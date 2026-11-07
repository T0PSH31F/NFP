#!/usr/bin/env python3
"""
Jev Autonomous Inbox Purifier & Hygiene Daemon
NFP Fleet Email Triage & Bulk Newsletter Incinerator
Author: GLaDOS / Aperture Science Enrichment Center
"""

import argparse
import datetime
import email
import email.utils
import imaplib
import json
import os
import re
import socket
import sys
import time

ACCOUNTS = {
    "wrighterik77": {
        "email": "wrighterik77@gmail.com",
        "secret_path": os.path.expanduser("~/.config/sops-nix/secrets/gmail_app_password_wrighterik77"),
    },
    "lovelainautomations": {
        "email": "lovelainautomations@gmail.com",
        "secret_path": os.path.expanduser("~/.config/sops-nix/secrets/gmail_app_password_lovelainautomations"),
    },
}

STATE_DIR = os.path.expanduser("~/.local/share/jev")
WHITELIST_FILE = os.path.join(STATE_DIR, "whitelisted_contacts.json")

# Keywords for Financial / Invoices (IMMUNE)
FINANCIAL_KEYWORDS = [
    "invoice", "receipt", "billing", "payment", "order confirmation",
    "subscription renewed", "cloudflare", "stripe", "aws", "paypal",
    "bank", "credit card", "statement", "wire transfer", "renewal",
    "transaction", "charge", "refund", "auto-renew"
]

# Keywords for Security / Auth (IMMUNE)
SECURITY_KEYWORDS = [
    "verification code", "verify your", "security alert", "password reset",
    "one-time password", "2fa", "otp", "login alert", "confirm your account",
    "suspicious activity", "new device", "sign-in attempt"
]

# Keywords for Marketing / Cold Spam (PURGE)
MARKETING_KEYWORDS = [
    "% off", "discount", "black friday", "cyber monday", "deal of the day",
    "promo code", "limited time", "flash sale", "free shipping", "clearance",
    "exclusive offer", "save big", "special promotion"
]


def get_imap_connection(account_name: str, timeout: int = 30) -> imaplib.IMAP4_SSL:
    """Connect to Gmail IMAP enforcing IPv4 to prevent IPv6 TLS hang."""
    if account_name not in ACCOUNTS:
        raise ValueError(f"Unknown account: {account_name}")
    
    cfg = ACCOUNTS[account_name]
    if not os.path.exists(cfg["secret_path"]):
        raise FileNotFoundError(f"Secret file not found: {cfg['secret_path']}")
    
    with open(cfg["secret_path"], "r") as f:
        password = f.read().strip()
    
    ipv4_addr = socket.gethostbyname("imap.gmail.com")
    conn = imaplib.IMAP4_SSL(ipv4_addr, 993, timeout=timeout)
    conn.login(cfg["email"], password)
    return conn


