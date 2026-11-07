#!/usr/bin/env python3
"""
Jev Autonomous Inbox Manager & Taxonomy Engine
24/7 Multi-Account Email Classifier, Labeler & Clutter Purifier
Aperture Science Enrichment Center - Fleet Mail Protocol
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

imaplib._MAXLINE = 10000000

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

# Clean, Sensible Taxonomy (IMAP UTF-7 names where &- = &)
TAXONOMY_LABELS = {
    "urgent": "Urgent!",
    "security": "Security &- 2FA",
    "billing": "Billing &- Receipts",
    "needs_response": "Needs Response",
    "messages": "Messages &- Social",
    "calendar": "Calendar &- Events",
    "updates": "Updates &- News",
    "promotions": "Promotions &- Deals",
    "drafts": "Agent Drafts",
    "archive": "Archive",
    "quarantine": "Quarantine",
}

# Rule Patterns for Classification
PATTERNS = {
    "urgent": [
        "urgent", "action required", "action advised", "attention required",
        "expir", "expire", "expiration notice", "immediate attention", "deadline",
        "suspended", "suspension", "overdue", "critical alert", "server down"
    ],
    "security": [
        "verification code", "verify your", "security alert", "password reset",
        "one-time password", "2fa", "otp", "login alert", "confirm your account",
        "suspicious activity", "new device", "sign-in attempt", "authentication code"
    ],
    "billing": [
        "invoice", "receipt", "billing", "payment", "order confirmation",
        "subscription renewed", "statement", "wire transfer", "transaction",
        "charge", "refund", "auto-renew", "stripe", "paypal", "porkbun",
        "namecheap", "aws", "cloudflare", "bank", "credit card"
    ],
    "messages": [
        "voice.google.com", "telephony", "discord", "slack", "matrix",
        "twitter.com", "x.com", "linkedin.com", "telegram", "sms"
    ],
    "calendar": [
        "invitation:", "accepted:", "declined:", "calendar", "appointment",
        "meeting", "webinar", "zoom.us", "meet.google.com"
    ],
    "promotions": [
        "% off", "discount", "deal of the day", "promo code", "flash sale",
        "free shipping", "clearance", "exclusive offer", "save big", "special promotion",
        "black friday", "cyber monday", "coupon", "giveaway", "free gift"
    ],
    "updates": [
        "github", "workflow run", "ci/cd", "release", "changelog", "digest",
        "announcement", "update on", "newsletter", "weekly report", "summary",
        "california lottery", "lottery", "jackpot alert"
    ],
    "quarantine": [
        "unsolicited", "viagra", "crypto recovery", "lottery winnings",
        "prince", "inheritance", "hacked your account", "malware"
    ]
}


def get_imap_connection(account_name: str, timeout: int = 35) -> imaplib.IMAP4_SSL:
    if account_name not in ACCOUNTS:
        raise ValueError(f"Unknown account: {account_name}")
    cfg = ACCOUNTS[account_name]
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


def ensure_labels(conn: imaplib.IMAP4_SSL):
    for key, lbl in TAXONOMY_LABELS.items():
        try:
            conn.create(lbl)
        except Exception:
            pass


def classify_email(headers: dict, whitelist: dict, is_flagged: bool = False) -> str:
    subj = (headers.get("subject") or "").strip()
    subj_lower = subj.lower()
    from_raw = headers.get("from") or ""
    parsed_from = email.utils.getaddresses([from_raw])
    from_addr = parsed_from[0][1].lower().strip() if parsed_from else ""
    combined = f"{subj_lower} {from_addr}"
    unsub = headers.get("list-unsubscribe", "")

    # Priority 0: Explicit User Star / Flag or Whitelisted Personal Contact -> Needs Response
    if is_flagged or from_addr in whitelist:
        return TAXONOMY_LABELS["needs_response"]

    # Priority 1: Direct Human Replies without unsubscribe headers
    if (subj_lower.startswith("re:") or subj_lower.startswith("fwd:")) and not unsub and ("support" in from_addr or "concierge" in from_addr or ".ai" in from_addr or ".com" in from_addr):
        return TAXONOMY_LABELS["needs_response"]

    # Priority 2: Security & 2FA
    if any(k in combined for k in PATTERNS["security"]):
        return TAXONOMY_LABELS["security"]

    # Priority 3: Urgent Infrastructure / Actions
    if any(k in combined for k in PATTERNS["urgent"]):
        return TAXONOMY_LABELS["urgent"]

    # Priority 4: Billing & Receipts
    if any(k in combined for k in PATTERNS["billing"]):
        return TAXONOMY_LABELS["billing"]

    # Priority 5: Communications / Google Voice / Messaging
    if any(k in combined for k in PATTERNS["messages"]):
        return TAXONOMY_LABELS["messages"]

    # Priority 6: Calendar & Events
    if any(k in combined for k in PATTERNS["calendar"]):
        return TAXONOMY_LABELS["calendar"]

    # Priority 7: Promotions & Deals
    if any(k in combined for k in PATTERNS["promotions"]):
        return TAXONOMY_LABELS["promotions"]

    # Priority 8: Quarantine
    if any(k in combined for k in PATTERNS["quarantine"]):
        return TAXONOMY_LABELS["quarantine"]

    # Priority 9: Updates & News (Bulk / Newsletters / GitHub / Digests)
    if unsub or any(k in combined for k in PATTERNS["updates"]):
        return TAXONOMY_LABELS["updates"]

    return TAXONOMY_LABELS["updates"]


def manage_inbox(account_name: str, limit: int = 250, dry_run: bool = False, archive_promotions: bool = True):
    print("\n" + "=" * 70)
    print(f"📬 JEV 24/7 INBOX MANAGEMENT: '{account_name}' (Mode: {'DRY RUN' if dry_run else 'APPLY LABELS & ROUTE'})")
    print("=" * 70)

    conn = get_imap_connection(account_name)
    ensure_labels(conn)
    conn.select("INBOX", readonly=dry_run)

    status, data = conn.uid("SEARCH", None, "ALL")
    if status != "OK" or not data[0]:
        print("[✓] Inbox is currently empty!")
        conn.logout()
        return

    all_uids = data[0].split()
    total_inbox = len(all_uids)
    print(f"[*] Total active messages in INBOX: {total_inbox}")

    whitelist = load_whitelist()
    process_uids = all_uids[-limit:] if limit > 0 else all_uids
    print(f"[*] Evaluating {len(process_uids)} recent messages...")

    tallies = {lbl: [] for lbl in TAXONOMY_LABELS.values()}
    batch_size = 100

    for chunk_start in range(0, len(process_uids), batch_size):
        chunk = process_uids[chunk_start:chunk_start + batch_size]
        uid_str = ",".join(u.decode() for u in chunk)

        fetch_status, fetch_items = conn.uid(
            "FETCH",
            uid_str,
            "(UID FLAGS BODY.PEEK[HEADER.FIELDS (FROM TO SUBJECT DATE LIST-UNSUBSCRIBE PRECEDENCE)])"
        )
        if fetch_status != "OK":
            continue

        for item in fetch_items:
            if not isinstance(item, tuple) or len(item) < 2:
                continue

            meta_str = item[0].decode(errors="ignore") if isinstance(item[0], bytes) else str(item[0])
            uid_match = re.search(r"UID\s+(\d+)", meta_str)
            uid = uid_match.group(1) if uid_match else None
            is_flagged = "\\flagged" in meta_str.lower() or "\\starred" in meta_str.lower()

            if not uid:
                continue

            msg = email.message_from_bytes(item[1])
            headers = {
                "subject": msg.get("subject") or "",
                "from": msg.get("from") or "",
                "list-unsubscribe": msg.get("list-unsubscribe") or "",
                "precedence": msg.get("precedence") or ""
            }

            label = classify_email(headers, whitelist, is_flagged=is_flagged)
            tallies[label].append(uid)

    print("\n------------------------------------------------------------------")
    print("📊 TAXONOMY CLASSIFICATION BREAKDOWN:")
    print("------------------------------------------------------------------")
    for key, lbl in TAXONOMY_LABELS.items():
        uids = tallies[lbl]
        display_name = lbl.replace("&-", "&")
        if uids:
            print(f" • {display_name:<24}: {len(uids):>5} messages")
    print("------------------------------------------------------------------")

    if not dry_run:
        # Apply labels
        for key, lbl in TAXONOMY_LABELS.items():
            uids = tallies[lbl]
            if not uids:
                continue
            display_name = lbl.replace("&-", "&")
            for i in range(0, len(uids), 100):
                chunk_uids = uids[i:i + 100]
                uid_chunk_str = ",".join(chunk_uids)
                conn.uid("STORE", uid_chunk_str, "+X-GM-LABELS", f'"{lbl}"')
            print(f"[✓] Tagged {len(uids)} messages with \"{display_name}\"")

        # Routing: Archive promotions to keep INBOX uncluttered if enabled
        if archive_promotions:
            promo_uids = tallies[TAXONOMY_LABELS["promotions"]]
            if promo_uids:
                print(f"[*] Archiving {len(promo_uids)} promotions out of INBOX view...")
                for i in range(0, len(promo_uids), 100):
                    p_chunk = promo_uids[i:i + 100]
                    p_str = ",".join(p_chunk)
                    conn.uid("MOVE", p_str, '"[Gmail]/All Mail"')
                print(f"[✓] Successfully archived {len(promo_uids)} promotional messages.")

            quarantine_uids = tallies[TAXONOMY_LABELS["quarantine"]]
            if quarantine_uids:
                print(f"[*] Moving {len(quarantine_uids)} spam/quarantine messages out of INBOX...")
                for i in range(0, len(quarantine_uids), 100):
                    q_chunk = quarantine_uids[i:i + 100]
                    q_str = ",".join(q_chunk)
                    conn.uid("MOVE", q_str, f'"{TAXONOMY_LABELS["quarantine"]}"')
                print(f"[✓] Quarantined {len(quarantine_uids)} suspicious messages.")

    conn.logout()


def main():
    parser = argparse.ArgumentParser(description="Jev Autonomous Inbox Manager & Taxonomy Engine")
    parser.add_argument("--account", choices=["wrighterik77", "lovelainautomations", "all"], default="all")
    parser.add_argument("--limit", type=int, default=250, help="Number of recent messages to process (0 = all)")
    parser.add_argument("--dry-run", action="store_true", help="Audit classification without applying labels")
    parser.add_argument("--purge", action="store_true", help="Archive promotions and quarantine spam automatically")
    parser.add_argument("--no-archive-promo", action="store_true", help="Do not archive promotions out of INBOX")

    args = parser.parse_args()
    accounts = ["wrighterik77", "lovelainautomations"] if args.account == "all" else [args.account]

    for acct in accounts:
        manage_inbox(
            acct,
            limit=args.limit,
            dry_run=args.dry_run,
            archive_promotions=not args.no_archive_promo
        )


if __name__ == "__main__":
    main()
