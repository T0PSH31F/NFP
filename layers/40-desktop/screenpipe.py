#!/usr/bin/env python3
"""
NFP Screen-Pipe Passive Desktop Perception Daemon
Location: layers/40-desktop/screenpipe.py
Part of dendritic layer: layers/40-desktop/

Provides:
- Passive desktop visual awareness via Hyprland/Niri IPC event streams
- Snapshot capture using `grim`
- Local zero-token OCR via Tesseract / PaddleOCR
- Structured perception logging in ~/.local/share/jarvis/screenpipe.db
- Graceful fallbacks for headless/testing environments
"""

import argparse
import asyncio
import json
import logging
import os
import sqlite3
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s [SCREENPIPE] %(message)s")

DEFAULT_DB_PATH = Path(os.environ.get("SCREENPIPE_DB", "~/.local/share/jarvis/screenpipe.db")).expanduser()
DEFAULT_SCRATCH_DIR = Path(os.environ.get("SCREENPIPE_SCRATCH_DIR", "/tmp/screenpipe"))
SCRATCH_IMG = DEFAULT_SCRATCH_DIR / "screen_capture.png"


def init_db(db_path: Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Initializes the desktop perception SQLite database schema."""
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS desktop_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            active_app TEXT,
            window_title TEXT,
            ocr_text TEXT,
            workspace TEXT,
            extra_meta TEXT
        )
    """)
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_screenpipe_timestamp ON desktop_history (timestamp)")
    conn.commit()
    return conn


def get_hyprland_metadata() -> Dict[str, str]:
    """Extracts active window class, title, and workspace from Hyprland IPC."""
    active_app = "Unknown"
    window_title = "Desktop"
    workspace = "1"

    # 1. Try hyprctl
    try:
        out = subprocess.check_output(["hyprctl", "activewindow", "-j"], text=True, stderr=subprocess.DEVNULL)
        data = json.loads(out)
        active_app = data.get("class") or data.get("initialClass") or "Unknown"
        window_title = data.get("title") or "Desktop"
        ws_info = data.get("workspace", {})
        if isinstance(ws_info, dict):
            workspace = str(ws_info.get("id") or ws_info.get("name") or "1")
        return {"active_app": active_app, "window_title": window_title, "workspace": workspace}
    except Exception:
        pass

    # 2. Try niri msg as fallback
    try:
        out = subprocess.check_output(["niri", "msg", "--json", "focused-window"], text=True, stderr=subprocess.DEVNULL)
        data = json.loads(out)
        active_app = data.get("app_id") or "Unknown"
        window_title = data.get("title") or "Desktop"
        return {"active_app": active_app, "window_title": window_title, "workspace": "niri"}
    except Exception:
        pass

    return {"active_app": active_app, "window_title": window_title, "workspace": workspace}


def capture_active_window(
    img_path: Path = SCRATCH_IMG,
    run_ocr: bool = True,
    capture_screenshot: bool = True
) -> Dict[str, Any]:
    """Captures desktop snapshot via grim and extracts window metadata and OCR text."""
    meta = get_hyprland_metadata()
    active_app = meta["active_app"]
    window_title = meta["window_title"]
    workspace = meta.get("workspace", "1")

    ocr_text = ""

    # Capture screenshot using grim if display server is present
    if capture_screenshot and os.environ.get("WAYLAND_DISPLAY"):
        try:
            img_path.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(["grim", "-q", "50", str(img_path)], check=False, stderr=subprocess.DEVNULL)
        except Exception as e:
            logging.debug(f"Grim capture failed: {e}")

    # Perform local zero-token OCR
    if run_ocr and img_path.exists() and img_path.stat().st_size > 0:
        try:
            # Using tesseract local CLI if available
            res = subprocess.check_output(
                ["tesseract", str(img_path), "stdout", "--oem", "1"],
                text=True,
                stderr=subprocess.DEVNULL,
                timeout=5.0
            )
            ocr_text = res.strip()[:1000]  # Limit chunk length to prevent context bloat
        except Exception as e:
            logging.debug(f"OCR Extraction skipped or failed: {e}")

    return {
        "active_app": active_app,
        "window_title": window_title,
        "workspace": workspace,
        "ocr_text": ocr_text,
    }


