#!/usr/bin/env python3
"""
Jev Label Purifier & Workspace Cleaner
Purges legacy SaneBox, Unroll.me, screener, and deprecated numbered labels.
Author: GLaDOS / Aperture Science Enrichment Center
"""

import argparse
import imaplib
import os
import socket
import sys

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

# Labels targeted for complete destruction
LABELS_TO_PURGE = [
    # SaneBox legacy clutter
    "@SaneReceipts",
    "@SaneBlackHole",
    "@SaneLater",
    "@SaneNews",
    "@SaneNoReplies",
    # Unroll.me relics
    "Unroll.me/Unsubscribed",
    "Unroll.me",
    # Screener & Hidden
    "*@ Hidden/Screener",
    "*@ Hidden",
    # Read Later
    "Read Later/Archive",
    "Read Later",
    # Deprecated numbered taxonomy
    "01. Reply",
    "02. Follow Up",
    "03. Action",
    "04. FYI",
    "05. Marketing",
    "06. Newsletters",
    "07. Urgent / Attention Required",
    "07. Urgent ",
    "08. Spam",
    "Urgent",
    # Agent & Third party artifacts
    "&2D3dwg- Archived by Agent",
    "[Notion]",
    "Actioned",
    "Awaiting Reply",
    "Cold Email",
    "FYI",
    "Marketing",
    "Meeting Update",
    "Notification",
    "To Respond",
    "System Notification",
]


def get_imap_connection(account_name: str, timeout: int = 30) -> imaplib.IMAP4_SSL:
    if account_name not in ACCOUNTS:
        raise ValueError(f"Unknown account: {account_name}")
    cfg = ACCOUNTS[account_name]
    with open(cfg["secret_path"], "r") as f:
        password = f.read().strip()
    ipv4_addr = socket.gethostbyname("imap.gmail.com")
    conn = imaplib.IMAP4_SSL(ipv4_addr, 993, timeout=timeout)
    conn.login(cfg["email"], password)
    return conn


def purge_labels(account_name: str, dry_run: bool = False):
    print("\n" + "=" * 65)
    print(f"🧹 PURGING CLUTTER LABELS: '{account_name}' (Mode: {'DRY RUN' if dry_run else 'EXECUTE DELETION'})")
    print("=" * 65)
    
    conn = get_imap_connection(account_name)
    status, mailboxes = conn.list()
    if status != "OK":
        print(f"[!] Failed to list mailboxes for {account_name}")
        conn.logout()
        return

    existing_mailboxes = set()
    for mb in mailboxes:
        # Format: (\Flags) "/" "Name" or (\Flags) "/" Name
        decoded = mb.decode(errors="ignore")
        parts = decoded.split(' "/" ')
        if len(parts) >= 2:
            raw_name = parts[1].strip()
            if raw_name.startswith('"') and raw_name.endswith('"'):
                raw_name = raw_name[1:-1]
            existing_mailboxes.add(raw_name)

    purged = 0
    for target in LABELS_TO_PURGE:
        if target in existing_mailboxes:
            if dry_run:
                print(f" [DRY-RUN] Would delete label: \"{target}\"")
                purged += 1
            else:
                try:
                    # Format as quoted IMAP mailbox
                    quoted_target = f'"{target}"'
                    del_status, res = conn.delete(quoted_target)
                    if del_status == "OK":
                        print(f" [✓] Deleted label: \"{target}\"")
                        purged += 1
                    else:
                        print(f" [!] Delete failed for \"{target}\": {res}")
                except Exception as e:
                    print(f" [!] Error deleting \"{target}\": {e}")

    print("-" * 65)
    print(f"[✓] Finished. {purged} clutter labels {'identified' if dry_run else 'incinerated'}.")
    conn.logout()


def main():
    parser = argparse.ArgumentParser(description="Jev Label Purifier & Workspace Cleaner")
    parser.add_argument("--account", choices=["wrighterik77", "lovelainautomations", "all"], default="all")
    parser.add_argument("--dry-run", action="store_true", help="Audit labels without deleting")
    args = parser.parse_args()

    accounts = ["wrighterik77", "lovelainautomations"] if args.account == "all" else [args.account]
    for acct in accounts:
        purge_labels(acct, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
