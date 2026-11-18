#!/usr/bin/env python3
"""
Periodic Fleet Storage Organizer for NFP (/storage on luffy).
Organizes staged directories from local & remote machines into /storage without
breaking multi-file game/movie directories, active downloads, or git repos.
"""

import argparse
import grp
import hashlib
import json
import os
import pwd
import re
import shutil
import sys
import time

DEFAULT_STORAGE_ROOT = "/storage"
DEFAULT_MIN_AGE_SEC = 300

SKIP_NAMES = {
    ".directory",
    ".DS_Store",
    "Thumbs.db",
    "desktop.ini",
    ".syncing",
    ".git",
}

SKIP_SUFFIXES = (".part", ".crdownload", ".aria2", ".!qB", ".tmp", ".rsync-tmp")

ROM_EXTENSIONS = {
    ".gba": "gba",
    ".gbc": "gbc",
    ".gb": "gb",
    ".nds": "nds",
    ".3ds": "3ds",
    ".cia": "3ds",
    ".nes": "nes",
    ".snes": "snes",
    ".smc": "snes",
    ".sfc": "snes",
    ".z64": "n64",
    ".n64": "n64",
    ".v64": "n64",
    ".xci": "switch",
    ".nsp": "switch",
    ".nsz": "switch",
    ".xcz": "switch",
    ".cso": "psp",
    ".wbfs": "wii",
    ".rvz": "gc",
    ".gdi": "dreamcast",
    ".cdi": "dreamcast",
    ".chd": "psx",
}

EBOOK_EXTENSIONS = {".epub", ".mobi", ".azw", ".azw3", ".fb2", ".djvu"}
COMIC_EXTENSIONS = {".cbz", ".cbr"}
DOC_EXTENSIONS = {".pdf", ".docx", ".doc", ".odt", ".rtf", ".txt", ".md"}
SPREADSHEET_EXTENSIONS = {".xlsx", ".xls", ".csv", ".ods"}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".avif", ".bmp", ".tiff", ".svg"}
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".wmv", ".webm", ".m4v"}
AUDIO_EXTENSIONS = {".mp3", ".flac", ".wav", ".aac", ".ogg", ".m4a", ".opus"}
ARCHIVE_EXTENSIONS = {".zip", ".rar", ".7z", ".tgz", ".xz", ".bz2"}
DB_EXTENSIONS = {".sql", ".db", ".sqlite", ".sqlite3", ".kdbx", ".wallet"}
INSTALLER_EXTENSIONS = {".appimage", ".deb", ".rpm"}

CODE_SUBDIRS = {
    ".nix": "Nix_Expressions",
    ".py": "Python_Scripts",
    ".sh": "Shell_Scripts",
    ".patch": "Git_Patches",
    ".diff": "Git_Patches",
}

TOPIC_KEYWORDS = {
    "Cybersecurity_and_PenTesting": [
        "hack", "exploit", "cyber", "security", "pentest", "metasploit", "kali",
        "forensic", "revers", "malware", "osint", "wifi", "burp", "injection",
        "phish", "threat", "vulnerab", "penetration", "privilege escalation",
    ],
    "Programming_and_NixOS": [
        "python", "nix", "nixos", "rust", "linux", "bash", "javascript", "golang",
        "c++", "c#", "java", "devops", "docker", "kubernetes", "git", "api",
        "compiler", "algo", "agentic", "llm", "machine learning", "neural",
    ],
    "SEO_Marketing_and_Business": [
        "seo", "marketing", "business", "sales", "ecommerce", "brand", "copywriting",
        "funnel", "monetiz", "entrepreneur", "advertising",
    ],
    "Hardware_and_Phone_Repair": [
        "phone", "repair", "hardware", "schematic", "circuit", "android", "iphone",
        "emmc", "edl", "jtag", "solder", "motherboard", "firmware", "pinout",
    ],
    "Crypto_Finance_and_Security": [
        "crypto", "bitcoin", "ethereum", "finance", "tax", "credit", "grant",
        "banking", "invest", "trading", "wallet", "ledger", "stock", "forex", "offshore",
    ],
}

