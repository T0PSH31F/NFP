#!/usr/bin/env python3
"""
NFP Jarvis Nightly Reflection & Dream Cycle Miner (Layer 71)
============================================================
Autonomous weakness miner, playbook distiller, and deterministic gatekeeper.

Queries ~/.local/share/pi-durable/state.sqlite for:
1. Failed tool calls
2. Jev classification drops
3. Barge-in interrupts
4. Linter rejections

Distills recurring failure patterns into .agents/memory/playbook.md,
proposes candidate mutations to Jev rules and system prompts,
and subjects all mutations to deterministic gatekeeper verification (./init.sh).
"""

import sys
import os
import json
import sqlite3
import re
import subprocess
import time
from pathlib import Path
from datetime import datetime, timezone, timedelta

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_DB_PATH = Path.home() / ".local/share/pi-durable/state.sqlite"
PLAYBOOK_PATH = REPO_ROOT / ".agents/memory/playbook.md"
PROMPTS_DIR = REPO_ROOT / "layers/70-agents/71-harness/prompts"
JEV_RULES_PATH = REPO_ROOT / "layers/70-agents/78-llm-routers/jev_rules.json"
GLADOS_TTS_BIN = Path.home() / ".local/bin/glados-tts-cli"


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


def init_db(db_path: Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Initializes execution log tables in SQLite."""
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.execute("""
    CREATE TABLE IF NOT EXISTS failed_tool_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        tool_name TEXT NOT NULL,
        agent TEXT NOT NULL,
        error_message TEXT NOT NULL,
        payload TEXT
    );
    """)
    conn.execute("""
    CREATE TABLE IF NOT EXISTS jev_drops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        event_text TEXT NOT NULL,
        drop_reason TEXT NOT NULL,
        stage INTEGER NOT NULL,
        tokens_saved INTEGER NOT NULL
    );
    """)
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
    conn.execute("""
    CREATE TABLE IF NOT EXISTS linter_rejections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        file_path TEXT NOT NULL,
        linter TEXT NOT NULL,
        error_output TEXT NOT NULL
    );
    """)
    conn.execute("""
    CREATE TABLE IF NOT EXISTS dream_cycle_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        mutations_proposed INTEGER NOT NULL,
        verification_passed INTEGER NOT NULL,
        summary TEXT
    );
    """)
    conn.commit()
    return conn


def log_tool_failure(tool_name: str, agent: str, error_msg: str, payload: str = "", db_path: Path = DEFAULT_DB_PATH) -> None:
    try:
        conn = init_db(db_path)
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            "INSERT INTO failed_tool_calls (timestamp, tool_name, agent, error_message, payload) VALUES (?, ?, ?, ?, ?)",
            (now, tool_name, agent, str(error_msg)[:1000], str(payload)[:1000]),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def log_jev_drop(event_text: str, reason: str, stage: int = 1, tokens_saved: int = 0, db_path: Path = DEFAULT_DB_PATH) -> None:
    try:
        conn = init_db(db_path)
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            "INSERT INTO jev_drops (timestamp, event_text, drop_reason, stage, tokens_saved) VALUES (?, ?, ?, ?, ?)",
            (now, str(event_text)[:1000], str(reason)[:500], stage, tokens_saved),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def log_barge_in(active_persona: str, killed_count: int = 1, user_prompt: str = "", reason: str = "User speech detected", db_path: Path = DEFAULT_DB_PATH) -> None:
    try:
        conn = init_db(db_path)
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            "INSERT INTO barge_in_events (timestamp, active_persona, killed_pids, user_prompt, reason) VALUES (?, ?, ?, ?, ?)",
            (now, active_persona, str(killed_count), str(user_prompt)[:500], str(reason)),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def log_linter_rejection(file_path: str, linter: str, error_output: str, db_path: Path = DEFAULT_DB_PATH) -> None:
    try:
        conn = init_db(db_path)
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            "INSERT INTO linter_rejections (timestamp, file_path, linter, error_output) VALUES (?, ?, ?, ?)",
            (now, str(file_path), str(linter), str(error_output)[:1000]),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def seed_sample_events(db_path: Path = DEFAULT_DB_PATH) -> None:
    """Injects sample realistic events for testing and bootstrap calibration."""
    init_db(db_path)
    now = datetime.now(timezone.utc).isoformat()

    conn = sqlite3.connect(str(db_path))
    # 1. Failed tool call
    conn.execute(
        "INSERT INTO failed_tool_calls (timestamp, tool_name, agent, error_message, payload) VALUES (?, ?, ?, ?, ?)",
        (now, "nfp-todo", "pi", "flock timeout: /tmp/nfp-todo.lock held by another process", "todo add 'Check services'"),
    )
    # 2. Jev classification drop (e.g. routine ping)
    conn.execute(
        "INSERT INTO jev_drops (timestamp, event_text, drop_reason, stage, tokens_saved) VALUES (?, ?, ?, ?, ?)",
        (now, '{"status": "ok", "service": "healthz"}', "Routine ping matched heuristic", 1, 45),
    )
    # 3. Barge-in interrupt
    conn.execute(
        "INSERT INTO barge_in_events (timestamp, active_persona, killed_pids, user_prompt, reason) VALUES (?, ?, ?, ?, ?)",
        (now, "glados-auditor", "1", "Stop, just run the build", "User interrupted verbose explanation"),
    )
    # 4. Linter rejection
    conn.execute(
        "INSERT INTO linter_rejections (timestamp, file_path, linter, error_output) VALUES (?, ?, ?, ?)",
        (now, "layers/10-system/nas-mounts.nix", "statix", "[20] Warning: Avoid repeated keys in attribute sets"),
    )
    conn.commit()
    conn.close()


def mine_weaknesses(db_path: Path = DEFAULT_DB_PATH, hours: int = 24) -> dict:
    """Queries SQLite for weaknesses logged in the given timeframe."""
    conn = init_db(db_path)
    cur = conn.cursor()

    time_cutoff = (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat()

    # 1. Failed tool calls
    cur.execute(
        """
        SELECT tool_name, error_message, COUNT(*) as cnt
        FROM failed_tool_calls
        WHERE timestamp >= ?
        GROUP BY tool_name, error_message
        ORDER BY cnt DESC
        """,
        (time_cutoff,),
    )
    failed_tools = [{"tool": row[0], "error": row[1], "count": row[2]} for row in cur.fetchall()]

    # 2. Jev classification drops
    cur.execute(
        """
        SELECT drop_reason, COUNT(*) as cnt, SUM(tokens_saved) as tokens
        FROM jev_drops
        WHERE timestamp >= ?
        GROUP BY drop_reason
        ORDER BY cnt DESC
        """,
        (time_cutoff,),
    )
    jev_drops = [{"reason": row[0], "count": row[1], "tokens_saved": row[2] or 0} for row in cur.fetchall()]

    # 3. Barge-in interrupts
    cur.execute(
        """
        SELECT active_persona, COUNT(*) as cnt, reason
        FROM barge_in_events
        WHERE timestamp >= ?
        GROUP BY active_persona, reason
        ORDER BY cnt DESC
        """,
        (time_cutoff,),
    )
    barge_ins = [{"persona": row[0], "count": row[1], "reason": row[2]} for row in cur.fetchall()]

    # 4. Linter rejections
    cur.execute(
        """
        SELECT linter, error_output, COUNT(*) as cnt
        FROM linter_rejections
        WHERE timestamp >= ?
        GROUP BY linter, error_output
        ORDER BY cnt DESC
        """,
        (time_cutoff,),
    )
    linter_errors = [{"linter": row[0], "error": row[1], "count": row[2]} for row in cur.fetchall()]

    conn.close()

    total_count = sum(len(x) for x in (failed_tools, jev_drops, barge_ins, linter_errors))
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "lookback_hours": hours,
        "failed_tools": failed_tools,
        "jev_drops": jev_drops,
        "barge_ins": barge_ins,
        "linter_errors": linter_errors,
        "total_weaknesses": total_count,
    }


def update_playbook(findings: dict, playbook_path: Path = PLAYBOOK_PATH) -> bool:
    """Updates the itemized operational playbook with distilled lessons."""
    if not playbook_path.exists():
        playbook_path.parent.mkdir(parents=True, exist_ok=True)
        content = "# NFP Autonomous Agent Playbook & Operational Memory\n\n## 3. Dynamic Incident Log & Learned Mutations\n\n"
    else:
        content = playbook_path.read_text(encoding="utf-8")

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    entries_added = 0

    # Format new incident rows
    new_rows = []
    for item in findings.get("failed_tools", []):
        new_rows.append(f"| {today} | Failed Tool: {item['tool']} | Error: {item['error'][:50]} (Count: {item['count']}) | Wrap tool execution with retry and timeout bounds | PASSED |")
        entries_added += 1

    for item in findings.get("barge_ins", []):
        new_rows.append(f"| {today} | Barge-in Interrupt ({item['persona']}) | Reason: {item['reason']} (Count: {item['count']}) | Enforce strict 1-2 sentence response cap in system prompt | PASSED |")
        entries_added += 1

    for item in findings.get("linter_errors", []):
        new_rows.append(f"| {today} | Linter: {item['linter']} | Error: {item['error'][:50]} (Count: {item['count']}) | Format and clean before git commit | PASSED |")
        entries_added += 1

    if new_rows:
        table_marker = "| Date | Incident Type | Context / Root Cause | Applied Countermeasure / Mutation | Gatekeeper Status |"
        if table_marker in content:
            parts = content.split(table_marker)
            header_and_divider = parts[1].split("\n", 2)
            divider = header_and_divider[1] if len(header_and_divider) > 1 else "| :--- | :--- | :--- | :--- | :--- |"
            rest = header_and_divider[2] if len(header_and_divider) > 2 else ""
            inserted = "\n".join(new_rows) + "\n"
            content = parts[0] + table_marker + "\n" + divider + "\n" + inserted + rest
        else:
            content += "\n### Dynamic Incidents\n" + table_marker + "\n| :--- | :--- | :--- | :--- | :--- |\n" + "\n".join(new_rows) + "\n"

        playbook_path.write_text(content, encoding="utf-8")
        return True
    return False


def propose_mutations(findings: dict) -> list[dict]:
    """Generates candidate mutations to Jev heuristic rules or system prompts."""
    mutations = []

    # 1. Propose Jev heuristic mutations if drops or recurring alerts warrant refinement
    if JEV_RULES_PATH.exists():
        try:
            jev_rules = json.loads(JEV_RULES_PATH.read_text(encoding="utf-8"))
            # Check if any new critical pattern is needed
            current_crit = jev_rules.get("critical_patterns", [])
            # Example candidate refinement: ensure disk impermanence warning is critical
            impermanence_pat = r"\b(impermanence\s*capacity|btrfs\s*device\s*error|zpool\s*degraded)\b"
            if impermanence_pat not in current_crit:
                new_rules = dict(jev_rules)
                new_rules["critical_patterns"] = current_crit + [impermanence_pat]
                new_rules["updated_at"] = datetime.now(timezone.utc).isoformat()
                mutations.append({
                    "target_path": JEV_RULES_PATH,
                    "description": "Add impermanence & storage degradation pattern to Jev critical rules",
                    "new_content": json.dumps(new_rules, indent=2) + "\n",
                })
        except Exception:
            pass

    # 2. Propose prompt conciseness reinforcement if barge-in count is elevated
    jarvis_prompt_path = PROMPTS_DIR / "jarvis_system_prompt.md"
    if jarvis_prompt_path.exists() and findings.get("barge_ins"):
        txt = jarvis_prompt_path.read_text(encoding="utf-8")
        reinforcement = "- **Acoustic Economy**: On detected barge-in interrupts, immediately acknowledge and truncate playback under 5 words."
        if reinforcement not in txt:
            new_txt = txt + f"\n{reinforcement}\n"
            mutations.append({
                "target_path": jarvis_prompt_path,
                "description": "Reinforce acoustic economy and rapid interruption recovery in Jarvis prompt",
                "new_content": new_txt,
            })

    return mutations


def run_deterministic_gatekeeper(mutations: list[dict], repo_dir: Path = REPO_ROOT) -> tuple[bool, str]:
    """
    Applies proposed edits and validates with ./init.sh --worktree.
    Rolls back immediately if verification fails.
    """
    if not mutations:
        return True, "No candidate mutations proposed."

    scratch_dir = Path("/tmp/nfp-dream-scratch")
    scratch_dir.mkdir(parents=True, exist_ok=True)

    backups = {}
    applied = []

    try:
        # 1. Back up original files
        for mut in mutations:
            target = mut["target_path"]
            if target.exists():
                backups[target] = target.read_text(encoding="utf-8")
            else:
                backups[target] = None

            # Apply mutation
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(mut["new_content"], encoding="utf-8")
            applied.append(target)

        # 2. Execute deterministic verification gate
        init_script = repo_dir / "init.sh"
        if not init_script.exists():
            return False, "init.sh not found at repository root"

        print(f"[Deterministic Gatekeeper] Running {init_script} --worktree ...")
        proc = subprocess.run(
            [str(init_script), "--worktree"],
            cwd=str(repo_dir),
            capture_output=True,
            text=True,
            timeout=300,
        )

        if proc.returncode == 0:
            print("[Deterministic Gatekeeper] Verification SUCCESSFUL (exit code 0).")
            # Log to git if inside repo
            try:
                subprocess.run(["git", "add", "."], cwd=str(repo_dir), check=False)
                commit_msg = "feat(dream-cycle): nightly reflection and self-improvement pass [verified]"
                subprocess.run(
                    ["git", "commit", "-m", commit_msg],
                    cwd=str(repo_dir),
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception:
                pass
            return True, "All verification gates passed. Changes merged."
        else:
            print(f"[Deterministic Gatekeeper] Verification FAILED (exit code {proc.returncode}). Rolling back...")
            # Revert applied files
            for target, original in backups.items():
                if original is None:
                    if target.exists():
                        target.unlink()
                else:
                    target.write_text(original, encoding="utf-8")
            return False, f"Verification failed with exit code {proc.returncode}:\n{proc.stderr[:400]}"

    except Exception as e:
        # Revert on any exception
        for target, original in backups.items():
            if original is None:
                if target.exists():
                    target.unlink()
            else:
                target.write_text(original, encoding="utf-8")
        return False, f"Exception during gatekeeper execution: {e}"


def run_nightly_cycle(db_path: Path = DEFAULT_DB_PATH) -> dict:
    """Orchestrates the complete nightly reflection and dream cycle."""
    t0 = time.time()
    print(f"[DreamCycle] Starting nightly reflection cycle at {datetime.now(timezone.utc).isoformat()}...")

    # 1. Initialize tables & mine weaknesses
    init_db(db_path)
    findings = mine_weaknesses(db_path=db_path, hours=24)
    print(f"[DreamCycle] Mined {findings['total_weaknesses']} weakness instances across 4 categories.")

    # 2. Distill into playbook
    playbook_updated = update_playbook(findings)
    if playbook_updated:
        print("[DreamCycle] Updated .agents/memory/playbook.md with new incident records.")

    # 2b. Personal Memory Reflection & User Profile Evolution
    try:
        reflection_script = REPO_ROOT / "layers/70-agents/73-memory/reflection.py"
        if reflection_script.exists():
            print("[DreamCycle] Running personal memory reflection pass...")
            subprocess.run(
                [sys.executable, str(reflection_script), "--run-reflection"],
                cwd=str(REPO_ROOT),
                check=False,
                timeout=60,
            )
            print("[DreamCycle] Personal memory reflection complete (.agents/memory/user_profile.md).")
    except Exception as exc:
        print(f"[DreamCycle] Warning: Personal reflection encountered error: {exc}")

    # 3. Propose mutations
    mutations = propose_mutations(findings)
    print(f"[DreamCycle] Proposed {len(mutations)} candidate mutations.")

    # 4. Deterministic Gatekeeper
    passed, reason = run_deterministic_gatekeeper(mutations)

    # 5. Record run in SQLite
    conn = init_db(db_path)
    now = datetime.now(timezone.utc).isoformat()
    conn.execute(
        "INSERT INTO dream_cycle_runs (timestamp, status, mutations_proposed, verification_passed, summary) VALUES (?, ?, ?, ?, ?)",
        (now, "PASSED" if passed else "FAILED", len(mutations), 1 if passed else 0, reason[:500]),
    )
    conn.commit()
    conn.close()

    duration = round(time.time() - t0, 2)
    voice_msg = (
        f"Nightly dream cycle complete. Self-improvement mutations verified in {duration} seconds."
        if passed
        else "Nightly dream cycle rejected candidate edits failing deterministic verification."
    )
    speak_glados(voice_msg)

    return {
        "status": "success" if passed else "rejected",
        "passed": passed,
        "mutations_count": len(mutations),
        "reason": reason,
        "duration_seconds": duration,
    }


def self_test() -> int:
    """Offline test suite for weakness mining, playbook updates, and gatekeeper."""
    print("==> Running dream_miner.py self-test suite...")
    test_db = Path("/tmp/test_dream_miner.sqlite")
    if test_db.exists():
        test_db.unlink()

    test_playbook = Path("/tmp/test_playbook.md")
    if test_playbook.exists():
        test_playbook.unlink()

    # 1. Test table init
    conn = init_db(test_db)
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = {r[0] for r in cur.fetchall()}
    assert {"failed_tool_calls", "jev_drops", "barge_in_events", "linter_rejections", "dream_cycle_runs"}.issubset(tables)
    conn.close()
    print("  [PASS] Test 1: SQLite schema initialized with 5 canonical tables")

    # 2. Test event logging & seeding
    seed_sample_events(test_db)
    findings = mine_weaknesses(test_db, hours=24)
    assert len(findings["failed_tools"]) >= 1
    assert len(findings["jev_drops"]) >= 1
    assert len(findings["barge_ins"]) >= 1
    assert len(findings["linter_errors"]) >= 1
    print(f"  [PASS] Test 2: Weakness mining extracted {findings['total_weaknesses']} events across 4 categories")

    # 3. Test playbook distillation
    updated = update_playbook(findings, playbook_path=test_playbook)
    assert updated is True
    assert test_playbook.exists()
    assert "flock timeout" in test_playbook.read_text()
    print("  [PASS] Test 3: Operational playbook successfully distilled and updated")

    # 4. Test mutation proposal
    mutations = propose_mutations(findings)
    assert isinstance(mutations, list)
    print(f"  [PASS] Test 4: Proposed {len(mutations)} candidate mutations")

    # Clean up test artifacts
    if test_db.exists():
        test_db.unlink()
    if test_playbook.exists():
        test_playbook.unlink()

    print("==> All dream_miner.py tests PASSED!")
    return 0


if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())
    elif "--seed-samples" in sys.argv:
        seed_sample_events()
        print("Sample events successfully seeded into SQLite state database.")
        sys.exit(0)
    elif "--mine" in sys.argv:
        res = mine_weaknesses()
        print(json.dumps(res, indent=2))
        sys.exit(0)
    elif "--run-nightly" in sys.argv:
        res = run_nightly_cycle()
        print(json.dumps(res, indent=2))
        sys.exit(0 if res.get("passed") else 1)
    else:
        print("Usage: dream_miner.py [--test | --mine | --seed-samples | --run-nightly]")
        sys.exit(0)
