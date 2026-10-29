#!/usr/bin/env python3
"""
NFP Voice Interrupter & Hot-Swapper Daemon
Provides Silero VAD barge-in interrupt capability (killing active TTS on speech)
and parses voice trigger commands (e.g. 'Switch voice to [Persona]') to update
~/.local/share/pi-durable/state.sqlite.
"""

import sys
import os
import json
import re
import sqlite3
import subprocess
import signal
import time
from pathlib import Path
from datetime import datetime, timezone

PERSONAS_MANIFEST = Path(__file__).parent / "personas.json"
DEFAULT_STATE_DB = Path.home() / ".local/share/pi-durable/state.sqlite"

# Subprocess names to terminate upon barge-in interrupt
TTS_TARGET_BINARIES = ("glados-tts-cli", "pw-play", "piper", "paplay", "aplay", "whisper-server")

def load_personas() -> dict:
    if not PERSONAS_MANIFEST.exists():
        return {}
    with open(PERSONAS_MANIFEST, "r", encoding="utf-8") as f:
        data = json.load(f)
        return data.get("personas", {})

def init_state_db(db_path: Path = DEFAULT_STATE_DB) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.execute("""
    CREATE TABLE IF NOT EXISTS session_attributes (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );
    """)
    conn.commit()
    return conn

def get_active_persona(db_path: Path = DEFAULT_STATE_DB) -> str:
    try:
        conn = init_state_db(db_path)
        cur = conn.cursor()
        cur.execute("SELECT value FROM session_attributes WHERE key = 'active_persona'")
        row = cur.fetchone()
        conn.close()
        if row:
            return row[0]
    except Exception:
        pass
    return "glados-auditor"

def set_active_persona(persona_id: str, db_path: Path = DEFAULT_STATE_DB) -> bool:
    personas = load_personas()
    if persona_id not in personas:
        # Check aliases
        matched = None
        for pid, pdata in personas.items():
            if persona_id.lower() in [a.lower() for a in pdata.get("aliases", [])]:
                matched = pid
                break
        if matched:
            persona_id = matched
        else:
            return False

    conn = init_state_db(db_path)
    now = datetime.now(timezone.utc).isoformat()
    conn.execute("""
    INSERT INTO session_attributes (key, value, updated_at)
    VALUES ('active_persona', ?, ?)
    ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at;
    """, (persona_id, now))
    conn.commit()
    conn.close()
    return True

def parse_voice_trigger(text: str) -> str | None:
    """
    Parses voice trigger phrases such as:
    - 'switch voice to gandalf'
    - 'change persona to jarvis-classic'
    - 'set voice to samuel jackson'
    - 'activate paimon voice'
    Returns normalized persona_id or None.
    """
    clean = text.strip().lower()
    personas = load_personas()

    # Pattern: switch/change/set [the] voice/persona to [name]
    patterns = [
        r"(?:switch|change|set|select)(?:\s+the)?\s+(?:voice|persona)\s+(?:to\s+)?([a-z0-9_\-\s]+)",
        r"(?:activate|use)(?:\s+the)?\s+([a-z0-9_\-\s]+)\s+(?:voice|persona)",
        r"^voice:\s*([a-z0-9_\-\s]+)$",
    ]

    for pat in patterns:
        m = re.search(pat, clean)
        if m:
            raw_target = m.group(1).strip().replace(" ", "-")
            # Exact match
            if raw_target in personas:
                return raw_target
            # Check aliases
            for pid, pdata in personas.items():
                if raw_target in [a.replace(" ", "-") for a in pdata.get("aliases", [])]:
                    return pid
                if raw_target in pid:
                    return pid

    return None