MOVIE_MARKERS = ("1080p", "2160p", "720p", "4k", "bluray", "web-dl", "webrip", "yts", "x264", "x265", "hevc", "remux")
SHOW_RE = re.compile(r"\bs\d{1,2}e\d{1,2}\b|\bseason[\s._-]?\d+\b", re.IGNORECASE)


def should_skip_name(name):
    if name in SKIP_NAMES or name.startswith(".") or name.endswith(SKIP_SUFFIXES):
        return True
    return False


def is_recent(path, now_ts, min_age_sec):
    try:
        st = os.stat(path)
        if (now_ts - st.st_mtime) < min_age_sec:
            return True
        if os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                for f in files:
                    fp = os.path.join(root, f)
                    if (now_ts - os.stat(fp).st_mtime) < min_age_sec:
                        return True
        return False
    except OSError:
        return True


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()


def resolve_ids(user_name, group_name):
    try:
        uid = pwd.getpwnam(user_name).pw_uid
    except KeyError:
        uid = -1
    try:
        gid = grp.getgrnam(group_name).gr_gid
    except KeyError:
        gid = -1
    return uid, gid


def apply_ownership(path, storage_root, uid, users_gid, media_gid):
    rel = os.path.relpath(path, storage_root)
    top = rel.split(os.sep, 1)[0]
    gid = media_gid if top in ("Media", "ROMs", "Calibre") and media_gid != -1 else users_gid
    if os.path.isdir(path):
        for root, dirs, files in os.walk(path):
            if uid != -1 or gid != -1:
                try:
                    os.chown(root, uid, gid)
                except OSError:
                    pass
            for name in dirs + files:
                try:
                    os.chown(os.path.join(root, name), uid, gid)
                except OSError:
                    pass
    else:
        if uid != -1 or gid != -1:
            try:
                os.chown(path, uid, gid)
            except OSError:
                pass


def unique_dest_path(dst_path):
    if not os.path.exists(dst_path):
        return dst_path
    parent = os.path.dirname(dst_path)
    base, ext = os.path.splitext(os.path.basename(dst_path))
    return os.path.join(parent, f"{base}_{int(time.time())}{ext}")


def safe_move_file(src, dst, storage_root, uid, users_gid, media_gid, dry_run):
    os.makedirs(os.path.dirname(dst), exist_ok=True) if not dry_run else None
    if os.path.exists(dst) and os.path.isfile(dst):
        try:
            if os.path.getsize(src) == os.path.getsize(dst) and sha256_file(src) == sha256_file(dst):
                print(f"[DEDUP] {src} == {dst}")
                if not dry_run:
                    os.unlink(src)
                return "dedup"
        except OSError:
            pass
        dst = unique_dest_path(dst)

    print(f"[MOVE] {src} -> {dst}")
    if dry_run:
        return "dry-run"

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    tmp_dst = f"{dst}.partial.{os.getpid()}"
    try:
        shutil.copy2(src, tmp_dst)
        os.replace(tmp_dst, dst)
        apply_ownership(dst, storage_root, uid, users_gid, media_gid)
        os.unlink(src)
        return "moved"
    except Exception as exc:
        if os.path.exists(tmp_dst):
            try:
                os.unlink(tmp_dst)
            except OSError:
                pass
        print(f"[ERROR] Failed moving {src} -> {dst}: {exc}", file=sys.stderr)
        return "error"


def safe_move_dir(src_dir, dst_dir, storage_root, uid, users_gid, media_gid, dry_run):
    if os.path.exists(dst_dir):
        dst_dir = unique_dest_path(dst_dir)
    print(f"[MOVE-DIR] {src_dir} -> {dst_dir}")
    if dry_run:
        return "dry-run"
    os.makedirs(os.path.dirname(dst_dir), exist_ok=True)
    try:
        shutil.move(src_dir, dst_dir)
        apply_ownership(dst_dir, storage_root, uid, users_gid, media_gid)
        return "moved-dir"
    except Exception as exc:
        print(f"[ERROR] Failed moving directory {src_dir} -> {dst_dir}: {exc}", file=sys.stderr)
        return "error"


