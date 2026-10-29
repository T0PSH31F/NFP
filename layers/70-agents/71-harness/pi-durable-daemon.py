#!/usr/bin/env python3
"""
Pi & Hermes Durable 24/7 Autonomous Task Decomposition & Worker Daemon (NFP Layer 71)
=====================================================================================
Provides:
1. Durable session management backed by /persist/var/lib/pi-agent/sessions
2. HTTP A2A Worker API on 127.0.0.1:8089 (/healthz, /v1/delegate, /v1/decompose)
3. Token-Optimized Kong + Jev Tier Routing:
   - Tier 1 (`jev/free-first` / `kong/Free`): Used for task decomposition, triage, and status summaries
   - Tier 2 (`jev/cascade-balanced` / `kong/Coding`): Used for executing `[SAFE-AUTO]` code/config preparation & tests using free + subscription quota models
   - Tier 3 (`jev/frontier` / `kong/Judge`): Reserved for complex escalations or explicit frontier requests
4. Autonomous Shared Todo Watcher (`~/Notes/EverOS/todo.md`) for both `## Pi` and `## Hermes`:
   - Auto-claims `@pi` tasks from `## Erik` into `## Pi`, and `@hermes` tasks into `## Hermes`
   - Breaks open tasks down into actionable `[SAFE-AUTO]` vs `[APPROVAL-GATE]` steps
   - Completes 100% of `[SAFE-AUTO]` research, preparation, refinement, and dry-run verification immediately
   - Pauses cleanly before any `[APPROVAL-GATE]` (`clan machines update`, `git push`, secret mutation, destructive ops)
   - Writes a structured Markdown report to `~/Notes/EverOS/reports/<YYYY-MM-DD>-<agent>-<slug>.md` and links it in `todo.md`
5. Mandatory GLaDOS voice notifications via `glados-tts-cli`
"""

import asyncio
import json
import os
import re
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Set

LISTEN_HOST = os.environ.get("PI_DAEMON_HOST", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("PI_DAEMON_PORT", "8089"))
PI_BIN = os.environ.get("PI_BIN", "/run/current-system/sw/bin/pi")
SESSION_DIR = Path(os.environ.get("PI_SESSION_DIR", "/persist/var/lib/pi-agent/sessions"))
STATE_DIR = Path(os.environ.get("PI_STATE_DIR", "/persist/var/lib/pi-agent"))
DEFAULT_PROVIDER = os.environ.get("PI_PROVIDER", "jev")
FREE_MODEL = os.environ.get("PI_FREE_MODEL", "free-first")
BALANCED_MODEL = os.environ.get("PI_DEFAULT_MODEL", "cascade-balanced")
FRONTIER_MODEL = os.environ.get("PI_FRONTIER_MODEL", "frontier")
NFP_TODO_BIN = os.environ.get("NFP_TODO_BIN", "/home/t0psh31f/.local/bin/nfp-todo")
GLADOS_TTS_BIN = os.environ.get("GLADOS_TTS_BIN", "/home/t0psh31f/.local/bin/glados-tts-cli")
POLL_INTERVAL_SECONDS = int(os.environ.get("PI_TODO_POLL_SECONDS", "45"))

START_TIME = time.time()
LAST_POLL_TS: float = 0.0
TASKS_COMPLETED: int = 0
REPORTS_WRITTEN: int = 0
ACTIVE_JOBS: int = 0
PROCESSED_TASKS: Set[str] = set()


