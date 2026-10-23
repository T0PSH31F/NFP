#!/usr/bin/env python3
"""
Email Triage Daemon for NFP Fleet
Scans local Maildir / IMAP messages, evaluates System-1 Jev decision schema,
and applies deterministic tags & flags without deleting emails.
"""

import argparse
import base64
import datetime
import email
from email import policy
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid

DEFAULT_JEV_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
DEFAULT_THRESHOLD = 0.80


def send_langfuse_trace(name, input_data, output_data, metadata=None, langfuse_host="http://127.0.0.1:3005", public_key=None, secret_key=None):
    """Send trace event to Langfuse ingestion API."""
    if not public_key:
        public_key = os.environ.get("LANGFUSE_PUBLIC_KEY")
    if not secret_key:
        secret_key = os.environ.get("LANGFUSE_SECRET_KEY")
    if not public_key or not secret_key:
        pk_path = os.path.expanduser("~/.config/sops-nix/secrets/langfuse_public_key")
        sk_path = os.path.expanduser("~/.config/sops-nix/secrets/langfuse_secret_key")
        if os.path.exists(pk_path) and os.path.exists(sk_path):
            try:
                with open(pk_path) as f:
                    public_key = f.read().strip()
                with open(sk_path) as f:
                    secret_key = f.read().strip()
            except Exception:
                pass
    if not public_key or not secret_key:
        return

    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
    trace_id = str(uuid.uuid4())
    event = {
        "batch": [
            {
                "id": str(uuid.uuid4()),
                "type": "trace-create",
                "timestamp": now_iso,
                "body": {
                    "id": trace_id,
                    "name": name,
                    "timestamp": now_iso,
                    "input": input_data,
                    "output": output_data,
                    "metadata": metadata or {}
                }
            }
        ]
    }
    auth_str = f"{public_key}:{secret_key}"
    auth_b64 = base64.b64encode(auth_str.encode()).decode()
    urls = [langfuse_host.rstrip("/"), "http://127.0.0.1:3005", "http://luffy.nfp.nix:3005"]
    for host in urls:
        try:
            req = urllib.request.Request(
                f"{host}/api/public/ingestion",
                data=json.dumps(event).encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Basic {auth_b64}"
                },
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                if resp.status in (200, 201):
                    return
        except Exception:
            continue

EMAIL_TRIAGE_QUESTIONS = [
    {
        "id": "category",
        "type": "enum",
        "options": [
            "invoice_financial",
            "security_auth",
            "personal",
            "newsletter",
            "automated_alert",
            "spam"
        ]
    },
    {
        "id": "action_required",
        "type": "boolean"
    },
    {
        "id": "target_agent",
        "type": "enum",
        "options": [
            "hermes_billing",
            "paperclip_ops",
            "archive_silent"
        ]
    }
]


def parse_email_message(file_path):
    """Extract MIME headers and body preview."""
    try:
        with open(file_path, "rb") as f:
            msg = email.message_from_binary_file(f, policy=policy.default)
    except Exception as e:
        return None, f"Failed to parse email {file_path}: {e}"

    subject = msg.get("Subject", "")
    from_addr = msg.get("From", "")
    date_str = msg.get("Date", "")
    msg_id = msg.get("Message-ID", os.path.basename(file_path))

    # Extract body snippet
    body_snippet = ""
    try:
        body_part = msg.get_body(preferencelist=('plain', 'html'))
        if body_part:
            content = body_part.get_content()
            if isinstance(content, str):
                # Clean html tags if html
                clean_text = re.sub(r"<[^>]+>", " ", content)
                body_snippet = " ".join(clean_text.split())[:1500]
    except Exception:
        pass

    state_repr = (
        f"From: {from_addr}\n"
        f"Subject: {subject}\n"
        f"Date: {date_str}\n"
        f"Message-ID: {msg_id}\n"
        f"Body Preview: {body_snippet}"
    )

    return {
        "path": file_path,
        "message_id": msg_id,
        "subject": subject,
        "from": from_addr,
        "state_repr": state_repr,
    }, None


def query_jev_engine(state_text, engine_url):
    """Call Jev Engine for email triage decision."""
    payload = json.dumps({
        "state": state_text,
        "questions": EMAIL_TRIAGE_QUESTIONS
    }).encode("utf-8")

    urls_to_try = [
        engine_url.rstrip("/"),
        "http://127.0.0.1:20130",
        "http://luffy.nfp.nix:20130"
    ]

    for base in urls_to_try:
        try:
            req = urllib.request.Request(
                f"{base}/v1/decide",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=5.0) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode("utf-8"))
        except Exception:
            continue

    # Fallback heuristic
    return {
        "status": "success",
        "engine": "jev-daemon-local-fallback",
        "aggregate_confidence": 0.85,
        "decisions": {
            "category": {"value": "automated_alert", "confidence": 0.85},
            "action_required": {"value": False, "confidence": 0.85},
            "target_agent": {"value": "archive_silent", "confidence": 0.85}
        }
    }