def get_doc_topic(filename):
    lower = filename.lower()
    for topic, keywords in TOPIC_KEYWORDS.items():
        if any(kw in lower for kw in keywords):
            return topic
    return "General_Reference"


def console_platform_from_name(lower):
    if "ps2" in lower:
        return "ps2"
    if "psx" in lower or "ps1" in lower:
        return "psx"
    if "psp" in lower:
        return "psp"
    if "gamecube" in lower or re.search(r"\bgc\b", lower):
        return "gc"
    if "wii" in lower:
        return "wii"
    if "xbox" in lower:
        return "xbox"
    if "switch" in lower or "nsp" in lower or "xci" in lower:
        return "switch"
    return None


def route_file(src_path, category, rel_path, storage_root):
    fname = os.path.basename(src_path)
    lower = fname.lower()
    ext = os.path.splitext(lower)[1]
    if lower.endswith(".tar.gz"):
        ext = ".tar.gz"

    # 1. Calibre eBooks & Komga comics
    if ext in EBOOK_EXTENSIONS:
        return os.path.join(storage_root, "Calibre", "auto_add", fname)
    if ext in COMIC_EXTENSIONS:
        return os.path.join(storage_root, "Media", "library", "books", fname)

    # 2. ROMs & Emulator firmware
    if ext in ROM_EXTENSIONS:
        return os.path.join(storage_root, "ROMs", "roms", ROM_EXTENSIONS[ext], fname)
    if any(k in lower for k in ("prodkeys", "titlekeys")) or (
        "firmware" in lower and ext in (".zip", ".7z", ".rar")
    ):
        return os.path.join(storage_root, "Games", "Emulators", fname)
    if ext == ".iso" or lower.endswith(".nkit.iso"):
        if any(
            k in lower
            for k in (
                "windows", "ubuntu", "nixos", "debian", "catalina", "fedora",
                "archlinux", "ventoy", "livecd", "gparted", "rescue", "kali",
                "mint", "tails", "linux",
            )
        ):
            return os.path.join(storage_root, "Backups", "OS_Images", fname)
        plat = console_platform_from_name(lower)
        if plat:
            return os.path.join(storage_root, "ROMs", "roms", plat, fname)
        if any(m in lower for m in MOVIE_MARKERS) or "movie" in lower:
            return os.path.join(storage_root, "Media", "library", "movies", fname)
        return os.path.join(storage_root, "Games", "PC", fname)

    # 3. Images / Photos (preserve subdirs from Pictures/Photos)
    if ext in IMAGE_EXTENSIONS:
        rel_dir = os.path.dirname(rel_path)
        if category in ("Pictures", "Photos") and rel_dir:
            return os.path.join(storage_root, "Pictures", rel_dir, fname)
        if "wallpaper" in src_path.lower():
            return os.path.join(storage_root, "Pictures", "Wallpapers", fname)
        return os.path.join(storage_root, "Pictures", fname)

    # 4. Videos
    if ext in VIDEO_EXTENSIONS:
        if SHOW_RE.search(fname):
            return os.path.join(storage_root, "Media", "library", "shows", fname)
        try:
            big_video = os.path.getsize(src_path) >= 400 * 1024 * 1024
        except OSError:
            big_video = False
        if any(m in lower for m in MOVIE_MARKERS) or (ext == ".mkv" and big_video):
            return os.path.join(storage_root, "Media", "library", "movies", fname)
        return os.path.join(storage_root, "Media", "home_videos", fname)

    # 5. Audio
    if ext in AUDIO_EXTENSIONS:
        return os.path.join(storage_root, "Media", "library", "music", fname)

    # 6. Games context
    if category == "Games":
        return os.path.join(storage_root, "Games", "PC", fname)

    # 7. Documents, code, spreadsheets, databases
    rel_dir = os.path.dirname(rel_path)
    if category == "Documents" and rel_dir:
        return os.path.join(storage_root, "Documents", rel_dir, fname)

    if ext in DOC_EXTENSIONS:
        return os.path.join(storage_root, "Documents", "Guides_and_Tutorials", get_doc_topic(fname), fname)
    if ext in SPREADSHEET_EXTENSIONS:
        return os.path.join(storage_root, "Documents", "Spreadsheets", fname)
    if ext in CODE_SUBDIRS:
        return os.path.join(storage_root, "Documents", "Development", CODE_SUBDIRS[ext], fname)
    if ext in DB_EXTENSIONS:
        return os.path.join(storage_root, "Documents", "Databases_and_Wallets", fname)
    if ext in INSTALLER_EXTENSIONS:
        return os.path.join(storage_root, "Documents", "Software", fname)

    # 8. Archives
    if ext in ARCHIVE_EXTENSIONS or ext == ".tar.gz":
        if any(k in lower for k in ("fitgirl", "repack", "crack", "game", "portable")):
            return os.path.join(storage_root, "Games", "PC", fname)
        if any(k in lower for k in ("rom", "pokemon", "mario", "zelda", "sonic")):
            return os.path.join(storage_root, "ROMs", "roms", "arcade", fname)
        if any(k in lower for k in ("backup", "bak", "dump")):
            return os.path.join(storage_root, "Backups", "archives", fname)
        return os.path.join(storage_root, "Documents", "Archives", fname)

    return os.path.join(storage_root, "Misc", fname)


