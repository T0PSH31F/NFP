#!/usr/bin/env python3
"""Fleet-wide non-destructive book consolidation, deduplication, Calibre import, and backup.

Run on luffy (host of /mnt/drives/backup-1/CalibreLibrary and calibre-web).
Never modifies or deletes any original source files across luffy, z0r0, sanji, or NATE DRIVE.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import zipfile
from pathlib import Path

BOOK_EXTS = {".epub", ".mobi", ".azw3", ".azw", ".kfx", ".djvu", ".fb2", ".cbz", ".cbr", ".pdf"}
PRIMARY_EBOOK_EXTS = {".epub", ".mobi", ".azw3", ".azw", ".kfx", ".djvu", ".fb2", ".cbz", ".cbr"}

SKIP_DIR_NAMES = {
    ".git", ".svn", ".obsidian", ".stversions", ".Trash-1000", "$RECYCLE.BIN",
    "System Volume Information", "node_modules", "__pycache__", ".cache", "Recovered_Hitachi_2TB",
}
SKIP_NAME_PATTERNS = re.compile(
    r"(?:invoice|receipt|tax[\s_-]?return|w-?2|1099|1040|paystub|bank[\s_-]?statement|resume|curriculum[\s_-]?vitae|passport|driver.?s.?license|ssn)",
    re.I,
)


def log(msg: str) -> None:
    print(f"[{dt.datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)


def verify_magic(path: Path) -> bool:
    ext = path.suffix.lower()
    if ext not in BOOK_EXTS:
        return False
    try:
        st = path.stat()
        if st.st_size < 10240:  # <10KB is almost always empty/broken stub
            return False
        with path.open("rb") as f:
            hdr = f.read(128)
    except OSError:
        return False

    if ext == ".pdf":
        return hdr.startswith(b"%PDF-")
    if ext in {".epub", ".cbz"}:
        if not hdr.startswith(b"PK\x03\x04"):
            return False
        if ext == ".epub":
            try:
                with zipfile.ZipFile(path, "r") as zf:
                    names = zf.namelist()
                    return "mimetype" in names or any("container.xml" in n for n in names)
            except Exception:
                return False
        return True
    if ext in {".mobi", ".azw", ".azw3", ".kfx"}:
        return b"BOOKMOBI" in hdr or b"TPZ" in hdr or len(hdr) >= 64
    if ext == ".cbr":
        return hdr.startswith(b"Rar!") or hdr.startswith(b"PK\x03\x04")
    if ext == ".djvu":
        return hdr.startswith(b"AT&TFORM")
    return True


def canonical_key(path: Path) -> tuple[str, str]:
    stem = path.stem
    stem = re.sub(r"\((?:z-?lib|annas|oceanofpdf|1lib)[^)]*\)", " ", stem, flags=re.I)
    stem = re.sub(r"\[[^\]]*\]", " ", stem)
    stem = re.sub(r"^(?:OceanofPDF\.com_|www\.[^_]+_)", "", stem, flags=re.I)
    stem = re.sub(r"(?:-\d+|\s*\(\d+\)|_copy\d*)$", "", stem, flags=re.I)
    stem = re.sub(r"[^a-z0-9]+", " ", stem.lower()).strip()
    return (stem[:100], path.suffix.lower())


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=check)


def seed_base_library(base_src: Path, lib_dir: Path) -> None:
    db = lib_dir / "metadata.db"
    if db.exists() and db.stat().st_size > 500_000:
        log(f"Target library {lib_dir} already seeded ({db.stat().st_size} bytes metadata.db)")
        return
    if not (base_src / "metadata.db").exists():
        log(f"Base source missing metadata.db: {base_src}", )
        return
    log(f"Seeding base Calibre library from {base_src} -> {lib_dir} ...")
    lib_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(["rsync", "-a", f"{base_src}/", f"{lib_dir}/"], check=True)
    log("Base library seed complete.")


def pull_remote_books(host: str, remote_paths: list[str], dest_root: Path) -> None:
    dest_root.mkdir(parents=True, exist_ok=True)
    for idx, rpath in enumerate(remote_paths):
        tag = f"src_{idx}_{Path(rpath).name.replace(' ', '_')}"
        local_dest = dest_root / tag
        local_dest.mkdir(parents=True, exist_ok=True)
        log(f"Pulling ebooks from {host}:{rpath} -> {local_dest} ...")
        # Use rsync filter rules to copy ONLY book formats non-destructively
        cmd = [
            "rsync", "-az", "--ignore-errors",
            "--exclude=.git/", "--exclude=node_modules/", "--exclude=*.sdr/",
            "--exclude=.Trash-1000/", "--exclude=.cache/", "--exclude=Recovered_Hitachi_2TB/",
            "--include=*/",
            "--include=*.epub", "--include=*.EPUB",
            "--include=*.mobi", "--include=*.MOBI",
            "--include=*.azw3", "--include=*.AZW3",
            "--include=*.azw", "--include=*.AZW",
            "--include=*.kfx", "--include=*.djvu", "--include=*.fb2",
            "--include=*.cbz", "--include=*.cbr", "--include=*.pdf", "--include=*.PDF",
            "--exclude=*",
            f"{host}:{rpath}/",
            f"{local_dest}/",
        ]
        subprocess.run(cmd, check=False)


def index_existing_library(lib_dir: Path) -> tuple[set[str], set[tuple[str, str]]]:
    hashes: set[str] = set()
    keys: set[tuple[str, str]] = set()
    for root_str, dirs, files in os.walk(lib_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIR_NAMES and not d.startswith(".")]
        for fname in files:
            p = Path(root_str) / fname
            if p.suffix.lower() in BOOK_EXTS:
                try:
                    hashes.add(sha256_file(p))
                    keys.add(canonical_key(p))
                except OSError:
                    pass
    log(f"Indexed existing target library: {len(hashes)} files hashed, {len(keys)} canonical keys.")
    return hashes, keys


def gather_candidates(
    source_dirs: list[tuple[str, Path, bool]],
    seen_hashes: set[str],
    seen_keys: set[tuple[str, str]],
    import_queue_dir: Path,
) -> dict[str, int]:
    stats = {"scanned": 0, "invalid": 0, "skipped_pii_name": 0, "dup_sha256": 0, "dup_title": 0, "queued": 0}
    if import_queue_dir.exists():
        shutil.rmtree(import_queue_dir)
    import_queue_dir.mkdir(parents=True, exist_ok=True)

    for label, sdir, pdfs_strict in source_dirs:
        if not sdir.exists():
            log(f"Skipping missing source [{label}]: {sdir}")
            continue
        log(f"Scanning [{label}] {sdir} ...")
        for root_str, dirs, files in os.walk(sdir):
            dirs[:] = [d for d in dirs if d not in SKIP_DIR_NAMES and not d.endswith(".sdr") and not d.startswith(".")]
            for fname in sorted(files):
                p = Path(root_str) / fname
                ext = p.suffix.lower()
                if ext not in BOOK_EXTS:
                    continue
                if pdfs_strict and ext == ".pdf":
                    # In mixed document folders, skip tiny PDFs (<250KB) & personal doc filenames
                    try:
                        if p.stat().st_size < 250_000:
                            continue
                    except OSError:
                        continue
                if SKIP_NAME_PATTERNS.search(p.name):
                    stats["skipped_pii_name"] += 1
                    continue
                stats["scanned"] += 1
                if not verify_magic(p):
                    stats["invalid"] += 1
                    continue
                try:
                    digest = sha256_file(p)
                except OSError:
                    continue
                if digest in seen_hashes:
                    stats["dup_sha256"] += 1
                    continue
                ckey = canonical_key(p)
                if ckey[0] and ckey in seen_keys:
                    stats["dup_title"] += 1
                    continue

                seen_hashes.add(digest)
                if ckey[0]:
                    seen_keys.add(ckey)

                target = import_queue_dir / f"{stats['queued']:06d}_{p.name}"
                try:
                    os.link(p, target)
                except OSError:
                    shutil.copy2(p, target)
                stats["queued"] += 1
    return stats


def batch_calibredb_import(queue_dir: Path, lib_dir: Path, batch_size: int = 150) -> int:
    files = sorted(queue_dir.iterdir())
    if not files:
        log("No new unique books to import into Calibre.")
        return 0
    log(f"Importing {len(files)} deduplicated books into {lib_dir} in batches of {batch_size}...")
    imported = 0
    for i in range(0, len(files), batch_size):
        chunk = [str(f) for f in files[i:i + batch_size]]
        res = subprocess.run(
            [
                "calibredb", "add",
                "--library-path", str(lib_dir),
                "--automerge", "ignore",
                *chunk,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        imported += len(chunk)
        if res.returncode != 0:
            log(f"Batch {i // batch_size} warning (rc={res.returncode}): {res.stderr.strip()[:300]}")
        else:
            log(f"Batch {i // batch_size + 1}: processed {imported}/{len(files)}")
    return imported


def backup_library(lib_dir: Path, backup_dir: Path) -> bool:
    if not (lib_dir / "metadata.db").exists():
        return False
    backup_dir.mkdir(parents=True, exist_ok=True)
    log(f"Backing up consolidated Calibre Library -> {backup_dir} ...")
    # Snapshot locally first so CIFS/SMB destinations do not reject SQLite byte-range locks
    local_tmp = Path("/tmp/calibre-metadata-backup.db")
    if local_tmp.exists():
        local_tmp.unlink()
    run(["sqlite3", "-cmd", ".timeout 15000", str(lib_dir / "metadata.db"), f".backup '{local_tmp}'"])
    shutil.copyfile(local_tmp, backup_dir / "metadata.db.tmp")
    local_tmp.unlink(missing_ok=True)
    os.replace(backup_dir / "metadata.db.tmp", backup_dir / "metadata.db")
    subprocess.run(
        [
            "rsync", "-rt", "--modify-window=2", "--no-perms", "--no-owner", "--no-group",
            "--exclude=metadata.db", "--exclude=metadata.db.*",
            f"{lib_dir}/", f"{backup_dir}/",
        ],
        check=True,
    )
    log(f"Backup complete at {backup_dir}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Consolidate, deduplicate, backup, and serve Calibre library.")
    parser.add_argument("--lib-dir", default="/mnt/drives/backup-1/CalibreLibrary")
    parser.add_argument("--staging-dir", default="/mnt/drives/backup-1/.book-consolidation-staging")
    parser.add_argument("--backup-dir", default="/mnt/NAS1/backups/CalibreLibrary")
    parser.add_argument("--local-backup-dir", default="/storage/Backups/CalibreLibrary")
    parser.add_argument("--skip-remote", action="store_true")
    args = parser.parse_args()

    lib_dir = Path(args.lib_dir)
    staging = Path(args.staging_dir)
    base_seed = Path("/storage/Documents/Calibre Library")

    # 1. Seed base rich Calibre Library first (non-destructive copy)
    seed_base_library(base_seed, lib_dir)

    # 2. Pull remote ebooks from z0r0 and sanji non-destructively into staging
    if not args.skip_remote:
        pull_remote_books(
            "z0r0",
            [
                "~/Documents/Calibre_Library",
                "~/Documents/10-Library",
                "~/Documents/03-Hacking-Security",
                "~/Documents/08-Duplicates",
                "~/Documents/Courses",
                "~/Documents/06-Documents",
                "~/Projects/AI/Knowledge_Books_Archive",
                "~/Projects/Products/Books",
                "~/Projects/Streaming_Liberation/build",
            ],
            staging / "z0r0",
        )
        pull_remote_books(
            "sanji",
            [
                "~/Notes/PKB/books",
                "~/Documents",
                "~/Projects/Streaming_Liberation/build",
            ],
            staging / "sanji",
        )

    # 3. Hash existing target library + scan & deduplicate all sources
    seen_hashes, seen_keys = index_existing_library(lib_dir)

    sources: list[tuple[str, Path, bool]] = [
        ("luffy-storage-NonFiction", Path("/storage/Documents/Non-Fiction"), False),
        ("luffy-storage-AI-books", Path("/storage/Documents/AI books"), False),
        ("luffy-storage-Fiction", Path("/storage/Documents/Fiction"), False),
        ("luffy-storage-Books", Path("/storage/Documents/Books"), False),
        ("luffy-storage-root", Path("/storage/Documents"), True),
        ("z0r0-pulled", staging / "z0r0", True),
        ("sanji-pulled", staging / "sanji", True),
        ("luffy-NATE-Calibre", Path("/run/media/t0psh31f/NATE DRIVE/Calibre Library"), False),
        ("luffy-NATE-Books", Path("/run/media/t0psh31f/NATE DRIVE/Books"), False),
    ]

    queue_dir = staging / "import_queue"
    stats = gather_candidates(sources, seen_hashes, seen_keys, queue_dir)
    log(f"Deduplication stats: {json.dumps(stats)}")

    # 4. Import queue into Calibre
    batch_calibredb_import(queue_dir, lib_dir)

    # 5. Summary + clean temporary staging on Backup_1 (NEVER touches original sources)
    conn = sqlite3.connect(f"file:{lib_dir / 'metadata.db'}?mode=ro", uri=True)
    books_cnt = conn.execute("SELECT count(*) FROM books").fetchone()[0]
    authors_cnt = conn.execute("SELECT count(*) FROM authors").fetchone()[0]
    conn.close()

    # Clean up temporary staging mirror on Backup_1 so disk space isn't wasted
    if staging.exists():
        shutil.rmtree(staging, ignore_errors=True)

    # 6. Dual Backup (NAS1 + local /storage SSD mirror if space allows)
    nas_ok = False
    if Path("/mnt/NAS1").exists():
        try:
            nas_ok = backup_library(lib_dir, Path(args.backup_dir))
        except Exception as exc:
            log(f"NAS1 backup warning: {exc}")

    report = {
        "library_path": str(lib_dir),
        "books_total": books_cnt,
        "authors_total": authors_cnt,
        "dedup_stats": stats,
        "nas1_backup_ok": nas_ok,
        "nas1_backup_path": args.backup_dir if nas_ok else None,
        "completed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    report_path = lib_dir / "CONSOLIDATION_REPORT.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    log(f"FINAL CONSOLIDATION REPORT: {json.dumps(report)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