def load_whitelist() -> dict:
    if os.path.exists(WHITELIST_FILE):
        try:
            with open(WHITELIST_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_whitelist(whitelist: dict):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(WHITELIST_FILE, "w") as f:
        json.dump(whitelist, f, indent=2)


def harvest_sent_contacts() -> dict:
    """Harvest all recipient email addresses from '[Gmail]/Sent Mail' across accounts."""
    whitelist = load_whitelist()
    initial_count = len(whitelist)
    print(f"[*] Starting Contact Harvest... (Existing whitelist: {initial_count} contacts)")

    for name in ACCOUNTS:
        try:
            print(f"[*] Connecting to {name} Sent Mailbox...")
            conn = get_imap_connection(name)
            status, data = conn.select('"[Gmail]/Sent Mail"', readonly=True)
            if status != "OK":
                conn.logout()
                continue
            
            status, msg_ids = conn.search(None, "ALL")
            ids = msg_ids[0].split()
            print(f"[*] {name}: Analyzing {len(ids)} sent messages...")
            
            if ids:
                # Fetch in batches of 250
                batch_size = 250
                for start_idx in range(0, len(ids), batch_size):
                    batch_ids = ids[start_idx:start_idx + batch_size]
                    range_str = f"{batch_ids[0].decode()}:{batch_ids[-1].decode()}"
                    status, fetch_data = conn.fetch(range_str, "(BODY.PEEK[HEADER.FIELDS (TO CC BCC SUBJECT DATE)])")
                    if status != "OK":
                        continue
                    
                    for item in fetch_data:
                        if isinstance(item, tuple):
                            msg = email.message_from_bytes(item[1])
                            to_addrs = email.utils.getaddresses(
                                msg.get_all("to", []) + msg.get_all("cc", []) + msg.get_all("bcc", [])
                            )
                            for display_name, addr in to_addrs:
                                if addr and "@" in addr:
                                    clean_addr = addr.lower().strip()
                                    if clean_addr not in whitelist:
                                        whitelist[clean_addr] = {
                                            "name": display_name,
                                            "count": 0,
                                            "last_subject": msg.get("subject", "")
                                        }
                                    whitelist[clean_addr]["count"] += 1
            conn.logout()
        except Exception as e:
            sys.stderr.write(f"[!] Harvest failed for {name}: {e}\n")

    save_whitelist(whitelist)
    print(f"[✓] Contact Harvest complete! Whitelist contains {len(whitelist)} protected contacts.")
    return whitelist


def classify_message(headers: dict, whitelist: dict, is_flagged: bool = False) -> tuple:
    """Classify an email into action category based on deterministic rules."""
    # Absolute Priority 0: Starred / Marked by User
    if is_flagged:
        return "IMMUNE_STARRED", "Message is explicitly starred or marked by user"

    from_raw = headers.get("from", "")
    parsed_from = email.utils.getaddresses([from_raw])
    from_addr = parsed_from[0][1].lower().strip() if parsed_from else ""
    subject = headers.get("subject", "")
    subj_lower = subject.lower()
    unsub = headers.get("list-unsubscribe", "")
    precedence = (headers.get("precedence") or "").lower()

    # Priority 1: Personal Contact Immunity
    if from_addr in whitelist:
        return "IMMUNE_PERSONAL", "Sender matches verified Sent Mail contact"

    # Priority 2: Financial / Invoices
    if any(k in subj_lower or k in from_addr for k in FINANCIAL_KEYWORDS):
        return "IMMUNE_FINANCIAL", "Detected critical financial/billing receipt"

    # Priority 3: Security / 2FA / Authentication
    if any(k in subj_lower for k in SECURITY_KEYWORDS):
        return "IMMUNE_SECURITY", "Detected security alert or authentication token"

    # Priority 4: Definite Newsletters (List-Unsubscribe or Bulk headers)
    if unsub or precedence in ["bulk", "list"]:
        return "PURGE_NEWSLETTER", "Contains List-Unsubscribe or bulk header"

    # Priority 5: Marketing Promotions
    if any(k in subj_lower for k in MARKETING_KEYWORDS):
        return "PURGE_MARKETING", "Subject matches promotional marketing blast"

    # Priority 6: Voice / SMS / Telephony relays
    if "txt.voice.google.com" in from_addr or "telephony" in from_addr:
        return "IMMUNE_SYSTEM", "Google Voice or telephony SMS message"

    return "UNCLASSIFIED_REVIEW", "Uncertain — requires manual inspection"


def scan_inbox(account_name: str, limit: int = 500, purge: bool = False, batch_size: int = 250):
    whitelist = load_whitelist()
    if not whitelist:
        whitelist = harvest_sent_contacts()

    print(f"\n==================================================================")
    print(f"[*] Jev Inbox Scan: Account '{account_name}' (Mode: {'PURGE TO TRASH' if purge else 'DRY RUN AUDIT'})")
    print(f"==================================================================")

    conn = get_imap_connection(account_name)
    status, data = conn.select("INBOX", readonly=not purge)
    total_in_box = int(data[0].decode())
    print(f"[*] Current Total Messages in INBOX: {total_in_box}")

    if total_in_box == 0:
        print("[✓] Inbox is already at Inbox Zero!")
        conn.logout()
        return

    scan_count = min(limit, total_in_box) if limit > 0 else total_in_box
    start_seq = max(1, total_in_box - scan_count + 1)
    end_seq = total_in_box

    print(f"[*] Scanning sequence range {start_seq}:{end_seq} ({scan_count} messages)...")

    results = {
        "IMMUNE_STARRED": [],
        "IMMUNE_PERSONAL": [],
        "IMMUNE_FINANCIAL": [],
        "IMMUNE_SECURITY": [],
        "IMMUNE_SYSTEM": [],
        "PURGE_NEWSLETTER": [],
        "PURGE_MARKETING": [],
        "UNCLASSIFIED_REVIEW": []
    }
    
    sender_tallies = {}
    purge_ids = []

    for chunk_start in range(start_seq, end_seq + 1, batch_size):
        chunk_end = min(chunk_start + batch_size - 1, end_seq)
        range_str = f"{chunk_start}:{chunk_end}"
        status, fetch_data = conn.fetch(
            range_str,
            "(UID FLAGS BODY.PEEK[HEADER.FIELDS (FROM TO SUBJECT DATE LIST-UNSUBSCRIBE PRECEDENCE MESSAGE-ID)])"
        )
        if status != "OK":
            continue

        for raw_meta in fetch_data:
            if isinstance(raw_meta, tuple) and len(raw_meta) >= 2:
                header_bytes = raw_meta[1]
                msg = email.message_from_bytes(header_bytes)
                
                # Extract UID and Flags (Starred protection)
                meta_str = raw_meta[0].decode() if isinstance(raw_meta[0], bytes) else str(raw_meta[0])
                uid_match = re.search(r"UID\s+(\d+)", meta_str)
                uid = uid_match.group(1) if uid_match else None
                is_flagged = "\\flagged" in meta_str.lower() or "\\starred" in meta_str.lower()

                headers_dict = {
                    "from": msg.get("from", ""),
                    "to": msg.get("to", ""),
                    "subject": msg.get("subject", ""),
                    "date": msg.get("date", ""),
                    "list-unsubscribe": msg.get("list-unsubscribe", ""),
                    "precedence": msg.get("precedence", "")
                }
                
                category, reason = classify_message(headers_dict, whitelist, is_flagged=is_flagged)
                parsed_from = email.utils.getaddresses([headers_dict["from"]])
                from_addr = parsed_from[0][1].lower().strip() if parsed_from else "unknown"
                
                item_record = {
                    "uid": uid,
                    "from": from_addr,
                    "subject": headers_dict["subject"],
                    "category": category,
                    "reason": reason
                }
                results[category].append(item_record)
                sender_tallies[from_addr] = sender_tallies.get(from_addr, 0) + 1

                if category in ["PURGE_NEWSLETTER", "PURGE_MARKETING"] and uid:
                    purge_ids.append(uid)

        processed_so_far = chunk_end - start_seq + 1
        if processed_so_far % 1000 < batch_size or chunk_end == end_seq:
            print(f"[*] Processed {processed_so_far}/{scan_count} messages ({len(purge_ids)} clutter candidates queued)...")

    # Output Summary Table
    print("\n------------------------------------------------------------------")
    print("📊 INBOX AUDIT CLASSIFICATION RESULTS:")
    print("------------------------------------------------------------------")
    total_categorized = sum(len(v) for v in results.values())
    for cat, items in results.items():
        pct = (len(items) / total_categorized * 100) if total_categorized else 0
        tag = "[PROTECTED]" if cat.startswith("IMMUNE") else "[PURGE CANDIDATE]"
        print(f" {tag:<18} {cat:<22}: {len(items):>5} messages ({pct:>5.1f}%)")

    total_purgeable = len(results["PURGE_NEWSLETTER"]) + len(results["PURGE_MARKETING"])
    purge_pct = (total_purgeable / total_categorized * 100) if total_categorized else 0
    print("------------------------------------------------------------------")
    print(f"🔥 TOTAL CLUTTER TO PURGE : {total_purgeable} / {total_categorized} messages ({purge_pct:.1f}%)")
    print("------------------------------------------------------------------")

    print("\n[!] Top 15 Senders Contributing to Inbox Clutter:")
    sorted_senders = sorted(sender_tallies.items(), key=lambda x: x[1], reverse=True)[:15]
    for s_addr, cnt in sorted_senders:
        immune_str = " (IMMUNE)" if s_addr in whitelist else ""
        print(f"   • {cnt:>4}x  {s_addr}{immune_str}")

    # Execution if --purge is specified
    if purge:
        if not purge_ids:
            print("\n[✓] No purgeable messages found.")
        else:
            print(f"\n[!] PURGE MODE ACTIVE: Moving {len(purge_ids)} messages to [Gmail]/Trash...")
            # Move in chunks of 100 to avoid buffer overflows
            chunk_size = 100
            for i in range(0, len(purge_ids), chunk_size):
                chunk = purge_ids[i:i + chunk_size]
                uid_str = ",".join(chunk)
                # Copy to Trash then mark Deleted in Inbox
                res, _ = conn.uid("COPY", uid_str, '"[Gmail]/Trash"')
                if res == "OK":
                    conn.uid("STORE", uid_str, "+FLAGS", r"(\Deleted)")
                moved_count = min(i + len(chunk), len(purge_ids))
                if moved_count % 500 < chunk_size or moved_count == len(purge_ids):
                    print(f"[*] Progress: Moved {moved_count}/{len(purge_ids)} clutter messages to Trash...")
                time.sleep(0.05)
            conn.expunge()
            print(f"[✓] Successfully incinerated {len(purge_ids)} newsletter & promo emails!")
    else:
        print("\n[i] DRY-RUN ONLY: Zero messages were modified or moved.")
        print(f"[i] To execute the purge and reclaim your inbox, re-run with: --purge")

    conn.logout()


def main():
    parser = argparse.ArgumentParser(description="Jev Autonomous Inbox Purifier & Hygiene Daemon")
    parser.add_argument("--harvest", action="store_true", help="Harvest personal contacts from Sent mailboxes")
    parser.add_argument("--account", choices=["wrighterik77", "lovelainautomations", "all"], default="wrighterik77", help="Account to scan")
    parser.add_argument("--limit", type=int, default=500, help="Number of recent messages to scan (0 = scan all)")
    parser.add_argument("--purge", action="store_true", help="Execute the purge (move newsletters/marketing to Trash)")
    parser.add_argument("--batch-size", type=int, default=250, help="IMAP header batch size")

    args = parser.parse_args()

    if args.harvest:
        harvest_sent_contacts()
        return

    accounts = ["wrighterik77", "lovelainautomations"] if args.account == "all" else [args.account]
    for acct in accounts:
        scan_inbox(acct, limit=args.limit, purge=args.purge, batch_size=args.batch_size)


if __name__ == "__main__":
    main()
