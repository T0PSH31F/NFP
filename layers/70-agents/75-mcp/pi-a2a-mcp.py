#!/usr/bin/env python3
"""
Hermes <-> Pi Worker A2A MCP Bridge (stdio JSON-RPC 2.0)
Allows Hermes (front door) to delegate coding and durable worker tasks to Pi (`pi --print --no-session`).
"""

import json
import subprocess
import sys
from typing import Any, Dict


TOOLS = [
    {
        "name": "pi_worker_delegate",
        "description": "Delegate a coding, file-analysis, or shell task from Hermes (front door) to the Pi durable coding worker.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task": {"type": "string", "description": "Clear, actionable coding or investigation task for Pi"},
                "model": {"type": "string", "description": "Optional Kong model/combo ID (defaults to Coding)"},
            },
            "required": ["task"],
        },
    }
]


def run_pi_worker(task: str, model: str = "Coding") -> Dict[str, Any]:
    cmd = [
        "/run/current-system/sw/bin/pi",
        "--print",
        "--no-session",
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
            "output": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip()[:500],
        }
    except Exception as exc:
        return {"status": "error", "error": str(exc)}


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
                "serverInfo": {"name": "hermes-pi-a2a-worker", "version": "1.0.0"},
            },
        }
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS}}
    if method == "tools/call":
        name = params.get("name")
        args = params.get("arguments") or {}
        if name == "pi_worker_delegate":
            res = run_pi_worker(str(args.get("task", "")), str(args.get("model", "Coding")))
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
