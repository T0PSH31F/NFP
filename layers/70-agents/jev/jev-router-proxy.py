#!/usr/bin/env python3
"""
Jev-Driven LLM Router Pre-Flight Proxy & Optimization Hook
Intercepts LLM requests at Kong / ExtremeRouter / OmniRoute gateway.
Evaluates complexity in ~6ms via Jev System-1:
- direct_jev_decision: Returns typed decision instantly (0 LLM tokens, 100% cost saved)
- local_slm_free: Routes to local SLM (Ollama / Llama 3)
- cheap_cloud_mini: Routes to cheap cloud model (Flash / Haiku)
- frontier_flagship: Routes to frontier models (Claude 3.7 / Sonnet)
- prompt_compression_eligible: Prunes redundant boilerplate and whitespace
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

HOST = os.environ.get("JEV_ROUTER_HOST", "0.0.0.0")
PORT = int(os.environ.get("JEV_ROUTER_PORT", "20127"))
UPSTREAM_ROUTER_URL = os.environ.get("UPSTREAM_ROUTER_URL", "http://127.0.0.1:20128")
JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
LOCAL_SLM_URL = os.environ.get("LOCAL_SLM_URL", "http://127.0.0.1:11434")

ROUTER_PREFLIGHT_QUESTIONS = [
    {
        "id": "target_tier",
        "type": "enum",
        "options": [
            "direct_jev_decision",
            "local_slm_free",
            "cheap_cloud_mini",
            "frontier_flagship"
        ]
    },
    {
        "id": "is_pure_classification",
        "type": "boolean"
    },
    {
        "id": "prompt_compression_eligible",
        "type": "boolean"
    }
]


def extract_prompt_state(payload):
    """Extract system prompt and user input into normalized state string."""
    messages = payload.get("messages", [])
    if not messages and "prompt" in payload:
        return str(payload["prompt"])

    parts = []
    for msg in messages:
        role = msg.get("role", "user")
        content = msg.get("content", "")
        if isinstance(content, list):
            # Multimodal parts
            text_chunks = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
            content = " ".join(text_chunks)
        if content:
            parts.append(f"{role.capitalize()}: {content}")

    return "\n".join(parts)


def evaluate_router_preflight(state_text):
    """Evaluate complexity and routing needs via Jev decision engine."""
    payload = json.dumps({
        "state": state_text[:2048],
        "questions": ROUTER_PREFLIGHT_QUESTIONS
    }).encode("utf-8")

    urls = [
        JEV_ENGINE_URL.rstrip("/"),
        "http://127.0.0.1:20130",
        "http://luffy.nfp.nix:20130"
    ]

    for base in urls:
        try:
            req = urllib.request.Request(
                f"{base}/v1/decide",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode("utf-8"))
        except Exception:
            continue

    # Fallback local evaluation
    return fallback_local_router_decide(state_text)


def fallback_local_router_decide(state_text):
    """Fallback local joint-embedding evaluation."""
    jev_path = os.path.join(os.path.dirname(__file__), "../74-ai-infra/jev-engine.py")
    if os.path.exists(jev_path):
        try:
            import importlib.util
            spec = importlib.util.spec_from_file_location("jev_engine_local", jev_path)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            return mod.evaluate_local(state_text, ROUTER_PREFLIGHT_QUESTIONS)
        except Exception:
            pass

    state_lower = state_text.lower()
    is_class = any(k in state_lower for k in ["classify", "triage", "category", "sentiment", "tag", "is this", "spam"])
    is_complex = any(k in state_lower for k in ["architect", "design", "refactor", "proof", "debug", "complex", "plan"])
    is_simple = any(k in state_lower for k in ["summarize", "format", "json", "extract", "convert", "table"])

    if is_class:
        tier = "direct_jev_decision"
    elif is_complex:
        tier = "frontier_flagship"
    elif is_simple:
        tier = "local_slm_free"
    else:
        tier = "cheap_cloud_mini"

    return {
        "status": "success",
        "engine": "jev-router-fallback",
        "aggregate_confidence": 0.88,
        "decisions": {
            "target_tier": {"value": tier, "confidence": 0.88},
            "is_pure_classification": {"value": is_class, "confidence": 0.90},
            "prompt_compression_eligible": {"value": len(state_text) > 300, "confidence": 0.85}
        }
    }


def compress_prompt_payload(payload):
    """Prune redundant whitespace, blank lines, and debug clutter."""
    if "messages" in payload:
        compressed_msgs = []
        for msg in payload["messages"]:
            content = msg.get("content")
            if isinstance(content, str):
                # Collapse repeated blank lines
                cleaned = re.sub(r"\n{3,}", "\n\n", content)
                # Trim excessive horizontal indentation
                cleaned = re.sub(r"[ \t]+", " ", cleaned)
                msg["content"] = cleaned.strip()
            compressed_msgs.append(msg)
        payload["messages"] = compressed_msgs
    return payload


def build_direct_jev_response(state_text, decisions, latency_ms):
    """Return standard OpenAI chat completion JSON with 0 LLM tokens."""
    prompt_tokens = max(1, len(state_text.split()))
    req_id = f"chatcmpl-jev-{int(time.time() * 1000)}"

    result_content = {
        "engine": "jev-system1",
        "classification": decisions.get("target_tier", {}).get("value"),
        "is_pure_classification": decisions.get("is_pure_classification", {}).get("value", True),
        "confidence": decisions.get("target_tier", {}).get("confidence", 0.95),
        "decisions": decisions,
        "tokens_saved": prompt_tokens,
        "cost_saved_usd": round(prompt_tokens * 0.000015, 6)
    }

    return {
        "id": req_id,
        "object": "chat.completion",
        "created": int(time.time()),
        "model": "jev-system1-decision",
        "choices": [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": json.dumps(result_content, indent=2)
                },
                "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": 0,
            "total_tokens": prompt_tokens,
            "tokens_saved": prompt_tokens,
            "cost_saved_usd": round(prompt_tokens * 0.000015, 6)
        },
        "jev_preflight": {
            "latency_ms": latency_ms,
            "routed_tier": "direct_jev_decision",
            "zero_llm_tokens": True
        }
    }


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class RouterPreflightHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, status_code, data, extra_headers=None):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, str(v))
        self.end_headers()
        self.wfile.write(body)

    def forward_request(self, target_url, body_bytes=None, method="GET", headers=None):
        """Forward arbitrary request to target backend."""
        req_headers = {}
        if headers:
            for k, v in headers.items():
                if k.lower() not in ("host", "content-length"):
                    req_headers[k] = v

        req = urllib.request.Request(
            target_url,
            data=body_bytes if method in ("POST", "PUT", "PATCH") else None,
            headers=req_headers,
            method=method
        )

        try:
            with urllib.request.urlopen(req, timeout=60.0) as resp:
                resp_data = resp.read()
                self.send_response(resp.status)
                for hk, hv in resp.headers.items():
                    if hk.lower() not in ("transfer-encoding", "content-length"):
                        self.send_header(hk, hv)
                self.send_header("Content-Length", str(len(resp_data)))
                self.end_headers()
                self.wfile.write(resp_data)
        except urllib.error.HTTPError as e:
            err_data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(err_data)))
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            self.send_json(502, {"error": "Bad Gateway", "details": str(e)})

    def do_GET(self):
        if self.path in ("/health", "/healthz"):
            self.send_json(200, {
                "status": "ok",
                "service": "jev-router-plugin",
                "port": PORT,
                "upstream": UPSTREAM_ROUTER_URL
            })
        else:
            # Forward transparently (e.g. /v1/models)
            target = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{self.path}"
            self.forward_request(target, method="GET", headers=self.headers)

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length)

        if self.path in ("/v1/chat/completions", "/v1/completions"):
            t_start = time.perf_counter()
            try:
                payload = json.loads(raw_body.decode("utf-8")) if raw_body else {}
            except Exception:
                target = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{self.path}"
                self.forward_request(target, raw_body, method="POST", headers=self.headers)
                return

            state = extract_prompt_state(payload)
            jev_eval = evaluate_router_preflight(state)
            decisions = jev_eval.get("decisions", {})
            target_tier = decisions.get("target_tier", {}).get("value", "frontier_flagship")
            is_class = decisions.get("is_pure_classification", {}).get("value", False)
            comp_eligible = decisions.get("prompt_compression_eligible", {}).get("value", False)

            t_eval_ms = round((time.perf_counter() - t_start) * 1000, 2)

            # Route 1: Deterministic / Pure Classification task -> Return instant Jev decision (0 LLM tokens)
            if target_tier == "direct_jev_decision" or is_class:
                resp_json = build_direct_jev_response(state, decisions, t_eval_ms)
                self.send_json(200, resp_json, extra_headers={
                    "X-Jev-Routed-Tier": "direct_jev_decision",
                    "X-Jev-Eval-Ms": t_eval_ms,
                    "X-Tokens-Saved": resp_json["usage"]["tokens_saved"]
                })
                return

            # Route 2: Compress prompt if eligible
            if comp_eligible:
                payload = compress_prompt_payload(payload)

            # Route 3: Model adjustment based on tier
            req_headers = dict(self.headers)
            req_headers["X-Jev-Routed-Tier"] = target_tier
            req_headers["X-Jev-Eval-Ms"] = str(t_eval_ms)

            dest_url = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{self.path}"
            if target_tier == "local_slm_free" and not payload.get("model", "").startswith("claude"):
                # Suggest local SLM model to ExtremeRouter or Ollama
                payload["model"] = payload.get("model") or "llama3.2"

            mod_body = json.dumps(payload).encode("utf-8")
            self.forward_request(dest_url, mod_body, method="POST", headers=req_headers)

        else:
            # Forward all other endpoints transparently
            target = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{self.path}"
            self.forward_request(target, raw_body, method="POST", headers=self.headers)


def run():
    server = ThreadedHTTPServer((HOST, PORT), RouterPreflightHandler)
    sys.stderr.write(f"Jev Router Pre-Flight Hook running on {HOST}:{PORT} -> upstream {UPSTREAM_ROUTER_URL}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run()
