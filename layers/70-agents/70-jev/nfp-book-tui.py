#!/usr/bin/env python3
"""Interactive Terminal Review Screen for E-Book Vault & RAG Ingestion Pipeline.

Inspects purified books, quarantined artifacts, cover presence, and Jev AI/Income RAG routing.
"""

import argparse
import curses
import json
import os
import re
import sys
import urllib.request

DEFAULT_LIBRARY = os.environ.get("BOOK_LIBRARY_DIR", "/data/vault/library")
DEFAULT_QUARANTINE = os.environ.get("BOOK_QUARANTINE_DIR", "/data/vault/quarantine")
DEFAULT_BRAIN_INBOX = os.environ.get("BRAIN_INBOX_DIR", "/var/lib/brain-service/inbox")
BRAIN_SERVICE_URL = os.environ.get("BRAIN_SERVICE_URL", "http://127.0.0.1:8010")


def scan_vault(library_dir, quarantine_dir, brain_inbox):
    """Scan library and quarantine directories to collect items."""
    library_items = []
    quarantine_items = []
    rag_items = []

    # 1. Scan Library
    if os.path.exists(library_dir):
        for root, dirs, files in os.walk(library_dir):
            if "by-topic" in root:
                continue
            receipt = None
            if ".purified-metadata.json" in files:
                try:
                    with open(os.path.join(root, ".purified-metadata.json"), "r", encoding="utf-8") as rf:
                        receipt = json.load(rf)
                except Exception:
                    pass

            book_files = [f for f in files if f.endswith((".epub", ".pdf", ".mobi", ".azw3", ".cbz"))]

            for bf in book_files:
                fpath = os.path.join(root, bf)
                size_mb = round(os.path.getsize(fpath) / (1024 * 1024), 2)

                # Check companion metadata receipt or folder metadata
                receipt = None
                companion_meta = os.path.splitext(fpath)[0] + ".metadata.json"
                if os.path.exists(companion_meta):
                    try:
                        with open(companion_meta, "r", encoding="utf-8") as rf:
                            receipt = json.load(rf)
                    except Exception:
                        pass
                elif ".purified-metadata.json" in files:
                    try:
                        with open(os.path.join(root, ".purified-metadata.json"), "r", encoding="utf-8") as rf:
                            receipt = json.load(rf)
                    except Exception:
                        pass

                # Check companion cover or directory cover
                companion_cover = os.path.splitext(fpath)[0] + ".cover.jpg"
                has_cover = (
                    os.path.exists(companion_cover)
                    or "cover.jpg" in files
                    or "cover.png" in files
                )

                triage = receipt.get("triage", {}) if receipt else {}
                meta = receipt.get("metadata", {}) if receipt else {}

                # Parse year from metadata or filename prefix [YYYY]
                year = meta.get("year")
                year_m = re.match(r"^\[(\d{4})\]", bf)
                if year_m:
                    year = year or year_m.group(1)
                year_str = str(year or "0000")
                undated = (year_str == "0000")

                author = meta.get("author") or "Unknown Author"
                title = meta.get("title") or os.path.splitext(bf)[0]

                # Parse author/title from filename if not in receipt
                if author == "Unknown Author" and " - (" in bf:
                    parts = bf.split(" - (", 1)
                    title_part = re.sub(r"^\[\d{4}\]\s*", "", parts[0]).strip()
                    author_part = parts[1].rstrip(")").rstrip(os.path.splitext(bf)[1]).strip()
                    title = title or title_part
                    author = author_part

                library_items.append({
                    "title": title,
                    "author": author,
                    "year": year_str,
                    "undated": undated,
                    "filename": bf,
                    "path": fpath,
                    "size_mb": size_mb,
                    "cover": has_cover,
                    "domain": triage.get("primary_domain", "unclassified"),
                    "priority": triage.get("brain_service_ingest_priority", "none"),
                    "ai_income": triage.get("is_ai_or_passive_income", False),
                    "rag_ingested": receipt.get("rag_ingested", False) if receipt else False,
                    "meta": meta
                })

    # 2. Scan Quarantine
    non_books = os.path.join(quarantine_dir, "non-books")
    if os.path.exists(non_books):
        for f in sorted(os.listdir(non_books)):
            if f.endswith(".json"):
                continue
            fpath = os.path.join(non_books, f)
            if os.path.isfile(fpath):
                size_kb = round(os.path.getsize(fpath) / 1024, 1)
                q_meta = {}
                q_meta_file = fpath + ".quarantine.json"
                if os.path.exists(q_meta_file):
                    try:
                        with open(q_meta_file, "r", encoding="utf-8") as qf:
                            q_meta = json.load(qf)
                    except Exception:
                        pass
                quarantine_items.append({
                    "filename": f,
                    "path": fpath,
                    "size_kb": size_kb,
                    "reason": q_meta.get("reason", "Non-book format / corrupted signature"),
                    "time": q_meta.get("quarantine_time", "Unknown")
                })

    # 3. Scan Brain Inbox
    if os.path.exists(brain_inbox):
        for f in sorted(os.listdir(brain_inbox)):
            fpath = os.path.join(brain_inbox, f)
            if os.path.isfile(fpath):
                indexed = f.endswith(".indexed")
                rag_items.append({
                    "filename": f,
                    "path": fpath,
                    "indexed": indexed,
                    "size_mb": round(os.path.getsize(fpath) / (1024 * 1024), 2)
                })

    return library_items, quarantine_items, rag_items