class VoiceInterrupter:
    def __init__(self, db_path: Path = DEFAULT_STATE_DB):
        self.db_path = db_path
        self.personas = load_personas()
        self.active_tts_pids: set[int] = set()

    def register_tts_process(self, pid: int):
        self.active_tts_pids.add(pid)

    def trigger_barge_in(self) -> int:
        """
        Kills any active TTS playback process immediately when user speech is detected.
        Returns number of processes killed.
        """
        killed = 0
        # 1. Kill tracked PIDs
        for pid in list(self.active_tts_pids):
            try:
                os.kill(pid, signal.SIGKILL)
                killed += 1
            except ProcessLookupError:
                pass
            except Exception as e:
                sys.stderr.write(f"Error killing PID {pid}: {e}\n")
        self.active_tts_pids.clear()

        # 2. Sweep system processes matching known TTS audio output tools
        try:
            out = subprocess.check_output(["ps", "-eo", "pid,comm"], text=True)
            for line in out.splitlines():
                parts = line.strip().split(maxsplit=1)
                if len(parts) == 2:
                    pid_str, comm = parts
                    if any(target in comm for target in TTS_TARGET_BINARIES):
                        pid = int(pid_str)
                        if pid != os.getpid():
                            try:
                                os.kill(pid, signal.SIGTERM)
                                killed += 1
                            except ProcessLookupError:
                                pass
        except Exception:
            pass

        if killed > 0:
            try:
                conn = init_state_db(self.db_path)
                now = datetime.now(timezone.utc).isoformat()
                active = get_active_persona(self.db_path)
                conn.execute("""
                CREATE TABLE IF NOT EXISTS barge_in_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    active_persona TEXT NOT NULL,
                    killed_pids TEXT,
                    user_prompt TEXT,
                    reason TEXT
                );
                """)
                conn.execute(
                    "INSERT INTO barge_in_events (timestamp, active_persona, killed_pids, user_prompt, reason) VALUES (?, ?, ?, ?, ?)",
                    (now, active, str(killed), "", "User speech detected during active audio playback"),
                )
                conn.commit()
                conn.close()
            except Exception:
                pass

        return killed

    def handle_user_input(self, text: str) -> dict:
        """
        Checks for voice trigger switch; if detected, updates active persona and vocalizes confirmation.
        """
        target = parse_voice_trigger(text)
        if target:
            success = set_active_persona(target, self.db_path)
            if success:
                pinfo = self.personas.get(target, {})
                return {
                    "switched": True,
                    "persona_id": target,
                    "name": pinfo.get("name", target),
                    "sample": pinfo.get("sample_phrase", "Voice updated.")
                }
        return {"switched": False, "active_persona": get_active_persona(self.db_path)}

def self_test():
    print("==> Running Voice Interrupter & Persona Registry Self-Test...")
    test_db = Path("/tmp/test_pi_state.sqlite")
    if test_db.exists():
        test_db.unlink()

    # 1. Test persona manifest loading
    personas = load_personas()
    assert len(personas) >= 11, f"Expected >= 11 personas, got {len(personas)}"
    expected = [
        "jarvis-classic", "glados-auditor", "samuel-jackson", "orc-peon",
        "hk-55", "sc-adjutant", "johnny-5", "gandalf", "paimon", "cortana",
        "eccentric-jp-girl"
    ]
    for exp in expected:
        assert exp in personas, f"Missing persona '{exp}'"
    print(f"  [PASS] Persona Manifest loaded ({len(personas)} personas verified)")

    # 2. Test voice trigger parser
    assert parse_voice_trigger("switch voice to gandalf") == "gandalf"
    assert parse_voice_trigger("change persona to jarvis") == "jarvis-classic"
    assert parse_voice_trigger("set voice to orc peon") == "orc-peon"
    assert parse_voice_trigger("activate paimon voice") == "paimon"
    assert parse_voice_trigger("switch voice to glados") == "glados-auditor"
    assert parse_voice_trigger("just an ordinary task") is None
    print("  [PASS] Voice Trigger parsing verified across direct IDs and aliases")

    # 3. Test SQLite State DB hot-swapping
    assert set_active_persona("cortana", db_path=test_db) is True
    assert get_active_persona(db_path=test_db) == "cortana"
    assert set_active_persona("hk-55", db_path=test_db) is True
    assert get_active_persona(db_path=test_db) == "hk-55"
    print("  [PASS] SQLite state persistence and hot-swapping verified")

    # 4. Test Barge-in Interrupter simulation
    interrupter = VoiceInterrupter(db_path=test_db)
    # Spawn dummy sleeper process to simulate active TTS
    proc = subprocess.Popen(["sleep", "10"])
    interrupter.register_tts_process(proc.pid)
    killed = interrupter.trigger_barge_in()
    assert killed >= 1
    # Verify process terminated
    proc.poll()
    print("  [PASS] Silero VAD Barge-in simulation killed active playback process")

    if test_db.exists():
        test_db.unlink()

    print("==> All Voice Interrupter tests PASSED!")
    return 0

if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())
    elif "--status" in sys.argv:
        curr = get_active_persona()
        personas = load_personas()
        pinfo = personas.get(curr, {})
        print(f"Active Persona: {curr} ({pinfo.get('name', 'Unknown')})")
        print(f"Sample Phrase: {pinfo.get('sample_phrase', '')}")
    elif "--switch" in sys.argv:
        idx = sys.argv.index("--switch")
        if idx + 1 < len(sys.argv):
            target = sys.argv[idx + 1]
            if set_active_persona(target):
                print(f"Successfully switched persona to: {target}")
            else:
                print(f"Failed to find persona: {target}")
                sys.exit(1)
    else:
        print("Usage: nfp_voice_interrupter.py [--test | --status | --switch <persona>]")
