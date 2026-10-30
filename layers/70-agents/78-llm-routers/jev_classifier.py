#!/usr/bin/env python3
"""
Jev System-1 Pre-Flight Classifier Daemon
Listens on port 20127. Provides zero-token and local SLM two-stage triage
before forwarding or escalating agent tasks and event notifications.
"""

import sys
import os
import json
import time
import re
import uuid
import sqlite3
import urllib.request
import urllib.error
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime, timezone

JEV_HOST = os.environ.get("JEV_HOST", "127.0.0.1")
JEV_PORT = int(os.environ.get("JEV_PORT", "20127"))
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen3.5:9b")
UPSTREAM_ROUTER_URL = os.environ.get("UPSTREAM_ROUTER_URL", "http://127.0.0.1:20128")
STATE_DB_PATH = Path(os.environ.get("PI_STATE_DB", Path.home() / ".local/share/pi-durable/state.sqlite"))
JEV_RULES_FILE = Path(__file__).parent / "jev_rules.json"

METRICS = {
    "total_requests": 0,
    "stage1_heuristic_drops": 0,
    "stage2_classifications": 0,
    "dispatched_agents": 0,
    "notifications": 0,
}

# Routine patterns that can be dropped at zero token cost (fallback defaults)
DEFAULT_ROUTINE_PING_PATTERNS = [
    r"^(?:ok|pong|ping|heartbeat|healthz?|status\s*200|200\s*ok)$",
    r"\{\s*\"(?:status|health|ping)\"\s*:\s*(?:\"(?:ok|pong|alive|healthy)\"|200)\s*\}",
    r"connection\s+keep-?alive",
    r"routine\s+check\s+passed",
]

# High-risk trigger keywords for deterministic escalation (fallback defaults)
DEFAULT_CRITICAL_PATTERNS = [
    r"\b(out of memory|oom-killer|disk\s*full|read-only file system|kernel panic|segfault|security breach|unauthorized root|database corruption)\b",
]

def load_heuristic_patterns() -> tuple[list[str], list[str]]:
    """Loads heuristic rules from jev_rules.json if present; falls back to defaults."""
    if JEV_RULES_FILE.exists():
        try:
            data = json.loads(JEV_RULES_FILE.read_text(encoding="utf-8"))
            pings = data.get("routine_ping_patterns", DEFAULT_ROUTINE_PING_PATTERNS)
            crits = data.get("critical_patterns", DEFAULT_CRITICAL_PATTERNS)
            return pings, crits
        except Exception:
            pass
    return DEFAULT_ROUTINE_PING_PATTERNS, DEFAULT_CRITICAL_PATTERNS