def trigger_rag_ingest(book_path):
    """Trigger Brain-Service API ingest."""
    url = f"{BRAIN_SERVICE_URL.rstrip('/')}/ingest/path"
    try:
        payload = json.dumps({"path": os.path.abspath(book_path)}).encode("utf-8")
        req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=4.0) as resp:
            if resp.status == 200:
                return True, "Ingested successfully"
    except Exception as e:
        return False, str(e)
    return False, "Failed"


def print_cli_summary(library_items, quarantine_items, rag_items):
    """Print non-interactive console summary."""
    print("=" * 64)
    print(" 📚 NFP Book Vault & RAG Ingestion Pipeline — Status Report")
    print("=" * 64)
    print(f"Total Purified Books:   {len(library_items)}")
    ai_books = [b for b in library_items if b.get("ai_income")]
    print(f"AI & Passive Income:    {len(ai_books)}")
    covers = [b for b in library_items if b.get("cover")]
    print(f"Books with Cover Art:   {len(covers)}")
    print(f"Quarantined Artifacts:  {len(quarantine_items)}")
    print(f"RAG Inbox Documents:    {len(rag_items)}")
    print("-" * 64)

    if library_items:
        print("Recent Purified Books:")
        for b in library_items[:8]:
            cover_tag = "[COVER ✓]" if b["cover"] else "[NO COVER]"
            rag_tag = "[RAG ✓]" if b["rag_ingested"] else ""
            print(f" • {b['author']} — {b['title']} {cover_tag} {rag_tag} ({b['domain']})")

    if quarantine_items:
        print("\nRecent Quarantined Items:")
        for q in quarantine_items[:5]:
            print(f" ⚠️ {q['filename']} ({q['size_kb']} KB) — {q['reason']}")
    print("=" * 64)