def speak_glados(text: str) -> None:
    """Mandatory GLaDOS voice notification (non-blocking background execution)."""
    clean = re.sub(r"\s+", " ", text).strip()
    if not clean:
        return
    for candidate in [GLADOS_TTS_BIN, "/run/current-system/sw/bin/glados-speak"]:
        if os.path.exists(candidate) and os.access(candidate, os.X_OK):
            try:
                subprocess.Popen(
                    [candidate, clean],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                return
            except Exception:
                pass


def ensure_dirs() -> None:
    for d in [STATE_DIR, SESSION_DIR, Path.home() / "Notes" / "EverOS" / "reports"]:
        try:
            d.mkdir(parents=True, exist_ok=True)
        except Exception:
            fallback = Path.home() / ".pi" / "agent" / "sessions"
            fallback.mkdir(parents=True, exist_ok=True)


def get_session_dir() -> Path:
    if SESSION_DIR.exists() and os.access(SESSION_DIR, os.W_OK):
        return SESSION_DIR
    fallback = Path.home() / ".pi" / "agent" / "sessions"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback


def get_todo_cmd() -> List[str]:
    if os.path.exists(NFP_TODO_BIN) and os.access(NFP_TODO_BIN, os.X_OK):
        return [NFP_TODO_BIN]
    todo_script = Path("/home/t0psh31f/Clan/NFP/layers/70-agents/75-mcp/nfp-todo-mcp.py")
    return [sys.executable, str(todo_script)]


async def run_pi_task(
    task: str,
    provider: str = DEFAULT_PROVIDER,
    model: str = BALANCED_MODEL,
    session_id: str = "hermes-a2a",
    notify_voice: bool = True,
    timeout: float = 240.0,
) -> Dict[str, Any]:
    global TASKS_COMPLETED, ACTIVE_JOBS
    ACTIVE_JOBS += 1
    t0 = time.monotonic()
    sdir = get_session_dir()

    system_rules = (
        "MANDATORY NFP AGENT DIRECTIVES:\n"
        "1. VOICE NOTIFICATIONS: Trigger `/home/t0psh31f/.local/bin/glados-tts-cli \"<short status>\" >/dev/null 2>&1 &` on completion.\n"
        "2. APPROVAL GATES: NEVER execute `clan machines update`, `nixos-rebuild`, `git push`, secret deletion, or destructive commands without Erik's approval. "
        "Instead, complete 100% of the preparation, file edits, dry-run checks, and verification steps leading up to the approval gate.\n"
        "3. TOKEN EFFICIENCY: Keep responses concise, read targeted line ranges instead of whole files, and prefer deterministic checks."
    )

    cmd = [
        PI_BIN,
        "--print",
        "--session-dir",
        str(sdir),
        "--session-id",
        session_id,
        "--provider",
        provider,
        "--model",
        model,
        "--append-system-prompt",
        system_rules,
        task,
    ]

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        try:
            stdout_b, stderr_b = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except asyncio.TimeoutError:
            proc.kill()
            return {
                "status": "timeout",
                "session_id": session_id,
                "model": f"{provider}/{model}",
                "elapsed_ms": round((time.monotonic() - t0) * 1000.0, 1),
            }

        elapsed_ms = round((time.monotonic() - t0) * 1000.0, 1)
        out = stdout_b.decode("utf-8", errors="replace").strip()
        err = stderr_b.decode("utf-8", errors="replace").strip()
        ok = proc.returncode == 0
        if ok:
            TASKS_COMPLETED += 1
            if notify_voice:
                speak_glados("Pi durable worker has completed your delegated task and logged its findings.")
        else:
            try:
                db_p = Path.home() / ".local/share/pi-durable/state.sqlite"
                db_p.parent.mkdir(parents=True, exist_ok=True)
                import sqlite3
                conn = sqlite3.connect(str(db_p))
                now_str = datetime.now(timezone.utc).isoformat()
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
                conn.execute(
                    "INSERT INTO failed_tool_calls (timestamp, tool_name, agent, error_message, payload) VALUES (?, ?, ?, ?, ?)",
                    (now_str, "pi-task", "pi", f"Process exited with code {proc.returncode}: {err[:400]}", task[:400]),
                )
                conn.commit()
                conn.close()
            except Exception:
                pass
        return {
            "status": "completed" if ok else "error",
            "returncode": proc.returncode,
            "session_id": session_id,
            "model": f"{provider}/{model}",
            "elapsed_ms": elapsed_ms,
            "output": out,
            "stderr": err[:500] if err else "",
        }
    except Exception as exc:
        return {"status": "error", "error": str(exc), "session_id": session_id}
    finally:
        ACTIVE_JOBS = max(0, ACTIVE_JOBS - 1)


def build_a2ui_card(agent_slug: str, task_text: str, gate_status: str, diff_text: str | None = None) -> Dict[str, Any]:
    """Generates an A2UI Action Card compliant with a2ui_action_card_schema.json."""
    card_id = f"card-{uuid.uuid4().hex[:12]}"
    now_iso = datetime.now(timezone.utc).isoformat()
    is_gate = (gate_status == "awaiting_approval")
    risk = "high" if ("rm " in task_text or "destructive" in task_text or "nix-collect" in task_text) else ("medium" if is_gate else "low")
    
    actions = [
        {
            "id": "act-dismiss",
            "label": "Dismiss",
            "style": "outline",
            "action_type": "dismiss",
            "payload": {"card_id": card_id}
        }
    ]
    if is_gate:
        actions.insert(0, {
            "id": "act-approve",
            "label": "Approve Step",
            "style": "primary",
            "action_type": "approve",
            "payload": {"card_id": card_id, "task": task_text}
        })
        actions.insert(1, {
            "id": "act-reject",
            "label": "Reject / Halt",
            "style": "danger",
            "action_type": "reject",
            "payload": {"card_id": card_id, "task": task_text}
        })

    diff_preview = None
    if diff_text:
        diff_preview = {
            "file_path": "workspace",
            "old_content": "",
            "new_content": "",
            "unified_diff": diff_text
        }

    return {
        "card_id": card_id,
        "timestamp": now_iso,
        "source_agent": f"pi-{agent_slug}",
        "target_persona": "glados-auditor",
        "title": f"[{agent_slug.upper()}] {'Action Required' if is_gate else 'Task Completed'}",
        "summary": task_text[:160],
        "risk_level": risk,
        "verdict": "DISPATCH_AGENT" if is_gate else "NOTIFY",
        "actionability": is_gate,
        "diff_preview": diff_preview,
        "actions": actions,
        "ttl_rule": {
            "timeout_seconds": 600,
            "default_action_id": "act-dismiss",
            "on_expire": "auto_dismiss"
        }
    }


async def decompose_and_advance_task(agent_slug: str, task_text: str) -> Dict[str, Any]:
    """
    1. Uses Free Tier (`jev/free-first`) to break the task into actionable `[SAFE-AUTO]` vs `[APPROVAL-GATE]` steps.
    2. Uses Balanced/Subscription Quota Tier (`jev/cascade-balanced`) to execute all `[SAFE-AUTO]` preparation/refinement steps.
    3. Writes a structured Markdown report in `~/Notes/EverOS/reports/` and links it in `~/Notes/EverOS/todo.md`.
    """
    global REPORTS_WRITTEN
    clean_task = re.sub(r"\s*\(\[Report\]\([^)]+\)\)", "", task_text).strip()
    clean_task = re.sub(r"\s*\[⏳ AWAITING-APPROVAL\]", "", clean_task).strip()

    prompt = (
        f"You are acting as the NFP `{agent_slug.upper()}` autonomous agent working on task:\n"
        f"\"{clean_task}\"\n\n"
        "Perform the following 3 phases in a single pass with strict token discipline:\n"
        "PHASE 1 (Actionable Decomposition):\n"
        "- Break this task into 3 to 5 concrete sub-steps, labeling each step `[SAFE-AUTO]` or `[APPROVAL-GATE]`.\n"
        "PHASE 2 (Maximum Safe Execution):\n"
        "- Execute ALL `[SAFE-AUTO]` steps right now (inspect relevant files, verify configs, prepare/refine any code or commands, run non-destructive checks).\n"
        "- Do NOT execute `[APPROVAL-GATE]` actions (`clan machines update`, `git push`, deleting files, mutating live production secrets).\n"
        "PHASE 3 (Structured Report Output):\n"
        "- Output a concise Markdown report with sections:\n"
        "  ## 1. Actionable Step Breakdown\n"
        "  ## 2. Work Completed & Verification Evidence\n"
        "  ## 3. Approval-Gate Readiness (Exact commands/decisions prepared for Erik)\n"
        "- On the very last line of your output, write either `GATE_STATUS: COMPLETED` (if no approval gate remains) "
        "or `GATE_STATUS: AWAITING_APPROVAL` (if paused at an Erik approval gate)."
    )

    # Choose free-first for pure research/planning tasks, cascade-balanced (subscription quota + free cascade) for code/tool tasks
    needs_code_tools = bool(re.search(r"\b(fix|implement|refactor|config|nix|module|build|test|keybind|router)\b", clean_task, re.I))
    chosen_model = BALANCED_MODEL if needs_code_tools else FREE_MODEL

    res = await run_pi_task(
        task=prompt,
        provider=DEFAULT_PROVIDER,
        model=chosen_model,
        session_id=f"{agent_slug}-todo-worker",
        notify_voice=False,
        timeout=240.0,
    )

    output_md = res.get("output") or f"Task execution status: {res.get('status')}\n\nStderr: {res.get('stderr', '')}"
    gate_status = "completed"
    if "GATE_STATUS: AWAITING_APPROVAL" in output_md or re.search(r"\[APPROVAL-GATE\]", output_md):
        if "GATE_STATUS: COMPLETED" not in output_md:
            gate_status = "awaiting_approval"

    report_body = (
        f"**Task:** {clean_task}\n"
        f"**Model / Tier Used:** `{res.get('model', chosen_model)}` (`{res.get('elapsed_ms', 0)} ms`)\n\n"
        f"{output_md}\n"
    )

    todo_cmd = get_todo_cmd()
    proc = await asyncio.create_subprocess_exec(
        *todo_cmd,
        "--agent",
        agent_slug,
        "report",
        "--query",
        clean_task[:45],
        "--title",
        clean_task[:60],
        "--status",
        gate_status,
        "--body",
        report_body,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout_b, _ = await proc.communicate()
    REPORTS_WRITTEN += 1

    if gate_status == "awaiting_approval":
        speak_glados(
            f"{agent_slug.capitalize()} has decomposed your task, completed all preparatory steps, and written a report awaiting your approval."
        )
    else:
        speak_glados(
            f"{agent_slug.capitalize()} has completed your task and filed the verification report."
        )

    card = build_a2ui_card(agent_slug, clean_task, gate_status)
    try:
        ret = json.loads(stdout_b.decode("utf-8", errors="replace"))
        ret["a2ui_card"] = card
        return ret
    except Exception:
        return {"status": "ok", "gate_status": gate_status, "a2ui_card": card}


async def poll_shared_todo_loop() -> None:
    """Continuously watches ~/Notes/EverOS/todo.md for @pi / @hermes tasks and advances open tasks."""
    global LAST_POLL_TS
    while True:
        try:
            LAST_POLL_TS = time.time()
            cmd_base = get_todo_cmd()
            proc = await asyncio.create_subprocess_exec(
                *cmd_base,
                "list",
                "--json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout_b, _ = await proc.communicate()
            if proc.returncode == 0 and stdout_b:
                data = json.loads(stdout_b.decode("utf-8", errors="replace"))
                sections = data.get("sections", {})

                # 1. Auto-claim @pi and @hermes tasks from ## Erik
                for item in sections.get("erik", []):
                    txt = item.get("text", "")
                    if item.get("done"):
                        continue
                    for target_agent in ("pi", "hermes"):
                        if re.search(rf"(?:^|\s)@{target_agent}\b", txt, re.I):
                            claim_proc = await asyncio.create_subprocess_exec(
                                *cmd_base,
                                "--agent",
                                target_agent,
                                "claim",
                                txt[:45],
                                stdout=asyncio.subprocess.PIPE,
                                stderr=asyncio.subprocess.PIPE,
                            )
                            await claim_proc.communicate()
                            speak_glados(f"{target_agent.capitalize()} claimed task from your list and is decomposing it into actionable steps.")

                # 2. Decompose & advance any open task in ## Pi or ## Hermes that does not yet have a ([Report](...))
                for agent_slug in ("pi", "hermes"):
                    for item in sections.get(agent_slug, []):
                        txt = item.get("text", "")
                        status_ch = item.get("status", " ")
                        # Skip already completed ('x'), paused at approval gate ('>'), or already reported tasks
                        if status_ch in ("x", "X", ">") or "([Report](" in txt or "[⏳ AWAITING-APPROVAL]" in txt:
                            continue
                        # Skip default placeholder seed lines unless explicitly tagged #auto/@auto/@pi/@hermes
                        is_seed_placeholder = any(
                            seed in txt
                            for seed in (
                                "Monitor Kong gateway & Jev router health",
                                "Maintain ~/.pi/agent/models.json sync",
                            )
                        )
                        if is_seed_placeholder and not re.search(r"(?:^|\s)[#@]auto\b", txt, re.I):
                            continue

                        task_key = f"{agent_slug}:{txt}"
                        if task_key in PROCESSED_TASKS:
                            continue
                        PROCESSED_TASKS.add(task_key)
                        await decompose_and_advance_task(agent_slug, txt)
        except Exception:
            pass
        await asyncio.sleep(POLL_INTERVAL_SECONDS)


async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    try:
        req_line = await asyncio.wait_for(reader.readline(), timeout=10.0)
        if not req_line:
            writer.close()
            return
        parts = req_line.decode("utf-8", errors="replace").strip().split(" ")
        method = parts[0] if parts else "GET"
        path = parts[1] if len(parts) > 1 else "/"

        content_length = 0
        while True:
            hline = await reader.readline()
            if not hline or hline in (b"\r\n", b"\n"):
                break
            h_str = hline.decode("utf-8", errors="replace").strip()
            if h_str.lower().startswith("content-length:"):
                content_length = int(h_str.split(":", 1)[1].strip())

        body_bytes = await reader.readexactly(content_length) if content_length > 0 else b""

        if method == "GET" and path in ("/healthz", "/health", "/status"):
            sdir = get_session_dir()
            sessions = [p.name for p in sdir.glob("*") if p.is_file() or p.is_dir()] if sdir.exists() else []
            payload = {
                "status": "ok",
                "service": "pi-durable-daemon",
                "provider": DEFAULT_PROVIDER,
                "tiers": {
                    "free": FREE_MODEL,
                    "balanced_quota": BALANCED_MODEL,
                    "frontier": FRONTIER_MODEL,
                },
                "session_dir": str(sdir),
                "session_count": len(sessions),
                "active_jobs": ACTIVE_JOBS,
                "tasks_completed": TASKS_COMPLETED,
                "reports_written": REPORTS_WRITTEN,
                "last_todo_poll_ts": LAST_POLL_TS,
                "uptime_seconds": round(time.time() - START_TIME, 1),
            }
            resp_b = json.dumps(payload).encode("utf-8")
            writer.write(
                b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                + f"Content-Length: {len(resp_b)}\r\n\r\n".encode("ascii")
                + resp_b
            )
            await writer.drain()
            writer.close()
            return

        if method == "POST" and path in ("/v1/delegate", "/delegate"):
            req_data = json.loads(body_bytes.decode("utf-8")) if body_bytes else {}
            task = str(req_data.get("task", "")).strip()
            if not task:
                err_b = json.dumps({"error": "missing task"}).encode("utf-8")
                writer.write(
                    b"HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n"
                    + f"Content-Length: {len(err_b)}\r\n\r\n".encode("ascii")
                    + err_b
                )
                await writer.drain()
                writer.close()
                return

            res = await run_pi_task(
                task=task,
                provider=str(req_data.get("provider", DEFAULT_PROVIDER)),
                model=str(req_data.get("model", BALANCED_MODEL)),
                session_id=str(req_data.get("session_id", "hermes-a2a")),
                notify_voice=bool(req_data.get("notify_voice", True)),
            )
            resp_b = json.dumps(res).encode("utf-8")
            writer.write(
                b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                + f"Content-Length: {len(resp_b)}\r\n\r\n".encode("ascii")
                + resp_b
            )
            await writer.drain()
            writer.close()
            return

        if method == "POST" and path in ("/v1/decompose", "/decompose"):
            req_data = json.loads(body_bytes.decode("utf-8")) if body_bytes else {}
            task = str(req_data.get("task", "")).strip()
            agent_slug = str(req_data.get("agent", "pi")).strip().lower()
            res = await decompose_and_advance_task(agent_slug, task)
            resp_b = json.dumps(res).encode("utf-8")
            writer.write(
                b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                + f"Content-Length: {len(resp_b)}\r\n\r\n".encode("ascii")
                + resp_b
            )
            await writer.drain()
            writer.close()
            return

        not_found = b'{"error":"not_found"}'
        writer.write(
            b"HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n"
            + f"Content-Length: {len(not_found)}\r\n\r\n".encode("ascii")
            + not_found
        )
        await writer.drain()
        writer.close()
    except Exception:
        try:
            writer.close()
        except Exception:
            pass


async def main_async() -> None:
    ensure_dirs()
    asyncio.create_task(poll_shared_todo_loop())
    server = await asyncio.start_server(handle_client, LISTEN_HOST, LISTEN_PORT)
    print(f"[pi-durable-daemon] Listening on http://{LISTEN_HOST}:{LISTEN_PORT} (sessions={get_session_dir()})", flush=True)
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main_async())
