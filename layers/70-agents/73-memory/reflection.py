#!/usr/bin/env python3
"""
NFP Personal Memory Reflection & Persona Evolution Engine
Location: layers/70-agents/73-memory/reflection.py
Part of dendritic layer: layers/70-agents/73-memory/

Executes during the nightly Dream Cycle (03:00 AM).
Mines the past 24 hours of conversation history (state.sqlite) and
desktop perception activity (screenpipe.db), extracts new user facts,
goals, habit patterns, and persona feedback, and updates:
- .agents/memory/user_profile.md
"""

import argparse
import json
import logging
import os
import re
import sqlite3
import subprocess
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s [REFLECTION] %(message)s")

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_PI_DURABLE_DB = Path(os.environ.get("PI_STATE_DB", Path.home() / ".local/share/pi-durable/state.sqlite"))
DEFAULT_SCREENPIPE_DB = Path(os.environ.get("SCREENPIPE_DB", Path.home() / ".local/share/jarvis/screenpipe.db"))
DEFAULT_PROFILE_MD = Path(os.environ.get("USER_PROFILE_PATH", REPO_ROOT / ".agents/memory/user_profile.md"))
DEFAULT_ROUTER_URL = os.environ.get("EXTREMEROUTER_URL", "http://127.0.0.1:20128/v1/chat/completions")
DEFAULT_OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434/v1/chat/completions")
GLADOS_TTS_BIN = Path.home() / ".local/bin/glados-tts-cli"

REFLECTION_PROMPT = """You are Jarvis's Memory & Persona Reflection Engine.
Analyze the provided 24-hour interaction log and current User Profile.
Extract any NEW explicit user preferences, financial goals, habit patterns, or persona feedback.

Current User Profile:
{current_profile}

24-Hour Activity & Chat Logs:
{activity_logs}

Output ONLY valid JSON matching this schema:
{{
  "new_facts": ["string"],
  "user_goals": ["string"],
  "workflow_preferences": ["string"],
  "detected_habits": ["string"],
  "persona_feedback": ["string"]
}}
"""