def curses_tui(stdscr, library_items, quarantine_items, rag_items):
    """Interactive curses TUI loop."""
    curses.curs_set(0)
    curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)
    curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK)
    curses.init_pair(4, curses.COLOR_RED, curses.COLOR_BLACK)
    curses.init_pair(5, curses.COLOR_BLACK, curses.COLOR_CYAN)

    current_tab = 0  # 0: Library, 1: Quarantine, 2: RAG Inbox
    tabs = ["1: Library", "2: Quarantine", "3: RAG Ingest Inbox"]
    selected_idx = 0
    status_msg = "Ready. [j/k]: Nav | [Tab]: Switch Tab | [r]: Ingest RAG | [q]: Quit"

    while True:
        stdscr.clear()
        h, w = stdscr.getmaxyx()

        # Header
        header_text = " 📚 NFP Book Vault & RAG Purification TUI "
        stdscr.attron(curses.color_pair(5))
        stdscr.addstr(0, 0, header_text.ljust(w)[:w])
        stdscr.attroff(curses.color_pair(5))

        # Tabs
        tab_line = " "
        for i, t in enumerate(tabs):
            if i == current_tab:
                tab_line += f"[{t}] "
            else:
                tab_line += f" {t}  "
        stdscr.addstr(1, 0, tab_line[:w], curses.A_BOLD)
        stdscr.addstr(2, 0, ("─" * w)[:w])

        items = library_items if current_tab == 0 else (quarantine_items if current_tab == 1 else rag_items)
        if selected_idx >= len(items):
            selected_idx = max(0, len(items) - 1)

        # Content area split: Left list, Right details
        split_x = int(w * 0.55)
        list_h = h - 5

        # Render Left List
        for idx in range(min(len(items), list_h)):
            y = 3 + idx
            item = items[idx]
            is_sel = (idx == selected_idx)
            style = curses.A_REVERSE if is_sel else curses.A_NORMAL

            if current_tab == 0:
                icon = "🤖" if item.get("ai_income") else "📖"
                c_tag = "✓" if item["cover"] else "✗"
                undated_tag = " [⚠️ 0000]" if item.get("undated") else ""
                line = f"{icon} [{c_tag}] [{item['year']}] {item['title']} - ({item['author']}){undated_tag}"
            elif current_tab == 1:
                line = f"⚠️ {item['filename']} ({item['size_kb']}KB)"
            else:
                idx_tag = "[DONE]" if item["indexed"] else "[PENDING]"
                line = f"⚡ {idx_tag} {item['filename']}"

            stdscr.addstr(y, 2, line[:split_x - 3].ljust(split_x - 3), style)

        # Vertical separator
        for y in range(3, h - 2):
            stdscr.addstr(y, split_x, "│")

        # Render Right Detail Pane
        if items and selected_idx < len(items):
            sel = items[selected_idx]
            dy = 3
            if current_tab == 0:
                stdscr.addstr(dy, split_x + 2, "TITLE:", curses.A_BOLD)
                stdscr.addstr(dy + 1, split_x + 4, str(sel["title"])[:w - split_x - 6])
                stdscr.addstr(dy + 3, split_x + 2, "AUTHOR:", curses.A_BOLD)
                stdscr.addstr(dy + 4, split_x + 4, str(sel["author"])[:w - split_x - 6])
                stdscr.addstr(dy + 6, split_x + 2, "YEAR:", curses.A_BOLD)
                y_color = curses.color_pair(3) if sel.get("undated") else curses.color_pair(2)
                stdscr.addstr(dy + 7, split_x + 4, f"[{sel['year']}]" + (" (Needs Year Review)" if sel.get("undated") else ""), y_color)
                stdscr.addstr(dy + 9, split_x + 2, "DOMAIN TAXONOMY:", curses.A_BOLD)
                stdscr.addstr(dy + 10, split_x + 4, f"{sel['domain']}", curses.color_pair(2))
                stdscr.addstr(dy + 12, split_x + 2, "RAG INGEST PRIORITY:", curses.A_BOLD)
                p_color = curses.color_pair(2) if "p0" in sel['priority'] else curses.color_pair(3)
                stdscr.addstr(dy + 13, split_x + 4, f"{sel['priority']}", p_color)
                stdscr.addstr(dy + 15, split_x + 2, "COVER ART:", curses.A_BOLD)
                c_str = "Companion .cover.jpg extracted (OK)" if sel["cover"] else "Missing / Not Extracted"
                stdscr.addstr(dy + 16, split_x + 4, c_str, curses.color_pair(2 if sel["cover"] else 4))
                stdscr.addstr(dy + 18, split_x + 2, "FILE SIZE:", curses.A_BOLD)
                stdscr.addstr(dy + 19, split_x + 4, f"{sel['size_mb']} MB")
            elif current_tab == 1:
                stdscr.addstr(dy, split_x + 2, "QUARANTINED FILE:", curses.A_BOLD)
                stdscr.addstr(dy + 1, split_x + 4, sel["filename"][:w - split_x - 6])
                stdscr.addstr(dy + 3, split_x + 2, "REASON:", curses.A_BOLD)
                stdscr.addstr(dy + 4, split_x + 4, sel["reason"][:w - split_x - 6], curses.color_pair(4))
                stdscr.addstr(dy + 6, split_x + 2, "QUARANTINED AT:", curses.A_BOLD)
                stdscr.addstr(dy + 7, split_x + 4, sel["time"][:w - split_x - 6])
            else:
                stdscr.addstr(dy, split_x + 2, "RAG DOCUMENT:", curses.A_BOLD)
                stdscr.addstr(dy + 1, split_x + 4, sel["filename"][:w - split_x - 6])
                stdscr.addstr(dy + 3, split_x + 2, "STATUS:", curses.A_BOLD)
                status_txt = "Indexed in PGVector" if sel["indexed"] else "Queued for indexing"
                stdscr.addstr(dy + 4, split_x + 4, status_txt, curses.color_pair(2 if sel["indexed"] else 3))

        # Footer
        stdscr.addstr(h - 2, 0, ("─" * w)[:w])
        stdscr.addstr(h - 1, 1, status_msg[:w - 2], curses.color_pair(1))
        stdscr.refresh()

        # Input handling
        try:
            key = stdscr.getch()
        except KeyboardInterrupt:
            break

        if key in (ord('q'), ord('x'), 27):
            break
        elif key in (ord('\t'), curses.KEY_RIGHT):
            current_tab = (current_tab + 1) % len(tabs)
            selected_idx = 0
        elif key == curses.KEY_LEFT:
            current_tab = (current_tab - 1) % len(tabs)
            selected_idx = 0
        elif key in (curses.KEY_UP, ord('k')):
            selected_idx = max(0, selected_idx - 1)
        elif key in (curses.KEY_DOWN, ord('j')):
            selected_idx = min(len(items) - 1, selected_idx + 1)
        elif key == ord('r') and current_tab == 0 and items:
            sel = items[selected_idx]
            ok, msg = trigger_rag_ingest(sel["path"])
            status_msg = f"RAG Trigger: {msg}"


def main():
    parser = argparse.ArgumentParser(description="NFP E-Book Vault Review TUI")
    parser.add_argument("--library", default=DEFAULT_LIBRARY, help="Library directory path")
    parser.add_argument("--quarantine", default=DEFAULT_QUARANTINE, help="Quarantine directory path")
    parser.add_argument("--brain-inbox", default=DEFAULT_BRAIN_INBOX, help="Brain inbox directory path")
    parser.add_argument("--status", action="store_true", help="Print summary report and exit")

    args = parser.parse_args()

    lib_items, quar_items, rag_items = scan_vault(args.library, args.quarantine, args.brain_inbox)

    if args.status or not sys.stdin.isatty():
        print_cli_summary(lib_items, quar_items, rag_items)
    else:
        curses.wrapper(curses_tui, lib_items, quar_items, rag_items)


if __name__ == "__main__":
    main()