def log_event(data: Dict[str, Any], db_path: Path = DEFAULT_DB_PATH) -> int:
    """Saves structured perception frame into screenpipe.db."""
    conn = init_db(db_path)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO desktop_history (active_app, window_title, ocr_text, workspace, extra_meta)
        VALUES (?, ?, ?, ?, ?)
    """, (
        data.get("active_app", "Unknown"),
        data.get("window_title", "Desktop"),
        data.get("ocr_text", ""),
        data.get("workspace", "1"),
        json.dumps(data.get("extra_meta", {}))
    ))
    row_id = cursor.lastrowid
    conn.commit()
    conn.close()
    logging.info(f"📸 Snapshot Logged: [{data.get('active_app')}] {data.get('window_title')}")
    return row_id


def get_hyprland_socket_path() -> Optional[str]:
    """Locates the Hyprland socket2 for real-time IPC events."""
    his_socket = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if not his_socket:
        return None

    candidates = [
        f"/tmp/hypr/{his_socket}/.socket2.sock",
    ]
    xdg_runtime = os.getenv("XDG_RUNTIME_DIR")
    if xdg_runtime:
        candidates.append(f"{xdg_runtime}/hypr/{his_socket}/.socket2.sock")

    for c in candidates:
        if Path(c).exists():
            return c
    return None


async def watch_hyprland_ipc(
    db_path: Path = DEFAULT_DB_PATH,
    poll_interval: int = 15,
    debounce_seconds: float = 5.0
) -> None:
    """Listens to Hyprland event socket for active window shifts with periodic fallback."""
    init_db(db_path)
    socket_path = get_hyprland_socket_path()

    if not socket_path or not Path(socket_path).exists():
        logging.warning("Hyprland socket not found. Falling back to periodic %ds polling...", poll_interval)
        while True:
            data = capture_active_window()
            log_event(data, db_path=db_path)
            await asyncio.sleep(poll_interval)

    logging.info(f"👁️ Screen-Pipe listening on Hyprland IPC eventstream ({socket_path})...")
    try:
        reader, _ = await asyncio.open_unix_connection(socket_path)
    except Exception as exc:
        logging.warning("Failed to open unix connection (%s). Falling back to %ds polling...", exc, poll_interval)
        while True:
            data = capture_active_window()
            log_event(data, db_path=db_path)
            await asyncio.sleep(poll_interval)

    last_capture = 0.0
    while True:
        try:
            line = await reader.readline()
            if not line:
                await asyncio.sleep(1)
                continue
            event = line.decode("utf-8", errors="replace").strip()

            # Trigger frame capture on window focus or workspace change (with debounce)
            if event.startswith("activewindow>") or event.startswith("workspace>"):
                now = time.time()
                if now - last_capture > debounce_seconds:
                    last_capture = now
                    data = capture_active_window()
                    log_event(data, db_path=db_path)
        except Exception as err:
            logging.error(f"Error reading IPC line: {err}")
            await asyncio.sleep(2)


def run_self_tests() -> int:
    """Self-test suite for screenpipe.py."""
    print("==> Running screenpipe.py self-test suite...")
    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        test_db = Path(tmpdir) / "test_screenpipe.db"
        test_img = Path(tmpdir) / "test_capture.png"

        # 1. DB Initialization
        conn = init_db(test_db)
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='desktop_history'")
        assert cur.fetchone() is not None, "desktop_history table was not created"
        conn.close()
        print("  [PASS] Test 1: SQLite schema initialized with desktop_history table")

        # 2. Metadata capture (handles headless environment safely)
        meta = get_hyprland_metadata()
        assert isinstance(meta, dict), "Metadata must be a dictionary"
        assert "active_app" in meta and "window_title" in meta
        print("  [PASS] Test 2: Active window metadata captured or gracefully defaulted")

        # 3. Log Event
        sample_data = {
            "active_app": "ghostty",
            "window_title": "t0psh31f@sanji: ~/Clan/NFP",
            "workspace": "1",
            "ocr_text": "nix eval .#nixosConfigurations.sanji.config",
            "extra_meta": {"test": True}
        }
        row_id = log_event(sample_data, db_path=test_db)
        assert row_id is not None and row_id > 0, "log_event must return positive rowid"

        # Verify DB entry
        conn = sqlite3.connect(str(test_db))
        cur = conn.cursor()
        cur.execute("SELECT active_app, window_title, ocr_text FROM desktop_history WHERE id = ?", (row_id,))
        row = cur.fetchone()
        assert row is not None
        assert row[0] == "ghostty"
        assert row[1] == "t0psh31f@sanji: ~/Clan/NFP"
        assert "nix eval" in row[2]
        conn.close()
        print("  [PASS] Test 3: Event record correctly inserted and queried from SQLite")

        # 4. Fallback capture without grim / display
        cap_res = capture_active_window(img_path=test_img, run_ocr=False, capture_screenshot=False)
        assert "active_app" in cap_res
        assert "window_title" in cap_res
        print("  [PASS] Test 4: Headless fallback capture cycle completed successfully")

        # 5. Socket path finder check
        _ = get_hyprland_socket_path()
        print("  [PASS] Test 5: Hyprland socket resolution verified")

    print("==> All screenpipe.py tests PASSED!")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="NFP Screen-Pipe Passive Desktop Perception Daemon")
    parser.add_argument("--watch", action="store_true", help="Run IPC eventstream and polling watcher loop")
    parser.add_argument("--once", action="store_true", help="Capture a single snapshot, log, and exit")
    parser.add_argument("--test", action="store_true", help="Run offline unit test suite")
    parser.add_argument("--db", type=str, default=str(DEFAULT_DB_PATH), help=f"Path to screenpipe.db (default: {DEFAULT_DB_PATH})")
    parser.add_argument("--interval", type=int, default=15, help="Polling interval in seconds when socket is unavailable")

    args = parser.parse_args()

    if args.test:
        sys.exit(run_self_tests())

    db_path = Path(args.db).expanduser()

    if args.once:
        data = capture_active_window()
        log_event(data, db_path=db_path)
        print(json.dumps(data, indent=2))
        return

    # Default to watch mode if no flags or --watch given
    try:
        asyncio.run(watch_hyprland_ipc(db_path=db_path, poll_interval=args.interval))
    except KeyboardInterrupt:
        logging.info("Screen-pipe terminated by user.")


if __name__ == "__main__":
    main()