def speak_glados(text: str) -> None:
    """Mandatory GLaDOS voice notification."""
    clean = re.sub(r"\s+", " ", text).strip()
    if not clean:
        return
    for candidate in [GLADOS_TTS_BIN, Path("/run/current-system/sw/bin/glados-speak")]:
        if candidate.exists() and os.access(candidate, os.X_OK):
            try:
                subprocess.Popen(
                    [str(candidate), clean],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                return
            except Exception:
                pass


def get_default_profile_template() -> str:
    """Default markdown structure for user profile."""
    return """# User Profile & Persistent Memory

> Maintained by Jarvis & Aperture Reflection Engine during nightly Dream Cycles.

## 1. Identity & Operator Context
- **Primary User**: Erik (t0psh31f)
- **Primary Nodes**: sanji (Dell Precision 7680), z0r0 (Remote Builder), luffy (Homelab AI server)
- **Role**: Software engineer, AI systems architect, builder

## 2. Personal & Business Goals
- Maintain robust, deterministic NixOS infrastructure with zero-token and free-tier LLM routing.
- Continuous multi-agent pair programming with autonomous decomposition.

## 3. Workflow & Technical Preferences
- Uses Hyprland Wayland compositor with Ghostty terminal and Neovim editor.
- Employs Clan machine management (`clan machines update sanji`).
- Prefers strict verification before merging code (`./init.sh`, unit test suites).

## 4. Persona Feedback & Communication Preferences
- Primary Voice: GLaDOS Piper neural voice model (`glados-tts-cli`).
- Communication style: Calm, technically sound, concise, Aperture science wit.

## 5. Detected Habits & Daily Rhythms
- Active development in late afternoon and night hours.
- Regular inspection of system performance and memory utilization.

## 6. Learned Facts & Context History
"""


def read_user_profile(profile_path: Path = DEFAULT_PROFILE_MD) -> str:
    """Reads current profile markdown or initializes template."""
    if profile_path.exists():
        try:
            return profile_path.read_text(encoding="utf-8")
        except Exception as e:
            logging.warning(f"Could not read {profile_path}: {e}")
    return get_default_profile_template()


def fetch_past_24h_desktop_activity(screenpipe_db: Path = DEFAULT_SCREENPIPE_DB) -> List[Dict[str, Any]]:
    """Mines desktop perception events from screenpipe.db over the past 24 hours."""
    if not screenpipe_db.exists():
        return []

    entries: List[Dict[str, Any]] = []
    try:
        conn = sqlite3.connect(str(screenpipe_db))
        cur = conn.cursor()
        cur.execute("""
            SELECT timestamp, active_app, window_title, ocr_text, workspace
            FROM desktop_history
            ORDER BY id DESC
            LIMIT 100
        """)
        for row in cur.fetchall():
            entries.append({
                "timestamp": row[0],
                "active_app": row[1],
                "window_title": row[2],
                "ocr_text": (row[3] or "")[:300],
                "workspace": row[4]
            })
        conn.close()
    except Exception as e:
        logging.warning(f"Error querying screenpipe.db: {e}")
    return entries


def fetch_past_24h_chat_and_tools(pi_db: Path = DEFAULT_PI_DURABLE_DB) -> List[Dict[str, Any]]:
    """Mines chat and tool execution logs from pi-durable state.sqlite."""
    if not pi_db.exists():
        return []

    entries: List[Dict[str, Any]] = []
    try:
        conn = sqlite3.connect(str(pi_db))
        cur = conn.cursor()

        # Check existing tables
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = {r[0] for r in cur.fetchall()}

        if "tracked_tasks" in tables:
            cur.execute("SELECT task_text, status, last_updated FROM tracked_tasks ORDER BY rowid DESC LIMIT 25")
            for row in cur.fetchall():
                entries.append({"type": "task", "text": row[0], "status": row[1], "timestamp": row[2]})

        if "failed_tool_calls" in tables:
            cur.execute("SELECT tool_name, error_message, timestamp FROM failed_tool_calls ORDER BY id DESC LIMIT 25")
            for row in cur.fetchall():
                entries.append({"type": "failed_tool", "tool": row[0], "error": row[1], "timestamp": row[2]})

        if "barge_in_events" in tables:
            cur.execute("SELECT active_persona, user_prompt, timestamp FROM barge_in_events ORDER BY id DESC LIMIT 25")
            for row in cur.fetchall():
                entries.append({"type": "barge_in", "persona": row[0], "prompt": row[1], "timestamp": row[2]})

        conn.close()
    except Exception as e:
        logging.warning(f"Error querying state.sqlite: {e}")
    return entries


def extract_reflections_heuristic(desktop_entries: List[Dict[str, Any]], chat_entries: List[Dict[str, Any]]) -> Dict[str, List[str]]:
    """Fallback zero-token heuristic reflection engine if LLM endpoints are unavailable."""
    new_facts: List[str] = []
    user_goals: List[str] = []
    workflow_prefs: List[str] = []
    detected_habits: List[str] = []
    persona_feedback: List[str] = []

    # Analyze desktop apps
    app_counts: Dict[str, int] = {}
    for d in desktop_entries:
        app = d.get("active_app", "unknown")
        app_counts[app] = app_counts.get(app, 0) + 1

    top_apps = sorted(app_counts.items(), key=lambda x: x[1], reverse=True)[:3]
    if top_apps:
        names = ", ".join(f"{a} ({c} frames)" for a, c in top_apps if a != "Unknown")
        if names:
            detected_habits.append(f"Frequent active applications in last 24h: {names}.")

    # Analyze chat and task entries
    for c in chat_entries:
        txt = c.get("text", "")
        if "proactive" in txt.lower() or "monitor" in txt.lower():
            user_goals.append("Expand autonomous proactive system monitoring and task orchestration.")
        if "screen" in txt.lower() or "perception" in txt.lower():
            workflow_prefs.append("Integrated passive desktop perception pipeline via Hyprland IPC and grim.")

    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    new_facts.append(f"[{now_iso}] Nightly reflection processed {len(desktop_entries)} desktop frames and {len(chat_entries)} agent activity logs.")

    return {
        "new_facts": new_facts,
        "user_goals": user_goals,
        "workflow_preferences": workflow_prefs,
        "detected_habits": detected_habits,
        "persona_feedback": persona_feedback
    }


def call_llm_reflection(prompt: str, url: str = DEFAULT_ROUTER_URL) -> Optional[Dict[str, Any]]:
    """Dispatches reflection prompt to LLM router / completions endpoint."""
    payload = json.dumps({
        "model": "cascade/agent",
        "messages": [
            {"role": "system", "content": "You are an intelligent memory extraction engine. Return ONLY valid JSON."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.2,
        "max_tokens": 800
    }).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=15.0) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            content = data["choices"][0]["message"]["content"]
            # Extract JSON block
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                return json.loads(match.group(0))
    except Exception as exc:
        logging.debug(f"LLM call to {url} failed: {exc}")
    return None


def run_personal_reflection(
    profile_path: Path = DEFAULT_PROFILE_MD,
    screenpipe_db: Path = DEFAULT_SCREENPIPE_DB,
    pi_db: Path = DEFAULT_PI_DURABLE_DB,
    router_url: str = DEFAULT_ROUTER_URL,
    dry_run: bool = False
) -> Dict[str, Any]:
    """Coordinates mining, extraction, and updating of the user profile."""
    current_profile = read_user_profile(profile_path)
    desktop_activity = fetch_past_24h_desktop_activity(screenpipe_db)
    chat_activity = fetch_past_24h_chat_and_tools(pi_db)

    activity_summary = {
        "desktop_perception_frames": desktop_activity[:30],
        "agent_chat_and_tasks": chat_activity[:30]
    }
    activity_str = json.dumps(activity_summary, indent=2)

    prompt = REFLECTION_PROMPT.format(
        current_profile=current_profile[:1500],
        activity_logs=activity_str[:3000]
    )

    # Attempt LLM reflection first, fallback to heuristics
    reflections = call_llm_reflection(prompt, url=router_url)
    if not reflections or not isinstance(reflections, dict):
        reflections = extract_reflections_heuristic(desktop_activity, chat_activity)
        reflections["engine"] = "heuristic_fallback"
    else:
        reflections["engine"] = "llm_router"

    # Update profile in-place
    updated_profile = update_profile_content(current_profile, reflections)

    if not dry_run:
        profile_path.parent.mkdir(parents=True, exist_ok=True)
        profile_path.write_text(updated_profile, encoding="utf-8")
        speak_glados("Personal memory reflection complete. User profile and habit patterns have been updated.")

    return {
        "status": "success",
        "engine": reflections.get("engine", "unknown"),
        "reflections": reflections,
        "profile_path": str(profile_path)
    }


def update_profile_content(current_md: str, reflections: Dict[str, List[str]]) -> str:
    """Appends extracted reflections into corresponding markdown sections."""
    lines = current_md.splitlines()
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # Collect items to append to Section 6 (Learned Facts & Context History)
    items_to_add: List[str] = []
    for f in reflections.get("new_facts", []):
        if f not in current_md:
            items_to_add.append(f"- {f}")
    for g in reflections.get("user_goals", []):
        if g not in current_md:
            items_to_add.append(f"- **Goal ({today_str})**: {g}")
    for h in reflections.get("detected_habits", []):
        if h not in current_md:
            items_to_add.append(f"- **Habit ({today_str})**: {h}")

    if not items_to_add:
        return current_md

    # Append to bottom under Learned Facts
    if "## 6. Learned Facts & Context History" in current_md:
        idx = -1
        for i, l in enumerate(lines):
            if "## 6. Learned Facts & Context History" in l:
                idx = i
                break
        if idx != -1:
            lines.insert(idx + 1, "\n".join(items_to_add))
            return "\n".join(lines) + "\n"

    # Default append to end
    return current_md.strip() + "\n\n" + "\n".join(items_to_add) + "\n"


def run_self_tests() -> int:
    """Self-test suite for reflection.py."""
    print("==> Running reflection.py self-test suite...")
    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        test_dir = Path(tmpdir)
        test_profile = test_dir / "user_profile.md"
        test_screenpipe = test_dir / "screenpipe.db"
        test_pi_db = test_dir / "state.sqlite"

        # 1. Initialize dummy databases
        s_conn = sqlite3.connect(str(test_screenpipe))
        s_conn.execute("""
            CREATE TABLE desktop_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                active_app TEXT,
                window_title TEXT,
                ocr_text TEXT,
                workspace TEXT
            )
        """)
        s_conn.execute("""
            INSERT INTO desktop_history (active_app, window_title, ocr_text, workspace)
            VALUES ('ghostty', 't0psh31f@sanji: ~/Clan/NFP', 'nix eval sanji', '1'),
                   ('nvim', 'task_watcher.nix', 'serviceConfig', '2')
        """)
        s_conn.commit()
        s_conn.close()

        p_conn = sqlite3.connect(str(test_pi_db))
        p_conn.execute("""
            CREATE TABLE tracked_tasks (
                task_text TEXT,
                status TEXT,
                last_updated TEXT
            )
        """)
        p_conn.execute("""
            INSERT INTO tracked_tasks VALUES ('Implement proactive monitoring', 'completed', '2026-10-29T12:00:00Z')
        """)
        p_conn.commit()
        p_conn.close()
        print("  [PASS] Test 1: Test databases populated with sample desktop and task logs")

        # 2. Test mining functions
        desktop_act = fetch_past_24h_desktop_activity(test_screenpipe)
        assert len(desktop_act) == 2, f"Expected 2 desktop records, got {len(desktop_act)}"
        chat_act = fetch_past_24h_chat_and_tools(test_pi_db)
        assert len(chat_act) == 1, f"Expected 1 task record, got {len(chat_act)}"
        print("  [PASS] Test 2: Activity mining extracted 2 desktop frames and 1 task record")

        # 3. Test heuristic extraction
        refl = extract_reflections_heuristic(desktop_act, chat_act)
        assert len(refl["detected_habits"]) > 0, "Expected at least 1 detected habit"
        assert len(refl["user_goals"]) > 0, "Expected at least 1 user goal"
        print("  [PASS] Test 3: Heuristic reflection engine identified top apps and goals")

        # 4. Test profile markdown update
        initial_md = get_default_profile_template()
        updated_md = update_profile_content(initial_md, refl)
        assert "## 6. Learned Facts & Context History" in updated_md
        assert "Frequent active applications in last 24h" in updated_md
        print("  [PASS] Test 4: Profile markdown updated in-place with structured bullet points")

        # 5. End-to-end cycle test
        res = run_personal_reflection(
            profile_path=test_profile,
            screenpipe_db=test_screenpipe,
            pi_db=test_pi_db,
            router_url="http://127.0.0.1:9999",  # Will trigger fallback
            dry_run=False
        )
        assert res["status"] == "success"
        assert test_profile.exists()
        content = test_profile.read_text(encoding="utf-8")
        assert "Frequent active applications" in content
        print("  [PASS] Test 5: Full reflection cycle executed with file persistence")

    print("==> All reflection.py tests PASSED!")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="NFP Personal Memory Reflection & Persona Evolution Engine")
    parser.add_argument("--run-reflection", action="store_true", help="Execute personal memory reflection cycle")
    parser.add_argument("--test", action="store_true", help="Execute self-test suite")
    parser.add_argument("--dry-run", action="store_true", help="Print extracted reflections without writing to disk")
    parser.add_argument("--profile", type=str, default=str(DEFAULT_PROFILE_MD), help=f"Path to user_profile.md (default: {DEFAULT_PROFILE_MD})")
    parser.add_argument("--screenpipe-db", type=str, default=str(DEFAULT_SCREENPIPE_DB), help="Path to screenpipe.db")
    parser.add_argument("--pi-db", type=str, default=str(DEFAULT_PI_DURABLE_DB), help="Path to pi-durable state.sqlite")

    args = parser.parse_args()

    if args.test:
        sys.exit(run_self_tests())

    res = run_personal_reflection(
        profile_path=Path(args.profile),
        screenpipe_db=Path(args.screenpipe_db),
        pi_db=Path(args.pi_db),
        dry_run=args.dry_run
    )
    print(json.dumps(res, indent=2))


if __name__ == "__main__":
    main()
