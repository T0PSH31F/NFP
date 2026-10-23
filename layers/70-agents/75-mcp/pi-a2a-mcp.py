#!/usr/bin/env python3
"""
Hermes <-> Pi Durable Worker A2A MCP Bridge (stdio JSON-RPC 2.0)
Routes delegated tasks from Hermes (or OpenCode/Claude) to the 24/7 Pi Durable Daemon
(`http://127.0.0.1:8089/v1/delegate`) with automatic fallback to direct durable `pi --session-id`.
"""

import json
import os
import subprocess
import sys
import urllib.request
from typing import Any, Dict

PI_DAEMON_URL = os.environ.get("PI_DAEMON_URL", "http://127.0.0.1:8089")
SESSION_DIR = os.environ.get("PI_SESSION_DIR", "/persist/var/lib/pi-agent/sessions")

TOOLS = [
    {
        "name": "pi_worker_delegate",
        "description": "Delegate a coding, file-analysis, or shell task to the durable 24/7 Pi coding worker.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task": {"type": "string", "description": "Clear, actionable coding or investigation task for Pi"},
                "model": {"type": "string", "description": "Optional Kong model/combo ID (defaults to Coding)"},
                "session_id": {
                    "type": "string",
                    "description": "Durable session ID to preserve context across delegations (defaults to hermes-a2a)",
                },
                "notify_voice": {
                    "type": "boolean",
                    "description": "Whether to announce completion via GLaDOS voice (default: true)",
                },
            },
            "required": ["task"],
        },
    },
    {
        "name": "pi_daemon_status",
        "description": "Check the health, active sessions, and completed task count of the 24/7 Pi Durable Daemon.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "pi_decompose_and_advance",
        "description": "Break a task into actionable [SAFE-AUTO] vs [APPROVAL-GATE] steps, execute all [SAFE-AUTO] preparation/refinement steps immediately using free/quota-balanced tiers, and write a structured Markdown report in ~/Notes/EverOS/reports/ linked in todo.md.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task": {"type": "string", "description": "Task description from todo.md or user request"},
                "agent": {
                    "type": "string",
                    "description": "Owner section in todo.md (pi or hermes, default: pi)",
                },
            },
            "required": ["task"],
        },
    },
]


def run_pi_worker(
    task: str,
    model: str = "Coding",
    session_id: str = "hermes-a2a",
    notify_voice: bool = True,
) -> Dict[str, Any]:
    # 1. Prefer the warm 24/7 Pi Durable Daemon (:8089)
    try:
        payload = json.dumps(
            {
                "task": task,
                "model": model,
                "session_id": session_id,
                "notify_voice": notify_voice,
            }
        ).encode("utf-8")
        req = urllib.request.Request(
            f"{PI_DAEMON_URL}/v1/delegate",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=185) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        pass

    # 2. Fallback: invoke durable Pi CLI directly with persistent session-id
    sdir = SESSION_DIR if os.path.isdir(SESSION_DIR) and os.access(SESSION_DIR, os.W_OK) else os.path.expanduser("~/.pi/agent/sessions")
    os.makedirs(sdir, exist_ok=True)
    cmd = [
        "/run/current-system/sw/bin/pi",
        "--print",
        "--session-dir",
        sdir,
        "--session-id",
        session_id,
        "--no-mcp",
        "--provider",
        "kong",
        "--model",
        model,
        task,
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        return {
            "status": "completed" if proc.returncode == 0 else "error",
            "returncode": proc.returncode,
            "session_id": session_id,
            "output": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip()[:500],
        }
    except Exception as exc:
        return {"status": "error", "error": str(exc)}


def get_pi_status() -> Dict[str, Any]:
    try:
        with urllib.request.urlopen(f"{PI_DAEMON_URL}/healthz", timeout=3) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as exc:
        return {"status": "unreachable", "error": str(exc)}


def handle_rpc(msg: Dict[str, Any]) -> Dict[str, Any]:
    req_id = msg.get("id")
    method = msg.get("method", "")
    params = msg.get("params") or {}

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "hermes-pi-a2a-worker", "version": "2.0.0"},
            },
        }
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS}}
    if method == "tools/call":
        name = params.get("name")
        args = params.get("arguments") or {}
        if name == "pi_worker_delegate":
            res = run_pi_worker(
                task=str(args.get("task", "")),
                model=str(args.get("model", "Coding")),
                session_id=str(args.get("session_id", "hermes-a2a")),
                notify_voice=bool(args.get("notify_voice", True)),
            )
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"content": [{"type": "text", "text": json.dumps(res, indent=2)}]},
            }
        if name == "pi_daemon_status":
            res = get_pi_status()
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"content": [{"type": "text", "text": json.dumps(res, indent=2)}]},
            }
        if name == "pi_decompose_and_advance":
            try:
                payload = json.dumps(
                    {
                        "task": str(args.get("task", "")),
                        "agent": str(args.get("agent", "pi")),
                    }
                ).encode("utf-8")
                req = urllib.request.Request(
                    f"{PI_DAEMON_URL}/v1/decompose",
                    data=payload,
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=245) as resp:
                    res = json.loads(resp.read().decode("utf-8"))
            except Exception as exc:
                res = {"status": "error", "error": str(exc)}
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"content": [{"type": "text", "text": json.dumps(res, indent=2)}]},
            }
        return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Unknown tool: {name}"}}

    return {"jsonrpc": "2.0", "id": req_id, "result": {}}


def main() -> None:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
            if "id" in msg:
                resp = handle_rpc(msg)
                sys.stdout.write(json.dumps(resp) + "\n")
                sys.stdout.flush()
        except Exception:
            continue


if __name__ == "__main__":
    main()