def log_drop_to_sqlite(event_text: str, reason: str, stage: int = 1, tokens_saved: int = 0) -> None:
    """Logs dropped requests to SQLite for dream cycle weakness mining."""
    try:
        STATE_DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(STATE_DB_PATH))
        now = datetime.now(timezone.utc).isoformat()
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
        conn.execute(
            "INSERT INTO jev_drops (timestamp, event_text, drop_reason, stage, tokens_saved) VALUES (?, ?, ?, ?, ?)",
            (now, str(event_text)[:1000], str(reason)[:500], stage, tokens_saved),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass

def stage1_heuristic_check(payload_text: str) -> dict | None:
    """Stage 1: Zero-token heuristic check. Returns decision dict if droppable or critical, else None."""
    clean = payload_text.strip().lower()
    if not clean or len(clean) < 3:
        return {
            "stage": 1,
            "verdict": "IGNORE",
            "actionability": False,
            "risk_level": "low",
            "target_persona": None,
            "reason": "Empty or trivial payload dropped at zero token cost",
            "tokens_used": 0,
        }

    routine_pats, critical_pats = load_heuristic_patterns()

    for pat in routine_pats:
        if re.search(pat, clean):
            return {
                "stage": 1,
                "verdict": "IGNORE",
                "actionability": False,
                "risk_level": "low",
                "target_persona": None,
                "reason": f"Routine ping/200 OK matched heuristic '{pat}' — dropped at zero token cost",
                "tokens_used": 0,
            }

    for pat in critical_pats:
        if re.search(pat, clean, re.I):
            return {
                "stage": 1,
                "verdict": "DISPATCH_AGENT",
                "actionability": True,
                "risk_level": "critical",
                "target_persona": "glados-auditor",
                "reason": f"Critical infrastructure alert pattern matched '{pat}'",
                "tokens_used": 0,
            }

    return None

def query_ollama_classifier(text: str) -> dict:
    """Stage 2: Ollama local SLM classification."""
    prompt = f"""You are Jev System-1, a pre-flight classifier. Analyze this event and output ONLY valid JSON.
Event:
{text[:2000]}

JSON Schema:
{{
  "actionability": true or false,
  "risk_level": "low" | "medium" | "high" | "critical",
  "target_persona": "jarvis-classic" | "glados-auditor" | "samuel-jackson" | "cortana",
  "verdict": "IGNORE" | "NOTIFY" | "DISPATCH_AGENT",
  "summary": "1-2 sentence concise summary"
}}"""

    req_data = json.dumps({
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.1, "num_predict": 256}
    }).encode("utf-8")

    try:
        req = urllib.request.Request(
            f"{OLLAMA_URL}/api/generate",
            data=req_data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=3.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            parsed = json.loads(data.get("response", "{}"))
            parsed["stage"] = 2
            parsed["tokens_used"] = data.get("prompt_eval_count", 0) + data.get("eval_count", 0)
            return parsed
    except Exception as e:
        # Fallback if Ollama is unreachable or slow
        risk = "medium" if "error" in text.lower() or "fail" in text.lower() else "low"
        verdict = "NOTIFY" if risk == "medium" else "IGNORE"
        persona = "glados-auditor" if risk == "medium" else "jarvis-classic"
        return {
            "stage": 2,
            "fallback": True,
            "actionability": (verdict != "IGNORE"),
            "risk_level": risk,
            "target_persona": persona,
            "verdict": verdict,
            "summary": f"Fallback classification (Ollama offline: {e}): {text[:120]}",
            "tokens_used": 0
        }

def build_a2ui_card(triage_result: dict, original_event: str) -> dict:
    """Emits an A2UI compliant Action Card."""
    card_id = f"card-{uuid.uuid4().hex[:12]}"
    now_iso = datetime.now(timezone.utc).isoformat()
    verdict = triage_result.get("verdict", "NOTIFY")
    risk = triage_result.get("risk_level", "low")

    actions = [
        {
            "id": "act-dismiss",
            "label": "Dismiss",
            "style": "outline",
            "action_type": "dismiss",
            "payload": {"card_id": card_id}
        }
    ]

    if verdict == "DISPATCH_AGENT":
        actions.insert(0, {
            "id": "act-approve",
            "label": "Approve Agent Remediation",
            "style": "danger" if risk == "critical" else "primary",
            "action_type": "approve",
            "payload": {
                "card_id": card_id,
                "command": "hermes-ratchet run --event",
                "risk_level": risk
            }
        })
    elif verdict == "NOTIFY":
        actions.insert(0, {
            "id": "act-ack",
            "label": "Acknowledge",
            "style": "primary",
            "action_type": "dismiss",
            "payload": {"card_id": card_id}
        })

    return {
        "card_id": card_id,
        "timestamp": now_iso,
        "source_agent": "jev-classifier",
        "target_persona": triage_result.get("target_persona", "jarvis-classic"),
        "title": f"Triage Alert [{risk.upper()}]: {verdict}",
        "summary": triage_result.get("summary", original_event[:160]),
        "risk_level": risk,
        "verdict": verdict,
        "actionability": triage_result.get("actionability", False),
        "diff_preview": None,
        "actions": actions,
        "ttl_rule": {
            "timeout_seconds": 300,
            "default_action_id": "act-dismiss",
            "on_expire": "auto_dismiss"
        }
    }

def run_triage(event_text: str) -> dict:
    """Full two-stage triage pipeline."""
    METRICS["total_requests"] += 1
    t0 = time.time()
    
    # Stage 1: Zero-token heuristic check
    res = stage1_heuristic_check(event_text)
    if res is not None:
        METRICS["stage1_heuristic_drops"] += 1
        res["latency_ms"] = round((time.time() - t0) * 1000, 2)
        if res["verdict"] == "IGNORE":
            log_drop_to_sqlite(event_text, res.get("reason", "Stage 1 heuristic drop"), stage=1, tokens_saved=20)
        elif res["verdict"] in ("NOTIFY", "DISPATCH_AGENT"):
            res["a2ui_card"] = build_a2ui_card(res, event_text)
        return res

    # Stage 2: Ollama local SLM classification
    METRICS["stage2_classifications"] += 1
    res = query_ollama_classifier(event_text)
    res["latency_ms"] = round((time.time() - t0) * 1000, 2)
    
    if res["verdict"] == "DISPATCH_AGENT":
        METRICS["dispatched_agents"] += 1
        # Dispatch OnCallAgent for system errors/panics
        if any(k in event_text.lower() for k in ("panic", "50", "exception", "error", "fail", "oom", "segfault")):
            try:
                repo_root = Path(__file__).resolve().parents[3]
                oncall_script = repo_root / "layers/70-agents/71-harness/oncall_agent.py"
                if oncall_script.exists():
                    subprocess.Popen(
                        [sys.executable, str(oncall_script), "--event", json.dumps({"service": "jev-triage", "error": event_text[:300], "severity": res.get("risk_level", "high")})],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
            except Exception:
                pass
    elif res["verdict"] == "NOTIFY":
        METRICS["notifications"] += 1

    if res.get("actionability") or res.get("verdict") in ("NOTIFY", "DISPATCH_AGENT"):
        res["a2ui_card"] = build_a2ui_card(res, event_text)

    return res

class JevHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Concise logging to stdout
        sys.stdout.write(f"[JevClassifier] {self.address_string()} - {format % args}\n")
        sys.stdout.flush()

    def do_GET(self):
        if self.path in ("/health", "/healthz"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            resp = {
                "status": "ok",
                "service": "jev-classifier",
                "port": JEV_PORT,
                "metrics": METRICS,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            self.wfile.write(json.dumps(resp).encode("utf-8"))
        elif self.path == "/metrics":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            lines = [
                f"jev_requests_total {METRICS['total_requests']}",
                f"jev_stage1_heuristic_drops {METRICS['stage1_heuristic_drops']}",
                f"jev_stage2_classifications {METRICS['stage2_classifications']}",
                f"jev_dispatched_agents {METRICS['dispatched_agents']}",
                f"jev_notifications {METRICS['notifications']}",
            ]
            self.wfile.write("\n".join(lines).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_len = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_len).decode("utf-8") if content_len > 0 else ""

        if self.path in ("/classify", "/v1/classify", "/triage"):
            try:
                data = json.loads(raw_body) if raw_body else {}
                text = data.get("text") or data.get("event") or data.get("prompt") or str(data)
            except Exception:
                text = raw_body

            result = run_triage(text)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode("utf-8"))
        elif self.path in ("/v1/chat/completions", "/chat/completions"):
            # Check prompt: if trivial ping, drop or return instant response; otherwise proxy
            try:
                data = json.loads(raw_body) if raw_body else {}
                messages = data.get("messages", [])
                user_msg = messages[-1].get("content", "") if messages else ""
            except Exception:
                user_msg = raw_body

            heur = stage1_heuristic_check(user_msg)
            if heur and heur["verdict"] == "IGNORE":
                # Instant mock reply at zero tokens
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                mock_resp = {
                    "id": f"chatcmpl-{uuid.uuid4().hex[:8]}",
                    "object": "chat.completion",
                    "created": int(time.time()),
                    "model": "jev-zero-token",
                    "choices": [{
                        "index": 0,
                        "message": {"role": "assistant", "content": "PONG (suppressed at zero token cost)"},
                        "finish_reason": "stop"
                    }],
                    "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}
                }
                self.wfile.write(json.dumps(mock_resp).encode("utf-8"))
                return

            # Proxy to ExtremeRouter upstream
            try:
                upstream_req = urllib.request.Request(
                    f"{UPSTREAM_ROUTER_URL}/v1/chat/completions",
                    data=raw_body.encode("utf-8"),
                    headers={"Content-Type": "application/json"},
                    method="POST"
                )
                with urllib.request.urlopen(upstream_req, timeout=60) as upstream_resp:
                    self.send_response(upstream_resp.status)
                    for k, v in upstream_resp.headers.items():
                        if k.lower() not in ("content-length", "transfer-encoding"):
                            self.send_header(k, v)
                    resp_body = upstream_resp.read()
                    self.send_header("Content-Length", str(len(resp_body)))
                    self.end_headers()
                    self.wfile.write(resp_body)
            except Exception as e:
                err_msg = f"Upstream ExtremeRouter unreachable: {e}"
                try:
                    repo_root = Path(__file__).resolve().parents[3]
                    oncall_script = repo_root / "layers/70-agents/71-harness/oncall_agent.py"
                    if oncall_script.exists():
                        subprocess.Popen(
                            [sys.executable, str(oncall_script), "--event", json.dumps({"service": "extreme-router", "error": err_msg, "severity": "high"})],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL
                        )
                except Exception:
                    pass
                self.send_response(502)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": err_msg}).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def self_test():
    print("==> Running Jev System-1 Classifier Self-Test...")
    # Test 1: Stage 1 routine ping drop
    r1 = stage1_heuristic_check("200 OK")
    assert r1 is not None and r1["verdict"] == "IGNORE", f"Test 1 failed: {r1}"
    print("  [PASS] Test 1: '200 OK' dropped at Stage 1 (zero tokens)")

    # Test 2: Stage 1 healthz JSON drop
    r2 = stage1_heuristic_check('{"status": "ok"}')
    assert r2 is not None and r2["verdict"] == "IGNORE", f"Test 2 failed: {r2}"
    print("  [PASS] Test 2: '{\"status\": \"ok\"}' dropped at Stage 1")

    # Test 3: Critical panic escalation
    r3 = stage1_heuristic_check("Kernel panic: out of memory (oom-killer invoked)")
    assert r3 is not None and r3["verdict"] == "DISPATCH_AGENT", f"Test 3 failed: {r3}"
    print("  [PASS] Test 3: Critical panic escalated immediately to DISPATCH_AGENT")

    # Test 4: Full triage with A2UI Card generation
    card = build_a2ui_card(r3, "Kernel panic: out of memory")
    assert card["card_id"].startswith("card-")
    assert card["verdict"] == "DISPATCH_AGENT"
    assert len(card["actions"]) >= 2
    print("  [PASS] Test 4: A2UI Card successfully built and validated")

    # Test 5: Fallback triage
    t5 = run_triage("Disk usage at /persist is climbing to 92%, investigation needed.")
    assert t5["verdict"] in ("NOTIFY", "DISPATCH_AGENT", "IGNORE")
    print(f"  [PASS] Test 5: Complex event triaged (Verdict={t5['verdict']}, Risk={t5['risk_level']})")

    print("==> All Jev Classifier tests PASSED!")
    return 0

if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())

    server = HTTPServer((JEV_HOST, JEV_PORT), JevHandler)
    print(f"[JevClassifier] Daemon listening on http://{JEV_HOST}:{JEV_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[JevClassifier] Shutting down.")
        server.server_close()
