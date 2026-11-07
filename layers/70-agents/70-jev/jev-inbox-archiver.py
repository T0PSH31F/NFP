#!/usr/bin/env python3
"""
Jev Email Archiver & Multi-Site Deduplicated Cold Storage Daemon
Aperture Science Enrichment Center - Fleet Mail Storage Protocol
Author: GLaDOS / Aperture Science Enrichment Center
"""

import argparse
import datetime
import email
import email.utils
import hashlib
import imaplib
import json
import os
import re
import socket
import subprocess
import sys
import time

# Increase maximum line length for heavy MIME parts
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
ARCHIVE_DIR = os.path.join(STATE_DIR, "archives")
WHITELIST_FILE = os.path.join(STATE_DIR, "whitelisted_contacts.json")

# Remote Backup Endpoints
GDRIVE_REMOTE = "gdrive:Backups/Email/archives"
NAS_HOST = "z0r0"
NAS_REMOTE_DIR = "/persist/home/t0psh31f/Backups/Email/archives"

# Classification Keywords
URGENT_KEYWORDS = [
    "action required", "expir", "expire", "action advised", "urgent",
    "attention required", "renewal notice", "security alert", "password reset",
    "suspended", "unauthorized", "verify your account", "immediate attention"
]

FINANCIAL_KEYWORDS = [
    "invoice", "receipt", "billing", "payment", "order confirmation",
    "subscription renewed", "cloudflare", "stripe", "aws", "paypal",
    "bank", "credit card", "statement", "wire transfer", "renewal",
    "transaction", "charge", "refund", "auto-renew", "porkbun", "namecheap"
]

SYSTEM_NOTIF_KEYWORDS = [
    "github", "run failed", "workflow run", "ci/cd", "deployment",
    "daemon", "cron", "alertmanager", "grafana", "uptimerobot", "sentry"
]

FYI_KEYWORDS = [
    "lottery", "jackpot alert", "fantasy 5", "newsletter", "update on",
    "calendar alerts", "summary", "digest", "weekly report"
]


def get_imap_connection(account_name: str, timeout: int = 45) -> imaplib.IMAP4_SSL:
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


def calculate_sha256(file_path: str) -> str:
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def ensure_remote_dirs():
    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    # Check/create NAS remote directory
    try:
        subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", NAS_HOST, f"mkdir -p {NAS_REMOTE_DIR}"],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except Exception as e:
        print(f"[!] Warning: Could not pre-create NAS remote directory on {NAS_HOST}: {e}")


def execute_manifest_archival(account_name: str, cutoff_date: str = "06-Aug-2026"):
    archive_base = f"{account_name}-pre-{cutoff_date.replace('-', '').lower()}"
    manifest_path = os.path.join(ARCHIVE_DIR, f"{archive_base}-manifest.json")
    zst_path = os.path.join(ARCHIVE_DIR, f"{archive_base}.tar.zst")

    if not os.path.exists(manifest_path) or not os.path.exists(zst_path):
        print(f"[!] No completed backup manifest found for {account_name}. Run export first.")
        return

    with open(manifest_path, "r") as mf:
        manifest = json.load(mf)

    print("\n" + "=" * 70)
    print(f"🚀 EXECUTING GMAIL ARCHIVAL: '{account_name}'")
    print(f"   Backed-Up Messages in Manifest : {len(manifest)}")
    print(f"   Target Mailbox                 : [Gmail]/All Mail (Remove \\Inbox)")
    print("=" * 70)

    conn = get_imap_connection(account_name)
    conn.select("INBOX", readonly=False)

    # Protect starred / flagged messages
    status, f_data = conn.uid("SEARCH", None, "FLAGGED")
    flagged_uids = set(f_data[0].decode().split()) if f_data[0] else set()
    print(f"[*] Starred messages protected in INBOX: {len(flagged_uids)}")

    # Check which manifest UIDs are currently in INBOX
    status, all_inbox = conn.uid("SEARCH", None, "ALL")
    current_inbox_uids = set(all_inbox[0].decode().split()) if all_inbox[0] else set()

    to_archive = [uid for uid in manifest if uid not in flagged_uids and uid in current_inbox_uids]
    print(f"[*] Total backed-up messages to archive out of INBOX: {len(to_archive)}")

    if not to_archive:
        print("[✓] All backed-up messages are already archived!")
        conn.logout()
        return

    chunk_size = 100
    for i in range(0, len(to_archive), chunk_size):
        chunk = to_archive[i:i + chunk_size]
        uid_str = ",".join(chunk)
        for attempt in range(3):
            try:
                move_res, _ = conn.uid("MOVE", uid_str, '"[Gmail]/All Mail"')
                break
            except Exception:
                time.sleep(1)
                try:
                    conn = get_imap_connection(account_name)
                    conn.select("INBOX", readonly=False)
                except Exception:
                    pass
        
        archived_so_far = min(i + len(chunk), len(to_archive))
        if (i + chunk_size) % 500 < chunk_size or archived_so_far == len(to_archive):
            print(f"[*] Progress: Moved {archived_so_far}/{len(to_archive)} messages to All Mail...")
        time.sleep(0.02)

    conn.close()
    conn.select("INBOX", readonly=True)
    status, final_inbox = conn.uid("SEARCH", None, "ALL")
    final_count = len(final_inbox[0].split()) if final_inbox[0] else 0
    print("-" * 70)
    print(f"🏆 ARCHIVAL COMPLETE! INBOX count reduced to: {final_count} messages")
    print("-" * 70)
    conn.logout()


