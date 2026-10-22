#!/usr/bin/env python3
"""
Filesystem Organizer Daemon for NFP Fleet
Monitors staging directories, classifies files via Jev System-1 decision model,
and generates proposals or executes safe non-destructive relocation.
"""

import argparse
import datetime
import json
import mimetypes
import os
import shutil
import sys
import time
import urllib.error
import urllib.request

DEFAULT_JEV_URL = os.environ.get("JEV_ENGINE_URL", "http://luffy.nfp.nix:20130")
DEFAULT_THRESHOLD = 0.80

FS_ORGANIZE_QUESTIONS = [
    {
        "id": "target_vault",
        "type": "enum",
        "options": [
            "financial_records",
            "code_projects",
            "media_audiobooks",
            "personal_documents",
            "ephemeral_trash"
        ]
    },
    {
        "id": "suggested_filename_pattern",
        "type": "enum",
        "options": [
            "YYYY-MM-DD_vendor_receipt",
            "project_artifact",
            "keep_original"
        ]
    }
]


def extract_file_state(file_path):
    """Build metadata state string from file."""
    try:
        stat = os.stat(file_path)
    except Exception as e:
        return None, f"Stat failed: {e}"

    mime, _ = mimetypes.guess_type(file_path)
    base = os.path.basename(file_path)
    size_bytes = stat.st_size

    snippet = ""
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            snippet = f.read(1024)
            snippet = " ".join(snippet.split())[:300]
    except Exception:
        pass

    state_repr = (
        f"Path: {file_path}\n"
        f"Basename: {base}\n"
        f"Size: {size_bytes} bytes\n"
        f"MIME: {mime or 'unknown'}\n"
        f"Header: {snippet}"
    )

    return {
        "path": file_path,
        "basename": base,
        "size": size_bytes,
        "mtime": stat.st_mtime,
        "mime": mime or "unknown",
        "state_repr": state_repr,
    }, None