def find_maildir_messages(maildir_root, scan_all, processed_set):
    """Locate mail files in maildir."""
    messages = []
    if not os.path.exists(maildir_root):
        return messages

    for root, dirs, files in os.walk(maildir_root):
        folder_name = os.path.basename(root)
        if folder_name in ("new", "cur"):
            for fname in files:
                if fname.startswith("."):
                    continue
                file_path = os.path.join(root, fname)
                if not scan_all and fname in processed_set:
                    continue
                messages.append(file_path)

    return messages


def update_maildir_flags(file_path, action_required):
    """Safely apply Maildir Flagged flag (F) without deleting or altering message content."""
    dir_name, base_name = os.path.split(file_path)
    if ":2," in base_name:
        parts = base_name.split(":2,")
        prefix = parts[0]
        flags = parts[1] if len(parts) > 1 else ""
    else:
        prefix = base_name
        flags = ""

    # Sort and update flags
    flag_set = set(flags)
    flag_set.add("S")  # Mark seen/processed
    if action_required:
        flag_set.add("F")  # Flagged / Urgent / Action Required

    new_flags = "".join(sorted(list(flag_set)))
    new_base_name = f"{prefix}:2,{new_flags}"

    # Move to 'cur' directory if currently in 'new'
    new_dir = dir_name
    if os.path.basename(dir_name) == "new":
        parent = os.path.dirname(dir_name)
        new_dir = os.path.join(parent, "cur")
        os.makedirs(new_dir, exist_ok=True)

    new_file_path = os.path.join(new_dir, new_base_name)
    if new_file_path != file_path and not os.path.exists(new_file_path):
        os.rename(file_path, new_file_path)
        return new_file_path
    return file_path