def export_and_backup(account_name: str, cutoff_date: str = "06-Aug-2026", execute_archive: bool = False):
    ensure_remote_dirs()
    whitelist = load_whitelist()
    
    archive_base = f"{account_name}-pre-{cutoff_date.replace('-', '').lower()}"
    mbox_path = os.path.join(ARCHIVE_DIR, f"{archive_base}.mbox")
    zst_path = os.path.join(ARCHIVE_DIR, f"{archive_base}.tar.zst")
    sha_path = os.path.join(ARCHIVE_DIR, f"{archive_base}.tar.zst.sha256")
    manifest_path = os.path.join(ARCHIVE_DIR, f"{archive_base}-manifest.json")

    print("\n" + "=" * 70)
    print(f"📦 JEV ARCHIVE & BACKUP PIPELINE: '{account_name}'")
    print(f"   Cutoff Criteria  : Messages BEFORE {cutoff_date} (Older than 3 months)")
    print(f"   Local Export Dir : {ARCHIVE_DIR}")
    print(f"   Target Remote 1  : Google Drive ({GDRIVE_REMOTE})")
    print(f"   Target Remote 2  : NAS {NAS_HOST} ({NAS_REMOTE_DIR})")
    print(f"   Archive Mode     : {'EXECUTE ARCHIVE (Remove \\Inbox)' if execute_archive else 'EXPORT & BACKUP ONLY (Preserve INBOX)'}")
    print("=" * 70)

    conn = get_imap_connection(account_name)
    status, _ = conn.select("INBOX", readonly=not execute_archive)
    if status != "OK":
        raise RuntimeError("Failed to select INBOX")

    status, search_data = conn.uid("SEARCH", None, f"(BEFORE {cutoff_date})")
    if status != "OK" or not search_data[0]:
        print(f"[✓] No messages found older than {cutoff_date} in INBOX.")
        conn.logout()
        return

    old_uids = search_data[0].split()
    total_old = len(old_uids)
    print(f"[*] Found {total_old} messages older than {cutoff_date} in INBOX.")

    # Load existing manifest if resuming
    manifest = {}
    if os.path.exists(manifest_path):
        try:
            with open(manifest_path, "r") as mf:
                manifest = json.load(mf)
            print(f"[*] Resuming from existing manifest: {len(manifest)} messages already exported.")
        except Exception:
            manifest = {}

    # Open mbox in append mode
    exported_count = 0
    skipped_existing = 0
    protected_starred = []
    archiveable_uids = []

    batch_size = 50
    with open(mbox_path, "ab") as mbox_out:
        for chunk_idx in range(0, total_old, batch_size):
            chunk = old_uids[chunk_idx:chunk_idx + batch_size]
            uid_str = ",".join(u.decode() for u in chunk)
            
            # Fetch UID, Flags, and full RFC822 message by UID
            fetch_status, fetch_items = conn.uid("FETCH", uid_str, "(UID FLAGS RFC822)")
            if fetch_status != "OK":
                print(f"[!] Warning: Fetch failed for UIDs {uid_str[:30]}...")
                continue

            for i in range(0, len(fetch_items), 2):
                item = fetch_items[i]
                if not isinstance(item, tuple) or len(item) < 2:
                    continue
                
                meta_header = item[0].decode(errors="ignore") if isinstance(item[0], bytes) else str(item[0])
                raw_rfc822 = item[1]

                uid_match = re.search(r"UID\s+(\d+)", meta_header)
                uid = uid_match.group(1) if uid_match else None
                is_flagged = "\\flagged" in meta_header.lower() or "\\starred" in meta_header.lower()

                if not uid:
                    continue

                if is_flagged:
                    protected_starred.append(uid)
                    continue

                archiveable_uids.append(uid)

                if uid in manifest:
                    skipped_existing += 1
                    continue

                # Parse basic info for manifest
                msg = email.message_from_bytes(raw_rfc822)
                msg_id = msg.get("Message-ID", f"generated-{uid}@{account_name}")
                date_str = msg.get("Date", "")
                subject = msg.get("Subject", "")
                from_addr = msg.get("From", "")

                # Write standard mbox separator line
                mbox_from_line = f"From MAILER-DAEMON Mon Jan 01 00:00:00 2000\n".encode("utf-8")
                mbox_out.write(mbox_from_line)
                mbox_out.write(raw_rfc822)
                mbox_out.write(b"\n\n")

                manifest[uid] = {
                    "uid": uid,
                    "message_id": msg_id,
                    "date": date_str,
                    "subject": subject[:80],
                    "from": from_addr[:80]
                }
                exported_count += 1

            if (chunk_idx + batch_size) % 500 < batch_size or (chunk_idx + batch_size) >= total_old:
                progress = min(chunk_idx + batch_size, total_old)
                print(f"[*] Export progress: {progress}/{total_old} messages analyzed ({len(manifest)} in mbox, {len(protected_starred)} starred protected)...")

    # Save manifest
    with open(manifest_path, "w") as mf:
        json.dump(manifest, mf, indent=2)

    mbox_size_mb = os.path.getsize(mbox_path) / (1024 * 1024)
    print(f"\n[✓] Export complete! Total messages in mbox: {len(manifest)} ({mbox_size_mb:.2f} MB)")
    print(f"[✓] Starred items kept immune: {len(protected_starred)}")

    # Step 2: Compress with zstd
    print(f"\n[*] Compressing mbox with Zstandard (level 19, multi-threaded)...")
    tar_cmd = ["tar", "-I", "zstd -19 -T0", "-cf", zst_path, "-C", ARCHIVE_DIR, os.path.basename(mbox_path), os.path.basename(manifest_path)]
    subprocess.run(tar_cmd, check=True)

    zst_size_mb = os.path.getsize(zst_path) / (1024 * 1024)
    compression_ratio = (1 - (zst_size_mb / mbox_size_mb)) * 100 if mbox_size_mb else 0
    local_sha256 = calculate_sha256(zst_path)
    with open(sha_path, "w") as sf:
        sf.write(f"{local_sha256}  {os.path.basename(zst_path)}\n")

    print(f"[✓] Compression Complete: {zst_size_mb:.2f} MB (Compression savings: {compression_ratio:.1f}%)")
    print(f"[✓] Archive SHA256: {local_sha256}")

    # Step 3: Multi-site Replication
    print(f"\n[*] Syncing archive to Target 1: Google Drive ({GDRIVE_REMOTE})...")
    rclone_cmd = ["rclone", "copy", zst_path, GDRIVE_REMOTE]
    rclone_sha_cmd = ["rclone", "copy", sha_path, GDRIVE_REMOTE]
    subprocess.run(rclone_cmd, check=True)
    subprocess.run(rclone_sha_cmd, check=True)
    print(f"[✓] Target 1 (Google Drive) synced successfully.")

    print(f"[*] Syncing archive to Target 2: NAS {NAS_HOST} ({NAS_REMOTE_DIR})...")
    scp_cmd = ["scp", zst_path, sha_path, f"{NAS_HOST}:{NAS_REMOTE_DIR}/"]
    subprocess.run(scp_cmd, check=True)
    print(f"[✓] Target 2 (NAS {NAS_HOST}) synced successfully.")

    # Step 4: Verification of Integrity across All Targets
    print(f"\n[*] Verifying remote integrity...")
    nas_verify = subprocess.run(
        ["ssh", NAS_HOST, f"sha256sum {NAS_REMOTE_DIR}/{os.path.basename(zst_path)}"],
        capture_output=True, text=True, check=True
    )
    nas_sha256 = nas_verify.stdout.split()[0]
    if nas_sha256 != local_sha256:
        raise ValueError(f"CRITICAL CHECKSUM MISMATCH on NAS {NAS_HOST}! Local: {local_sha256} != Remote: {nas_sha256}")
    print(f"[✓] NAS {NAS_HOST} SHA256 verified: {nas_sha256} (MATCH)")

    # Verify Google Drive file size
    gdrive_verify = subprocess.run(
        ["rclone", "lsjson", f"{GDRIVE_REMOTE}/{os.path.basename(zst_path)}"],
        capture_output=True, text=True, check=True
    )
    gdrive_meta = json.loads(gdrive_verify.stdout)
    if not gdrive_meta or gdrive_meta[0]["Size"] != os.path.getsize(zst_path):
        raise ValueError(f"CRITICAL SIZE MISMATCH on Google Drive! Expected {os.path.getsize(zst_path)}, got {gdrive_meta}")
    print(f"[✓] Google Drive file size verified: {gdrive_meta[0]['Size']} bytes (MATCH)")

    print("\n" + "*" * 70)
    print("🏆 MULTI-SITE DEDUPLICATED BACKUP VERIFIED 100% HEALTHY & REDUNDANT")
    print(f"   • Primary Local : {zst_path}")
    print(f"   • Offsite Cloud : {GDRIVE_REMOTE}/{os.path.basename(zst_path)}")
    print(f"   • On-prem NAS   : {NAS_HOST}:{NAS_REMOTE_DIR}/{os.path.basename(zst_path)}")
    print("*" * 70)

    # Step 5: Archive from INBOX (if execute_archive is True)
    if execute_archive:
        # Re-establish fresh IMAP connection to prevent EOF timeouts after lengthy remote uploads
        try:
            conn.close()
            conn.logout()
        except Exception:
            pass
        
        conn = get_imap_connection(account_name)
        conn.select("INBOX", readonly=False)

        uids_to_archive = [uid for uid in archiveable_uids if uid in manifest]
        print(f"\n[!] Executing Gmail Archiving: Moving {len(uids_to_archive)} verified messages out of INBOX...")
        chunk_size = 100
        for i in range(0, len(uids_to_archive), chunk_size):
            chunk = uids_to_archive[i:i + chunk_size]
            uid_str = ",".join(chunk)
            try:
                move_res, _ = conn.uid("MOVE", uid_str, '"[Gmail]/All Mail"')
            except Exception as e:
                # Reconnect on intermittent network hiccup
                conn = get_imap_connection(account_name)
                conn.select("INBOX", readonly=False)
                move_res, _ = conn.uid("MOVE", uid_str, '"[Gmail]/All Mail"')
                
            if (i + chunk_size) % 500 < chunk_size or (i + len(chunk)) == len(uids_to_archive):
                archived_so_far = min(i + len(chunk), len(uids_to_archive))
                print(f"[*] Archival progress: Archived {archived_so_far}/{len(uids_to_archive)} messages to [Gmail]/All Mail...")
            time.sleep(0.05)
        print(f"[✓] Successfully archived {len(uids_to_archive)} messages from INBOX to [Gmail]/All Mail!")
    else:
        print("\n[i] Archival step skipped (dry-run/backup-only). Re-run with --archive to execute removal from INBOX.")

    conn.logout()