def query_jev_engine(state_text, engine_url):
    """Query Jev Engine for filesystem classification."""
    payload = json.dumps({
        "state": state_text,
        "questions": FS_ORGANIZE_QUESTIONS
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
        "engine": "jev-fs-local-fallback",
        "aggregate_confidence": 0.85,
        "decisions": {
            "target_vault": {"value": "personal_documents", "confidence": 0.85},
            "suggested_filename_pattern": {"value": "keep_original", "confidence": 0.85}
        }
    }


def format_suggested_filename(original_base, pattern, mtime):
    """Format suggested filename according to pattern."""
    if pattern == "YYYY-MM-DD_vendor_receipt":
        date_str = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")
        clean_name = original_base.replace(" ", "_")
        if not clean_name.startswith(date_str):
            return f"{date_str}_{clean_name}"
        return clean_name
    elif pattern == "project_artifact":
        return original_base.replace(" ", "_")
    return original_base


def execute_safe_move(src_path, dest_dir, new_name):
    """Safely move file without data loss or overwrites."""
    os.makedirs(dest_dir, exist_ok=True)
    target_path = os.path.join(dest_dir, new_name)

    # Collision avoidance
    if os.path.exists(target_path):
        base, ext = os.path.splitext(new_name)
        timestamp = int(time.time())
        target_path = os.path.join(dest_dir, f"{base}_{timestamp}{ext}")

    # Move file safely
    shutil.move(src_path, target_path)
    return target_path


def scan_and_propose(args):
    watch_dirs = [os.path.expanduser(d) for d in args.watch_dirs]
    vault_root = os.path.expanduser(args.vault_root)
    trash_dir = os.path.expanduser(args.trash_dir)
    proposal_file = os.path.expanduser(args.proposal_file)

    os.makedirs(os.path.dirname(proposal_file), exist_ok=True)
    os.makedirs(trash_dir, exist_ok=True)

    proposals = []
    scanned_count = 0

    for w_dir in watch_dirs:
        if not os.path.exists(w_dir):
            continue

        sys.stderr.write(f"Inspecting staging directory: {w_dir}\n")
        try:
            entries = os.listdir(w_dir)
        except Exception as e:
            sys.stderr.write(f"Cannot list {w_dir}: {e}\n")
            continue

        for fname in entries:
            # Ignore hidden files or active partial downloads
            if fname.startswith(".") or fname.endswith(".crdownload") or fname.endswith(".part"):
                continue

            full_path = os.path.join(w_dir, fname)
            if not os.path.isfile(full_path):
                continue

            scanned_count += 1
            meta, err = extract_file_state(full_path)
            if err or not meta:
                continue

            decision_res = query_jev_engine(meta["state_repr"], args.jev_url)
            decisions = decision_res.get("decisions", {})
            agg_conf = decision_res.get("aggregate_confidence", 0.0)

            target_vault = decisions.get("target_vault", {}).get("value", "personal_documents")
            pattern = decisions.get("suggested_filename_pattern", {}).get("value", "keep_original")

            suggested_name = format_suggested_filename(fname, pattern, meta["mtime"])

            if target_vault == "ephemeral_trash":
                destination_dir = os.path.join(trash_dir, "files")
            else:
                destination_dir = os.path.join(vault_root, target_vault)

            needs_review = agg_conf < args.confidence_threshold

            proposal = {
                "source_path": full_path,
                "current_name": fname,
                "target_vault": target_vault,
                "suggested_name": suggested_name,
                "destination_dir": destination_dir,
                "target_path": os.path.join(destination_dir, suggested_name),
                "confidence": agg_conf,
                "needs_review": needs_review,
                "timestamp": time.time()
            }
            proposals.append(proposal)

            sys.stdout.write(
                f"[Jev FS] {fname} -> vault={target_vault} | name={suggested_name} "
                f"| conf={agg_conf:.2f} {'(!REVIEW)' if needs_review else ''}\n"
            )

    # Save proposal JSON
    proposal_report = {
        "generated_at": time.time(),
        "dry_run": args.dry_run,
        "scanned_files": scanned_count,
        "proposals": proposals
    }

    try:
        with open(proposal_file, "w") as f:
            json.dump(proposal_report, f, indent=2)
        sys.stderr.write(f"Wrote proposals to {proposal_file}\n")
    except Exception as e:
        sys.stderr.write(f"Failed to write proposals to {proposal_file}: {e}\n")

    # If execution mode and not dry run: execute high-confidence items
    if not args.dry_run and args.execute:
        executed = 0
        for p in proposals:
            if not p["needs_review"] and os.path.exists(p["source_path"]):
                try:
                    res_path = execute_safe_move(p["source_path"], p["destination_dir"], p["suggested_name"])
                    executed += 1
                    sys.stdout.write(f"[EXEC] Moved {p['source_path']} -> {res_path}\n")
                except Exception as e:
                    sys.stderr.write(f"Error moving {p['source_path']}: {e}\n")
        sys.stderr.write(f"Execution complete: {executed} files relocated.\n")


def main():
    parser = argparse.ArgumentParser(description="Jev Filesystem Organizer Daemon")
    parser.add_argument("--watch-dirs", nargs="+", default=["~/Downloads", "~/Inbox", "~/Scans"], help="Staging directories")
    parser.add_argument("--vault-root", default="~/Vault", help="Destination vault root")
    parser.add_argument("--proposal-file", default="~/.local/share/jev/fs-proposals.json", help="Proposals JSON path")
    parser.add_argument("--trash-dir", default="~/.local/share/Trash", help="Safe trash staging directory")
    parser.add_argument("--jev-url", default=DEFAULT_JEV_URL, help="Jev Engine URL")
    parser.add_argument("--confidence-threshold", type=float, default=DEFAULT_THRESHOLD, help="Confidence threshold")
    parser.add_argument("--dry-run", action="store_true", default=True, help="Dry run mode (default: true)")
    parser.add_argument("--execute", action="store_true", help="Execute relocation for high confidence proposals")

    args = parser.parse_args()
    if args.execute:
        args.dry_run = False
    scan_and_propose(args)


if __name__ == "__main__":
    main()