def is_release_media_dir(dir_path):
    name = os.path.basename(dir_path).lower()
    if any(m in name for m in MOVIE_MARKERS) or SHOW_RE.search(name):
        return "shows" if SHOW_RE.search(name) else "movies"
    return None


def prune_empty_dirs(root_dir, keep_root=True):
    for current, dirs, files in os.walk(root_dir, topdown=False):
        if keep_root and os.path.abspath(current) == os.path.abspath(root_dir):
            continue
        try:
            if not os.listdir(current):
                os.rmdir(current)
        except OSError:
            pass


def process_category_dir(cat_dir, category, storage_root, min_age_sec, uid, users_gid, media_gid, dry_run, stats):
    if not os.path.isdir(cat_dir):
        return
    try:
        top_entries = sorted(os.listdir(cat_dir))
    except OSError as exc:
        print(f"[WARN] Cannot read {cat_dir}: {exc}", file=sys.stderr)
        return

    for entry in top_entries:
        if should_skip_name(entry):
            continue
        full_path = os.path.join(cat_dir, entry)
        if os.path.islink(full_path):
            continue
        if is_recent(full_path, time.time(), min_age_sec):
            stats["skipped_recent"] += 1
            continue

        # Keep intact top-level PC Game directories & Movie/TV release folders
        if os.path.isdir(full_path):
            if os.path.exists(os.path.join(full_path, ".git")):
                continue
            if category == "Games":
                dst_dir = os.path.join(storage_root, "Games", "PC", entry)
                res = safe_move_dir(full_path, dst_dir, storage_root, uid, users_gid, media_gid, dry_run)
                stats[res] = stats.get(res, 0) + 1
                continue
            if category == "Videos":
                media_kind = is_release_media_dir(full_path)
                if media_kind:
                    dst_dir = os.path.join(storage_root, "Media", "library", media_kind, entry)
                    res = safe_move_dir(full_path, dst_dir, storage_root, uid, users_gid, media_gid, dry_run)
                    stats[res] = stats.get(res, 0) + 1
                    continue
            if category == "Downloads":
                media_kind = is_release_media_dir(full_path)
                if media_kind:
                    dst_dir = os.path.join(storage_root, "Media", "library", media_kind, entry)
                elif any(k in entry.lower() for k in ("fitgirl", "repack", "codex", "dodi", "gog", "game")):
                    dst_dir = os.path.join(storage_root, "Games", "PC", entry)
                else:
                    dst_dir = os.path.join(storage_root, "Documents", "Software", entry)
                res = safe_move_dir(full_path, dst_dir, storage_root, uid, users_gid, media_gid, dry_run)
                stats[res] = stats.get(res, 0) + 1
                continue

            # Recurse normal subdirectories file-by-file
            for root, dirs, files in os.walk(full_path):
                dirs[:] = [d for d in dirs if not should_skip_name(d) and not os.path.exists(os.path.join(root, d, ".git"))]
                for f in files:
                    if should_skip_name(f):
                        continue
                    fp = os.path.join(root, f)
                    if os.path.islink(fp) or not os.path.isfile(fp):
                        continue
                    if is_recent(fp, time.time(), min_age_sec):
                        stats["skipped_recent"] += 1
                        continue
                    rel = os.path.relpath(fp, cat_dir)
                    dst = route_file(fp, category, rel, storage_root)
                    res = safe_move_file(fp, dst, storage_root, uid, users_gid, media_gid, dry_run)
                    stats[res] = stats.get(res, 0) + 1
        elif os.path.isfile(full_path):
            dst = route_file(full_path, category, entry, storage_root)
            res = safe_move_file(full_path, dst, storage_root, uid, users_gid, media_gid, dry_run)
            stats[res] = stats.get(res, 0) + 1

    if not dry_run:
        prune_empty_dirs(cat_dir, keep_root=True)