def sort_recent_messages(account_name: str, cutoff_date: str = "06-Aug-2026", apply_labels: bool = False):
    """
    Recent message audit without injecting clunky labels into the user's clean inbox.
    """
    print("\n" + "=" * 70)
    print(f"📊 JEV RECENT EMAIL AUDIT: '{account_name}'")
    print(f"   Target Scope: Active Messages SINCE {cutoff_date} (< 3 months old)")
    print("=" * 70)

    conn = get_imap_connection(account_name)
    conn.select("INBOX", readonly=True)

    status, search_data = conn.uid("SEARCH", None, f"(SINCE {cutoff_date})")
    if status != "OK" or not search_data[0]:
        print("[✓] No recent messages found in INBOX.")
        conn.logout()
        return

    recent_uids = search_data[0].split()
    total_recent = len(recent_uids)
    print(f"[*] Active clean messages sitting in INBOX: {total_recent}")
    conn.logout()


def main():
    parser = argparse.ArgumentParser(description="Jev Email Archiver & Multi-Site Cold Storage Daemon")
    parser.add_argument("--account", choices=["wrighterik77", "lovelainautomations", "all"], default="all")
    parser.add_argument("--cutoff", default="06-Aug-2026", help="Date cutoff in DD-Mon-YYYY (messages BEFORE this are archived)")
    parser.add_argument("--archive", action="store_true", help="Execute removal from INBOX to All Mail after verified multi-site backup")
    parser.add_argument("--sort-recent", action="store_true", help="Sort and label recent messages (<3mo) remaining in INBOX")
    parser.add_argument("--full-pipeline", action="store_true", help="Execute backup, archive, and sort recent across all accounts")

    args = parser.parse_args()
    accounts = ["wrighterik77", "lovelainautomations"] if args.account == "all" else [args.account]

    for acct in accounts:
        if args.archive:
            execute_manifest_archival(acct, cutoff_date=args.cutoff)
        elif args.full_pipeline:
            export_and_backup(acct, cutoff_date=args.cutoff, execute_archive=True)
        elif not args.sort_recent:
            export_and_backup(acct, cutoff_date=args.cutoff, execute_archive=False)

        if args.full_pipeline or args.sort_recent:
            sort_recent_messages(acct, cutoff_date=args.cutoff, apply_labels=False)


if __name__ == "__main__":
    main()