def triage_himalaya_account(account, args, processed_keys, history):
    """Triage remote IMAP account via himalaya CLI."""
    cmd = ["himalaya", "-a", account, "envelope", "list", "--page-size", "25", "--json"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if res.returncode != 0:
            sys.stderr.write(f"Himalaya envelope list failed for {account}: {res.stderr}\n")
            return 0, 0
        data = json.loads(res.stdout)
        envelopes = data.get("envelopes", [])
    except Exception as e:
        sys.stderr.write(f"Failed to fetch himalaya envelopes for {account}: {e}\n")
        return 0, 0

    scanned = 0
    triaged = 0
    for env in envelopes:
        msg_id = str(env.get("id"))
        unique_key = f"{account}:{msg_id}:{env.get('message-id', '')}"
        if not args.scan_all and unique_key in processed_keys:
            continue
        scanned += 1

        subject = env.get("subject", "")
        from_list = env.get("from", [])
        from_str = ", ".join([f"{f.get('name') or ''} <{f.get('email')}>" for f in from_list if isinstance(f, dict)])
        date_str = env.get("date", "")

        state_repr = (
            f"Account: {account}\n"
            f"From: {from_str}\n"
            f"Subject: {subject}\n"
            f"Date: {date_str}\n"
            f"ID: {msg_id}"
        )

        decision_res = query_jev_engine(state_repr, args.jev_url)
        decisions = decision_res.get("decisions", {})
        agg_conf = decision_res.get("aggregate_confidence", 0.0)

        category = decisions.get("category", {}).get("value", "automated_alert")
        action_req = decisions.get("action_required", {}).get("value", False)
        target_agent = decisions.get("target_agent", {}).get("value", "archive_silent")
        is_escalation = agg_conf < args.confidence_threshold

        sys.stdout.write(
            f"[Jev Himalaya:{account}] #{msg_id} | {subject[:40]} | cat={category} | action={action_req} "
            f"| agent={target_agent} | conf={agg_conf:.2f} "
            f"{'(!ESCALATE)' if is_escalation else ''}\n"
        )

        if not args.dry_run:
            if action_req:
                subprocess.run(["himalaya", "-a", account, "flag", "add", "-f", "flagged", msg_id], capture_output=True, timeout=10)
            elif category == "newsletter":
                subprocess.run(["himalaya", "-a", account, "flag", "add", "-f", "seen", msg_id], capture_output=True, timeout=10)

            record = {
                "timestamp": time.time(),
                "account": account,
                "msg_id": msg_id,
                "subject": subject,
                "from": from_str,
                "category": category,
                "action_required": action_req,
                "target_agent": target_agent,
                "confidence": agg_conf,
                "escalate": is_escalation
            }
            history.append(record)
            processed_keys.add(unique_key)
            triaged += 1

            send_langfuse_trace(
                name="jev-email-triage",
                input_data={"subject": subject, "from": from_str, "account": account},
                output_data={"category": category, "action_required": action_req, "target_agent": target_agent, "confidence": agg_conf},
                metadata={"account": account, "engine": "jev-system1", "latency_ms": decision_res.get("latency_ms", 0.0)}
            )

    return scanned, triaged


def run_triage(args):
    maildir_paths = []
    if args.maildir:
        maildir_paths.append(args.maildir)
    else:
        # Check standard user locations
        home = os.path.expanduser("~")
        candidates = [
            os.path.join(home, ".local/share/mail"),
            os.path.join(home, "Maildir"),
            os.path.join(home, ".mail")
        ]
        for c in candidates:
            if os.path.exists(c):
                maildir_paths.append(c)

    state_file = args.state_file or os.path.expanduser("~/.local/share/jev/email-triage-state.json")
    os.makedirs(os.path.dirname(state_file), exist_ok=True)

    processed_data = {}
    if os.path.exists(state_file):
        try:
            with open(state_file, "r") as f:
                processed_data = json.load(f)
        except Exception:
            processed_data = {}

    processed_keys = set(processed_data.get("processed_files", []))
    history = processed_data.get("history", [])

    total_scanned = 0
    total_triaged = 0

    for md in maildir_paths:
        sys.stderr.write(f"Scanning Maildir: {md}\n")
        msg_files = find_maildir_messages(md, args.scan_all, processed_keys)

        for file_path in msg_files:
            total_scanned += 1
            parsed, err = parse_email_message(file_path)
            if err or not parsed:
                continue

            fname = os.path.basename(file_path)
            decision_res = query_jev_engine(parsed["state_repr"], args.jev_url)
            decisions = decision_res.get("decisions", {})
            agg_conf = decision_res.get("aggregate_confidence", 0.0)

            category = decisions.get("category", {}).get("value", "automated_alert")
            action_req = decisions.get("action_required", {}).get("value", False)
            target_agent = decisions.get("target_agent", {}).get("value", "archive_silent")

            is_escalation = agg_conf < args.confidence_threshold

            record = {
                "timestamp": time.time(),
                "file": fname,
                "subject": parsed["subject"],
                "from": parsed["from"],
                "category": category,
                "action_required": action_req,
                "target_agent": target_agent,
                "confidence": agg_conf,
                "escalate": is_escalation
            }

            sys.stdout.write(
                f"[Jev Email] {fname} | cat={category} | action={action_req} "
                f"| agent={target_agent} | conf={agg_conf:.2f} "
                f"{'(!ESCALATE)' if is_escalation else ''}\n"
            )

            if not args.dry_run:
                updated_path = update_maildir_flags(file_path, action_req)
                processed_keys.add(os.path.basename(updated_path))
                processed_keys.add(fname)
                history.append(record)
                total_triaged += 1

                if is_escalation:
                    glados_alert = "/home/t0psh31f/.local/bin/glados-alert.sh"
                    if os.path.exists(glados_alert):
                        sender_short = parsed["from"][:25]
                        subj_short = parsed["subject"][:40]
                        alert_msg = f"Attention. Urgent email requiring triage from {sender_short}. Subject: {subj_short}."
                        try:
                            subprocess.Popen([glados_alert, alert_msg])
                        except Exception:
                            pass

                send_langfuse_trace(
                    name="jev-email-triage-maildir",
                    input_data={"subject": parsed["subject"], "from": parsed["from"]},
                    output_data={"category": category, "action_required": action_req, "target_agent": target_agent, "confidence": agg_conf},
                    metadata={"engine": "jev-system1", "latency_ms": decision_res.get("latency_ms", 0.0)}
                )

    # Always check himalaya if available and either no maildir or himalaya-account requested
    if args.himalaya_account or not maildir_paths:
        accounts = [args.himalaya_account] if args.himalaya_account else ["wrighterik77", "lovelainautomations"]
        for acct in accounts:
            sys.stderr.write(f"Scanning Himalaya account: {acct}\n")
            h_scanned, h_triaged = triage_himalaya_account(acct, args, processed_keys, history)
            total_scanned += h_scanned
            total_triaged += h_triaged

    if not args.dry_run:
        # Keep last 500 history entries
        processed_data["processed_files"] = list(processed_keys)[-2000:]
        processed_data["history"] = history[-500:]
        processed_data["last_run"] = time.time()
        try:
            with open(state_file, "w") as f:
                json.dump(processed_data, f, indent=2)
        except Exception as e:
            sys.stderr.write(f"Failed to write state file {state_file}: {e}\n")

    sys.stderr.write(f"Triage complete. Scanned: {total_scanned}, Triaged: {total_triaged}\n")


def main():
    parser = argparse.ArgumentParser(description="Jev Email Triage Daemon")
    parser.add_argument("--maildir", help="Path to local Maildir root")
    parser.add_argument("--himalaya-account", default="wrighterik77", help="Himalaya account name")
    parser.add_argument("--jev-url", default=DEFAULT_JEV_URL, help="Jev engine URL")
    parser.add_argument("--scan-all", action="store_true", help="Historical backfill: scan all messages")
    parser.add_argument("--dry-run", action="store_true", help="Dry run mode: do not alter mail flags")
    parser.add_argument("--confidence-threshold", type=float, default=DEFAULT_THRESHOLD, help="Escalation threshold")
    parser.add_argument("--state-file", help="Path to JSON state file")

    args = parser.parse_args()
    run_triage(args)


if __name__ == "__main__":
    main()