def infer_category(dir_path):
    base = os.path.basename(os.path.normpath(dir_path))
    if base in ("Downloads", "Documents", "Videos", "Pictures", "Photos", "Games"):
        return base
    return "Downloads"


def main():
    parser = argparse.ArgumentParser(description="NFP Fleet /storage Organizer")
    parser.add_argument("--storage-root", default=DEFAULT_STORAGE_ROOT)
    parser.add_argument("--watch-dirs", nargs="*", default=[])
    parser.add_argument("--incoming-root", default="/storage/Shared/incoming")
    parser.add_argument("--min-age-seconds", type=int, default=DEFAULT_MIN_AGE_SEC)
    parser.add_argument("--owner-user", default="t0psh31f")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not os.path.ismount(args.storage_root) and not os.path.isdir(args.storage_root):
        print(f"[ERROR] Storage root {args.storage_root} is not mounted/available.", file=sys.stderr)
        sys.exit(1)

    uid, users_gid = resolve_ids(args.owner_user, "users")
    _, media_gid = resolve_ids(args.owner_user, "media")
    stats = {"moved": 0, "moved-dir": 0, "dedup": 0, "skipped_recent": 0, "error": 0, "dry-run": 0}

    for wdir in args.watch_dirs:
        if os.path.isdir(wdir):
            process_category_dir(
                wdir, infer_category(wdir), args.storage_root, args.min_age_seconds,
                uid, users_gid, media_gid, args.dry_run, stats,
            )

    if args.incoming_root and os.path.isdir(args.incoming_root):
        for host_name in sorted(os.listdir(args.incoming_root)):
            if should_skip_name(host_name):
                continue
            host_dir = os.path.join(args.incoming_root, host_name)
            if not os.path.isdir(host_dir):
                continue
            if os.path.exists(os.path.join(host_dir, ".syncing")):
                print(f"[SKIP] {host_dir} is currently syncing.")
                continue
            for cat_name in sorted(os.listdir(host_dir)):
                if should_skip_name(cat_name):
                    continue
                cat_dir = os.path.join(host_dir, cat_name)
                if os.path.isdir(cat_dir):
                    process_category_dir(
                        cat_dir, cat_name, args.storage_root, args.min_age_seconds,
                        uid, users_gid, media_gid, args.dry_run, stats,
                    )

    print(json.dumps({"storage_root": args.storage_root, "dry_run": args.dry_run, "stats": stats}))


if __name__ == "__main__":
    main()
