#!/usr/bin/env python3
"""
Jev Tier Router — Async Streaming Decision-Only Reverse Proxy
Sits behind Kong (:8090/jev) and in front of ExtremeRouter (:20128).

Core Guarantees:
1. NEVER synthesizes an assistant answer. Every request is proxied upstream.
2. Evaluates request signals + optional Jev Engine (:20130) within a strict 50ms
   budget (fails open to default combo `Coding` if >50ms or engine down).
3. Selects one of 4 canonical tiers mapped to router-native combos:
   - voice-fast       -> Penny-Pincher (fast/low-latency, small max_tokens)
   - free-first       -> Free          (zero-cost swarm, non-tool turns only)
   - cascade-balanced -> Coding        (router-native cascade, tool-capable)
   - frontier         -> Judge / ag/claude-opus-4-6-thinking (complex/escalated)
4. Enforces tool-safety (tool-bearing turns only go to tool-capable combos;
   destructive tools flagged & schema-validated) and prompt-sensitivity guardrails
   (sensitive prompts never go to tos:avoid / web-cookie providers).
5. Output-based escalation: validates JSON/tool-call arguments against schema,
   detects truncation/refusal/loops; retries once at same tier, then escalates
   one tier (capped at MAX_ATTEMPTS = 3).
6. Full SSE streaming passthrough (`stream: true`), Prometheus `/metrics`, and
   Langfuse tracing.
"""

import asyncio
import base64
import collections
import datetime
import http.client
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from typing import Any, Callable, Dict, List, Optional, Tuple

HOST = os.environ.get("JEV_ROUTER_HOST", "127.0.0.1")
PORT = int(os.environ.get("JEV_ROUTER_PORT", "20127"))
UPSTREAM_ROUTER_URL = os.environ.get("UPSTREAM_ROUTER_URL", "http://100.64.0.1:20128")
JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
LOCAL_SLM_URL = os.environ.get("LOCAL_SLM_URL", "http://127.0.0.1:11434")
LANGFUSE_HOST = os.environ.get("LANGFUSE_HOST", "http://127.0.0.1:3005")
JEV_ENGINE_TIMEOUT_MS = float(os.environ.get("JEV_ENGINE_TIMEOUT_MS", "50.0"))
MAX_ATTEMPTS = int(os.environ.get("JEV_MAX_ATTEMPTS", "3"))

# ── Canonical Tier Definitions & Router Combo Mapping ─────────────────────
TIER_ORDER = ["voice-fast", "free-first", "cascade-balanced", "frontier"]

TIER_TO_COMBO = {
    "voice-fast": "Penny-Pincher",
    "free-first": "Free",
    "cascade-balanced": "Coding",
    "frontier": "Judge",
}

# Tool-bearing turns require reliable tool-calling combos/models
TOOL_CAPABLE_TIER_COMBO = {
    "voice-fast": "Coding",
    "free-first": "Coding",
    "cascade-balanced": "Coding",
    "frontier": "ag/claude-opus-4-6-thinking",
}

# Verified fast direct fallback models per tier when a combo's primary upstream returns 4xx/5xx
TIER_FALLBACK_MODEL = {
    "voice-fast": "gh/gpt-4o-mini",
    "free-first": "gh/gpt-4o-mini",
    "cascade-balanced": "ag/gemini-3-flash",
    "frontier": "ag/claude-sonnet-4-6",
}

# Sensitive prompts MUST stay on trusted/local providers (never web-cookie / tos:avoid)
TRUSTED_SENSITIVE_MODEL = os.environ.get("JEV_TRUSTED_MODEL", "ag/claude-sonnet-4-6")
LOCAL_TRUSTED_MODEL = os.environ.get("JEV_LOCAL_MODEL", "ollama/qwen3.5")

TOS_AVOID_PROVIDERS = {
    "felo", "puter", "g4fpol", "g4fgem", "g4fgroq", "g4fnv",
    "aihorde", "cl", "wb", "cbai", "kimchi", "unc", "fbw",
}

CODE_REASONING_PATTERNS = re.compile(
    r"(```|\bdef\s+\w+|\bfunction\s+\w+|\bclass\s+\w+|traceback|stack\s*trace|"
    r"refactor|architect|deadlock|race\s+condition|prove\s+that|complexity|"
    r"nixosConfigurations|flake\.nix|systemd\.services|sql|regex|optimize|theorem|invariant)",
    re.IGNORECASE,
)

FRONTIER_CUES = re.compile(
    r"(architect|multi-file|security\s+audit|formal\s+proof|root\s+cause|"
    r"distributed\s+consensus|kernel\s+panic|deep\s+research|design\s+packet|"
    r"migration\s+plan|review\s+packet)",
    re.IGNORECASE,
)

DESTRUCTIVE_TOOL_PATTERNS = re.compile(
    r"(rm\s+-rf|drop\s+table|delete_all|destroy|wipe|format_disk|mkfs|"
    r"dd\s+if=|git\s+push\s+--force|clan\s+machines\s+update|nixos-rebuild\s+switch|"
    r"truncate\s+table|remove_database|kill_all)",
    re.IGNORECASE,
)

SENSITIVE_PROMPT_PATTERNS = re.compile(
    r"(-----BEGIN\s+[A-Z ]*PRIVATE\s+KEY-----|AGE-SECRET-KEY-1[A-Z0-9]+|"
    r"sops_mac|password\s*[:=]\s*\S+|api[_-]?key\s*[:=]\s*sk-[A-Za-z0-9]+|"
    r"ssn\s*[:=]|\bconfidential\b|\binternal-only\b)",
    re.IGNORECASE,
)

REFUSAL_PATTERNS = re.compile(
    r"^(I\s+cannot\s+fulfill\s+this\s+request|I\s+am\s+unable\s+to\s+assist\s+with\s+that|"
    r"As\s+an\s+AI\s+language\s+model,\s+I\s+cannot|I\s+can't\s+help\s+with\s+that)",
    re.IGNORECASE,
)

# ── In-Memory Session State & Prometheus Metrics ──────────────────────────
SESSION_FAILURES: Dict[str, int] = collections.defaultdict(int)

METRICS = {
    "requests_total": collections.Counter(),       # (tier, combo, consumer, escalated)
    "escalations_total": collections.Counter(),    # (from_tier, to_tier, reason)
    "fail_open_total": 0,
    "sensitive_guarded_total": 0,
    "destructive_flagged_total": 0,
    "eval_latency_ms_sum": 0.0,
    "eval_latency_ms_count": 0,
    "upstream_latency_ms_sum": 0.0,
    "upstream_latency_ms_count": 0,
}


def load_upstream_api_key() -> str:
    for env_name in ("EXTREMEROUTER_API_KEY", "OPENAI_API_KEY"):
        if os.environ.get(env_name):
            return os.environ[env_name].strip()
    for p in (
        os.path.expanduser("~/.config/sops-nix/secrets/extremerouter_api_key"),
        "/run/secrets/extremerouter_api_key",
    ):
        if os.path.exists(p):
            try:
                with open(p) as f:
                    return f.read().strip()
            except Exception:
                pass
    return ""


def extract_prompt_text(payload: Dict[str, Any]) -> str:
    messages = payload.get("messages", [])
    if not messages:
        if isinstance(payload.get("input"), str):
            return payload["input"]
        if isinstance(payload.get("input"), list):
            messages = payload["input"]
        elif "prompt" in payload:
            return str(payload["prompt"])

    parts: List[str] = []
    for msg in messages:
        if not isinstance(msg, dict):
            continue
        role = msg.get("role", "user")
        content = msg.get("content", "")
        if isinstance(content, list):
            chunks = [
                c.get("text", "")
                for c in content
                if isinstance(c, dict) and c.get("type") in ("text", "input_text")
            ]
            content = " ".join(chunks)
        if content:
            parts.append(f"{role}: {content}")
    return "\n".join(parts)


def detect_tools_and_destructiveness(payload: Dict[str, Any], prompt_text: str) -> Tuple[bool, bool]:
    tools = payload.get("tools") or []
    tool_choice = payload.get("tool_choice")
    messages = payload.get("messages") or []

    has_role_tool = any(
        isinstance(m, dict) and (
            m.get("role") == "tool"
            or bool(m.get("tool_calls"))
            or (
                isinstance(m.get("content"), list)
                and any(
                    isinstance(b, dict) and b.get("type") in ("tool_use", "tool_result")
                    for b in m["content"]
                )
            )
        )
        for m in messages
    )
    has_tools = bool(tools) or (tool_choice not in (None, "none")) or has_role_tool

    destructive = False
    if has_tools:
        if DESTRUCTIVE_TOOL_PATTERNS.search(prompt_text):
            destructive = True
        for t in tools:
            if not isinstance(t, dict):
                continue
            fn = t.get("function", t)
            name = str(fn.get("name", ""))
            desc = str(fn.get("description", ""))
            if fn.get("x-destructive") is True or t.get("x-destructive") is True:
                destructive = True
            elif DESTRUCTIVE_TOOL_PATTERNS.search(f"{name} {desc}"):
                destructive = True
    return has_tools, destructive


def query_jev_engine_sync(prompt_text: str, timeout_s: float) -> Optional[Dict[str, Any]]:
    req_body = json.dumps({
        "state": prompt_text[:2048],
        "questions": [
            {
                "id": "target_tier",
                "type": "enum",
                "options": ["voice-fast", "free-first", "cascade-balanced", "frontier"],
            }
        ],
    }).encode("utf-8")
    req = urllib.request.Request(
        f"{JEV_ENGINE_URL.rstrip('/')}/v1/decide",
        data=req_body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        if resp.status == 200:
            return json.loads(resp.read().decode("utf-8"))
    return None


async def query_jev_engine(prompt_text: str, timeout_ms: float = JEV_ENGINE_TIMEOUT_MS) -> Tuple[Optional[Dict[str, Any]], bool]:
    """Query Jev engine within strict 50ms SLA; fail open if slow or down."""
    if not JEV_ENGINE_URL or timeout_ms <= 0:
        return None, True
    timeout_s = max(0.005, timeout_ms / 1000.0)
    try:
        res = await asyncio.wait_for(
            asyncio.to_thread(query_jev_engine_sync, prompt_text, timeout_s),
            timeout=timeout_s,
        )
        return res, False
    except Exception:
        return None, True


def escalate_tier(tier: str, steps: int = 1) -> str:
    if tier not in TIER_ORDER:
        return "cascade-balanced"
    idx = TIER_ORDER.index(tier)
    # Note: voice-fast escalates to cascade-balanced on failure
    if tier == "voice-fast" and steps >= 1:
        return "cascade-balanced" if steps == 1 else "frontier"
    new_idx = min(len(TIER_ORDER) - 1, idx + steps)
    return TIER_ORDER[new_idx]


def select_tier_and_model(
    payload: Dict[str, Any],
    headers: Dict[str, str],
    session_failures: int = 0,
    engine_result: Optional[Dict[str, Any]] = None,
    fail_open: bool = False,
) -> Dict[str, Any]:
    """
    Pure decision function: selects (tier, combo/model) from request signals.
    Never synthesizes an answer.
    """
    prompt_text = extract_prompt_text(payload)
    msg_len = len(prompt_text)
    has_tools, is_destructive = detect_tools_and_destructiveness(payload, prompt_text)
    has_code_cues = bool(CODE_REASONING_PATTERNS.search(prompt_text))
    has_frontier_cues = bool(FRONTIER_CUES.search(prompt_text))

    headers_lower = {k.lower(): v for k, v in headers.items()}
    consumer = (
        headers_lower.get("x-consumer-username")
        or headers_lower.get("x-jev-consumer")
        or "anonymous"
    ).strip().lower()

    is_sensitive = (
        headers_lower.get("x-sensitive-prompt", "").lower() == "true"
        or bool(SENSITIVE_PROMPT_PATTERNS.search(prompt_text))
    )

    requested_model = str(payload.get("model") or "").strip()

    # 1. Explicit tier hint in model field or voice consumer
    if requested_model in TIER_ORDER:
        tier = requested_model
        reason = f"explicit_tier_hint:{requested_model}"
    elif consumer in ("voice", "hermes-voice") or headers_lower.get("x-voice-turn") == "true":
        tier = "voice-fast"
        reason = f"voice_consumer:{consumer}"
    elif has_frontier_cues or msg_len > 12000:
        tier = "frontier"
        reason = "frontier_cues_or_large_context"
    elif has_tools or has_code_cues or msg_len > 1200:
        tier = "cascade-balanced"
        reason = "tools_or_code_or_medium_length"
    elif fail_open:
        # Fail-open default combo when Jev engine timed out / unavailable
        tier = "cascade-balanced"
        reason = "fail_open_default"
    else:
        tier = "free-first"
        reason = "short_general_turn"

    # 2. Enforce tool-bearing guardrail: never route tools to free-first
    if has_tools and tier in ("free-first", "voice-fast"):
        if consumer not in ("voice", "hermes-voice"):
            tier = "cascade-balanced"
            reason += "+tool_guardrail"

    # 3. Destructive tool guardrail: minimum cascade-balanced + validation flag
    human_approved = headers_lower.get("x-jev-human-approved", "").lower() == "true"
    destructive_policy = "none"
    if is_destructive:
        destructive_policy = "human_approved" if human_approved else "validated_retry_required"
        if tier in ("free-first", "voice-fast"):
            tier = "cascade-balanced"
            reason += "+destructive_tool_guardrail"

    # 4. Per-session failure escalation
    if session_failures > 0:
        prev_tier = tier
        tier = escalate_tier(tier, steps=session_failures)
        if tier != prev_tier:
            reason += f"+session_failures({session_failures})"

    # 5. Map tier to router combo / model
    if is_sensitive:
        # Sensitive prompts never go to web-cookie / tos:avoid combos
        selected_model = TRUSTED_SENSITIVE_MODEL
        combo = TRUSTED_SENSITIVE_MODEL
        reason += "+sensitive_prompt_guarded"
    elif requested_model and "/" in requested_model and requested_model not in TIER_ORDER:
        # Respect explicit provider/model unless its provider is tos:avoid on a sensitive prompt
        prov = requested_model.split("/", 1)[0].lower()
        if prov in TOS_AVOID_PROVIDERS:
            selected_model = TIER_TO_COMBO[tier]
            combo = selected_model
            reason += f"+tos_avoid_replaced({prov})"
        else:
            selected_model = requested_model
            combo = TIER_TO_COMBO[tier]
    elif requested_model in ("Coding", "DailyDrive", "Penny-Pincher", "Free", "Research", "Judge", "deepseek-swarm"):
        selected_model = requested_model
        combo = requested_model
    else:
        if has_tools:
            combo = TOOL_CAPABLE_TIER_COMBO[tier]
        else:
            combo = TIER_TO_COMBO[tier]
        selected_model = combo

    return {
        "tier": tier,
        "combo": combo,
        "original_model": requested_model or None,
        "selected_model": selected_model,
        "reason": reason,
        "message_length": msg_len,
        "has_tools": has_tools,
        "has_code_cues": has_code_cues,
        "destructive_context": is_destructive,
        "destructive_policy": destructive_policy,
        "sensitive_guarded": is_sensitive,
        "session_failures": session_failures,
        "consumer": consumer,
        "fail_open": fail_open,
    }


def validate_response_output(
    resp_json: Dict[str, Any],
    request_payload: Dict[str, Any],
    destructive_context: bool = False,
    human_approved: bool = False,
) -> Tuple[bool, Optional[str]]:
    """
    Validate assistant response for:
    1. Valid choices structure
    2. Tool-call JSON argument validity + JSON schema required/type checks
    3. Destructive tool call safety check
    4. Truncation (finish_reason == 'length' with unclosed fences/braces)
    5. Refusal on standard turns
    6. Repetitive generation loops
    Returns (is_valid, failure_reason).
    """
    if not isinstance(resp_json, dict):
        return False, "non_dict_response"

    if "error" in resp_json and not resp_json.get("choices"):
        return False, f"upstream_error:{resp_json.get('error')}"

    choices = resp_json.get("choices")
    if not isinstance(choices, list) or len(choices) == 0:
        # Support /v1/responses or /v1/messages shapes if proxied
        if resp_json.get("object") == "response" or resp_json.get("type") == "message":
            return True, None
        return False, "empty_choices"

    choice = choices[0] if isinstance(choices[0], dict) else {}
    msg = choice.get("message") or {}
    finish_reason = choice.get("finish_reason")
    content = str(msg.get("content") or "")
    tool_calls = msg.get("tool_calls") or []

    # Build schema map from request tools
    tool_schemas: Dict[str, Dict[str, Any]] = {}
    for t in request_payload.get("tools") or []:
        if isinstance(t, dict):
            fn = t.get("function", t)
            if isinstance(fn, dict) and fn.get("name"):
                tool_schemas[fn["name"]] = fn.get("parameters") or {}

    if tool_calls:
        for tc in tool_calls:
            if not isinstance(tc, dict):
                return False, "malformed_tool_call_entry"
            fn = tc.get("function") or {}
            fn_name = fn.get("name", "")
            raw_args = fn.get("arguments", "{}")
            if not fn_name:
                return False, "missing_tool_call_name"
            try:
                parsed_args = json.loads(raw_args) if isinstance(raw_args, str) else raw_args
            except Exception:
                return False, f"invalid_tool_call_json:{fn_name}"
            if not isinstance(parsed_args, dict):
                return False, f"tool_call_args_not_object:{fn_name}"

            # Validate against schema if declared
            schema = tool_schemas.get(fn_name)
            if isinstance(schema, dict):
                required = schema.get("required") or []
                for req_key in required:
                    if req_key not in parsed_args:
                        return False, f"missing_required_tool_arg:{fn_name}.{req_key}"
                props = schema.get("properties") or {}
                for k, v in parsed_args.items():
                    if k in props and isinstance(props[k], dict):
                        expected_type = props[k].get("type")
                        if expected_type == "string" and not isinstance(v, str):
                            return False, f"invalid_arg_type:{fn_name}.{k}:expected_string"
                        elif expected_type == "integer" and (not isinstance(v, int) or isinstance(v, bool)):
                            return False, f"invalid_arg_type:{fn_name}.{k}:expected_integer"
                        elif expected_type == "boolean" and not isinstance(v, bool):
                            return False, f"invalid_arg_type:{fn_name}.{k}:expected_boolean"
                        elif expected_type == "object" and not isinstance(v, dict):
                            return False, f"invalid_arg_type:{fn_name}.{k}:expected_object"
                        elif expected_type == "array" and not isinstance(v, list):
                            return False, f"invalid_arg_type:{fn_name}.{k}:expected_array"

            # Check destructive tool invocation without approval
            if destructive_context and not human_approved:
                serialized = json.dumps(parsed_args)
                if DESTRUCTIVE_TOOL_PATTERNS.search(f"{fn_name} {serialized}"):
                    # Require validated non-empty args and flag if unsafe shell wildcard
                    if "rm -rf /" in serialized or "rm -rf /*" in serialized:
                        return False, f"blocked_destructive_call:{fn_name}"

    else:
        # If tool_choice explicitly required a tool call, missing tool_calls is a failure
        tc_req = request_payload.get("tool_choice")
        if tc_req == "required" or (isinstance(tc_req, dict) and tc_req.get("type") == "function"):
            return False, "missing_required_tool_call"

        if not content.strip():
            return False, "empty_assistant_content"

    # Check truncation
    if finish_reason == "length":
        if content.count("```") % 2 == 1 or (content.startswith("{") and not content.rstrip().endswith("}")):
            return False, "truncated_structured_output"

    # Check refusal
    if content and REFUSAL_PATTERNS.search(content.strip()):
        return False, "model_refusal"

    # Check repetitive token loops (any 30-char window repeated >= 4 times consecutively)
    if len(content) >= 160:
        loop_match = re.search(r"(.{25,80}?)\1{3,}", content, re.DOTALL)
        if loop_match:
            return False, "repetitive_generation_loop"

    return True, None


def get_session_id(headers: Dict[str, str], payload: Dict[str, Any]) -> str:
    h_lower = {k.lower(): v for k, v in headers.items()}
    for k in ("x-session-id", "x-conversation-id", "x-request-session"):
        if h_lower.get(k):
            return h_lower[k]
    if payload.get("user"):
        return str(payload["user"])
    consumer = h_lower.get("x-consumer-username", "default")
    return f"session:{consumer}"


def apply_decision_to_payload(payload: Dict[str, Any], decision: Dict[str, Any]) -> Dict[str, Any]:
    modified = dict(payload)
    modified["model"] = decision["selected_model"]
    modified.setdefault("stream", False)
    # Voice latency budget optimization: cap max_tokens on voice-fast if not explicitly set
    if decision["tier"] == "voice-fast" and "max_tokens" not in modified and "max_completion_tokens" not in modified:
        modified["max_tokens"] = 200
    return modified


def parse_upstream_json_or_sse(raw_bytes: bytes) -> Dict[str, Any]:
    """
    Parse upstream response bytes as standard JSON or, if upstream returned SSE
    (`data: {"object":"chat.completion.chunk",...}`) for a non-streaming request,
    reassemble the delta chunks (content + tool_calls) into a single chat.completion dict.
    """
    text = raw_bytes.decode("utf-8", "replace").strip()
    if not text:
        return {"error": "empty_upstream_body"}
    if not text.startswith("data:"):
        try:
            return json.loads(text)
        except Exception:
            return {"error": text[:500]}

    # Reassemble SSE chunks into a chat.completion object
    comp_id = "chatcmpl-jev-reassembled"
    model = "unknown"
    created = int(time.time())
    content_parts: List[str] = []
    tool_calls_by_idx: Dict[int, Dict[str, Any]] = {}
    finish_reason = "stop"

    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("data:"):
            continue
        data_str = line[5:].strip()
        if not data_str or data_str == "[DONE]":
            continue
        try:
            chunk = json.loads(data_str)
        except Exception:
            continue
        if not isinstance(chunk, dict):
            continue
        if chunk.get("id"):
            comp_id = chunk["id"]
        if chunk.get("model"):
            model = chunk["model"]
        if chunk.get("created"):
            created = chunk["created"]
        for ch in chunk.get("choices") or []:
            if not isinstance(ch, dict):
                continue
            if ch.get("finish_reason"):
                finish_reason = ch["finish_reason"]
            delta = ch.get("delta") or ch.get("message") or {}
            if delta.get("content"):
                content_parts.append(str(delta["content"]))
            for tc in delta.get("tool_calls") or []:
                idx = int(tc.get("index", 0))
                entry = tool_calls_by_idx.setdefault(
                    idx,
                    {
                        "id": tc.get("id") or f"call_{idx}",
                        "type": tc.get("type") or "function",
                        "function": {"name": "", "arguments": ""},
                    },
                )
                if tc.get("id"):
                    entry["id"] = tc["id"]
                fn = tc.get("function") or {}
                if fn.get("name"):
                    entry["function"]["name"] += str(fn["name"])
                if fn.get("arguments"):
                    entry["function"]["arguments"] += str(fn["arguments"])

    msg: Dict[str, Any] = {
        "role": "assistant",
        "content": "".join(content_parts) if content_parts else None,
    }
    if tool_calls_by_idx:
        msg["tool_calls"] = [tool_calls_by_idx[k] for k in sorted(tool_calls_by_idx.keys())]
        if finish_reason == "stop":
            finish_reason = "tool_calls"

    return {
        "id": comp_id,
        "object": "chat.completion",
        "created": created,
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": msg,
                "finish_reason": finish_reason,
            }
        ],
    }


async def execute_with_escalation(
    payload: Dict[str, Any],
    headers: Dict[str, str],
    upstream_call: Callable[[Dict[str, Any], Dict[str, str]], Any],
    engine_decide: Optional[Callable[[str], Any]] = None,
) -> Tuple[int, Dict[str, Any], Dict[str, Any]]:
    """
    Execute a chat completion request with Jev tier selection and output-based escalation:
    - Attempt 1: initial tier
    - Attempt 2 (on validation/5xx/429 failure): retry once at SAME tier
    - Attempt 3 (on second failure): escalate ONE tier
    Capped at MAX_ATTEMPTS = 3.
    """
    t0 = time.perf_counter()
    prompt_text = extract_prompt_text(payload)
    session_id = get_session_id(headers, payload)
    prior_failures = SESSION_FAILURES.get(session_id, 0)

    if engine_decide is not None:
        engine_res, fail_open = await engine_decide(prompt_text)
    else:
        engine_res, fail_open = await query_jev_engine(prompt_text, JEV_ENGINE_TIMEOUT_MS)

    eval_ms = round((time.perf_counter() - t0) * 1000.0, 2)
    METRICS["eval_latency_ms_sum"] += eval_ms
    METRICS["eval_latency_ms_count"] += 1
    if fail_open:
        METRICS["fail_open_total"] += 1

    decision = select_tier_and_model(
        payload=payload,
        headers=headers,
        session_failures=prior_failures,
        engine_result=engine_res,
        fail_open=fail_open,
    )
    decision["eval_ms"] = eval_ms
    if decision["sensitive_guarded"]:
        METRICS["sensitive_guarded_total"] += 1
    if decision["destructive_context"]:
        METRICS["destructive_flagged_total"] += 1

    initial_tier = decision["tier"]
    current_tier = initial_tier
    attempts = 0
    escalation_history: List[Dict[str, Any]] = []
    human_approved = headers.get("X-Jev-Human-Approved", headers.get("x-jev-human-approved", "")).lower() == "true"

    last_status = 502
    last_resp: Dict[str, Any] = {"error": "upstream_not_called"}

    while attempts < MAX_ATTEMPTS:
        attempts += 1
        if attempts == 1:
            current_tier = initial_tier
        elif attempts == 2:
            # Retry once on the SAME tier
            current_tier = initial_tier
        else:
            # Attempt 3: escalate ONE tier
            next_tier = escalate_tier(initial_tier, steps=1)
            METRICS["escalations_total"][(current_tier, next_tier, escalation_history[-1]["reason"])] += 1
            current_tier = next_tier

        # Recompute model for current_tier if tier changed or retrying
        if attempts > 1:
            decision["tier"] = current_tier
            if decision["sensitive_guarded"]:
                decision["selected_model"] = TRUSTED_SENSITIVE_MODEL
                decision["combo"] = TRUSTED_SENSITIVE_MODEL
            elif decision["has_tools"]:
                decision["combo"] = TOOL_CAPABLE_TIER_COMBO[current_tier]
                decision["selected_model"] = (
                    TIER_FALLBACK_MODEL[current_tier]
                    if escalation_history and str(escalation_history[-1].get("reason", "")).startswith("http_")
                    else decision["combo"]
                )
            else:
                decision["combo"] = TIER_TO_COMBO[current_tier]
                decision["selected_model"] = (
                    TIER_FALLBACK_MODEL[current_tier]
                    if escalation_history and str(escalation_history[-1].get("reason", "")).startswith("http_")
                    else decision["combo"]
                )

        req_payload = apply_decision_to_payload(payload, decision)
        t_up = time.perf_counter()
        try:
            status, resp_json = await upstream_call(req_payload, decision)
        except Exception as exc:
            status = 502
            resp_json = {"error": f"upstream_exception:{exc}"}
        up_ms = round((time.perf_counter() - t_up) * 1000.0, 2)
        METRICS["upstream_latency_ms_sum"] += up_ms
        METRICS["upstream_latency_ms_count"] += 1

        last_status, last_resp = status, resp_json

        if status == 200:
            valid, fail_reason = validate_response_output(
                resp_json,
                payload,
                destructive_context=decision["destructive_context"],
                human_approved=human_approved,
            )
            if valid:
                SESSION_FAILURES[session_id] = 0
                break
            else:
                escalation_history.append({
                    "attempt": attempts,
                    "tier": current_tier,
                    "model": decision["selected_model"],
                    "reason": fail_reason or "validation_failed",
                })
                SESSION_FAILURES[session_id] = min(2, SESSION_FAILURES[session_id] + 1)
        else:
            escalation_history.append({
                "attempt": attempts,
                "tier": current_tier,
                "model": decision["selected_model"],
                "reason": f"http_{status}",
            })
            SESSION_FAILURES[session_id] = min(2, SESSION_FAILURES[session_id] + 1)

    decision["attempts"] = attempts
    decision["escalated"] = current_tier != initial_tier
    decision["initial_tier"] = initial_tier
    decision["escalation_history"] = escalation_history

    METRICS["requests_total"][(
        decision["tier"],
        decision["combo"],
        decision["consumer"],
        str(decision["escalated"]).lower(),
    )] += 1

    asyncio.create_task(emit_langfuse_trace(payload, last_resp, decision))
    return last_status, last_resp, decision


async def emit_langfuse_trace(
    req_payload: Dict[str, Any],
    resp_payload: Dict[str, Any],
    decision: Dict[str, Any],
) -> None:
    pk = os.environ.get("LANGFUSE_PUBLIC_KEY")
    sk = os.environ.get("LANGFUSE_SECRET_KEY")
    if not pk or not sk:
        pk_path = os.path.expanduser("~/.config/sops-nix/secrets/langfuse_public_key")
        sk_path = os.path.expanduser("~/.config/sops-nix/secrets/langfuse_secret_key")
        if os.path.exists(pk_path) and os.path.exists(sk_path):
            try:
                with open(pk_path) as f:
                    pk = f.read().strip()
                with open(sk_path) as f:
                    sk = f.read().strip()
            except Exception:
                return
        else:
            return

    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
    trace_id = str(uuid.uuid4())
    event = {
        "batch": [
            {
                "id": str(uuid.uuid4()),
                "type": "trace-create",
                "timestamp": now_iso,
                "body": {
                    "id": trace_id,
                    "name": f"jev-tier-{decision.get('tier')}",
                    "timestamp": now_iso,
                    "input": {"model": req_payload.get("model"), "tier": decision.get("tier")},
                    "output": {"selected_model": decision.get("selected_model"), "attempts": decision.get("attempts")},
                    "metadata": decision,
                },
            }
        ]
    }
    auth_b64 = base64.b64encode(f"{pk}:{sk}".encode()).decode()

    def _post():
        try:
            req = urllib.request.Request(
                f"{LANGFUSE_HOST.rstrip('/')}/api/public/ingestion",
                data=json.dumps(event).encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Basic {auth_b64}",
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=1.5):
                pass
        except Exception:
            pass

    await asyncio.to_thread(_post)


def format_prometheus_metrics() -> str:
    lines = [
        "# HELP jev_requests_total Total LLM requests routed by Jev Tier Router",
        "# TYPE jev_requests_total counter",
    ]
    for (tier, combo, consumer, escalated), count in sorted(METRICS["requests_total"].items()):
        lines.append(
            f'jev_requests_total{{tier="{tier}",combo="{combo}",consumer="{consumer}",escalated="{escalated}"}} {count}'
        )
    lines.extend([
        "# HELP jev_escalations_total Total tier escalations triggered by output/status validation",
        "# TYPE jev_escalations_total counter",
    ])
    for (from_t, to_t, reason), count in sorted(METRICS["escalations_total"].items()):
        safe_reason = reason.replace('"', "'")
        lines.append(
            f'jev_escalations_total{{from_tier="{from_t}",to_tier="{to_t}",reason="{safe_reason}"}} {count}'
        )
    lines.extend([
        "# HELP jev_fail_open_total Times Jev engine exceeded 50ms SLA or was unreachable and failed open",
        "# TYPE jev_fail_open_total counter",
        f"jev_fail_open_total {METRICS['fail_open_total']}",
        "# HELP jev_sensitive_guarded_total Prompts routed to trusted/local models due to sensitivity",
        "# TYPE jev_sensitive_guarded_total counter",
        f"jev_sensitive_guarded_total {METRICS['sensitive_guarded_total']}",
        "# HELP jev_destructive_flagged_total Tool turns flagged as destructive contexts",
        "# TYPE jev_destructive_flagged_total counter",
        f"jev_destructive_flagged_total {METRICS['destructive_flagged_total']}",
        "# HELP jev_eval_latency_ms_sum Total milliseconds spent in Jev pre-flight evaluation",
        "# TYPE jev_eval_latency_ms_sum counter",
        f"jev_eval_latency_ms_sum {round(METRICS['eval_latency_ms_sum'], 3)}",
        "# HELP jev_eval_latency_ms_count Count of Jev pre-flight evaluations",
        "# TYPE jev_eval_latency_ms_count counter",
        f"jev_eval_latency_ms_count {METRICS['eval_latency_ms_count']}",
    ])
    return "\n".join(lines) + "\n"


# ── Upstream HTTP / SSE Helpers ───────────────────────────────────────────
def build_upstream_headers(incoming_headers: Dict[str, str], decision: Optional[Dict[str, Any]] = None) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for k, v in incoming_headers.items():
        if k.lower() not in (
            "host",
            "content-length",
            "transfer-encoding",
            "connection",
            "accept-encoding",
            "apikey",
            "x-api-key",
        ):
            out[k] = v
    out["Accept-Encoding"] = "identity"
    # Ensure upstream router Bearer auth is always present
    auth = out.get("Authorization") or out.get("authorization") or ""
    er_key = load_upstream_api_key()
    if er_key and (not auth or not auth.lower().startswith("bearer ")):
        out["Authorization"] = f"Bearer {er_key}"
    if decision:
        out["X-Jev-Decision"] = json.dumps(decision, separators=(",", ":"))
        out["X-Jev-Tier"] = decision["tier"]
        out["X-Jev-Combo"] = decision["combo"]
    return out


def sync_upstream_json_request(
    url: str,
    method: str,
    headers: Dict[str, str],
    body_bytes: Optional[bytes],
    timeout: float = 20.0,
) -> Tuple[int, Dict[str, str], bytes]:
    req_headers = dict(headers)
    req_headers["Connection"] = "close"
    req = urllib.request.Request(url, data=body_bytes, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
            resp_headers = {k: v for k, v in resp.headers.items()}
            return resp.status, resp_headers, data
    except urllib.error.HTTPError as err:
        data = err.read() if err.fp else b""
        resp_headers = {k: v for k, v in err.headers.items()} if err.headers else {}
        return err.code, resp_headers, data


# ── Pure-Asyncio Streaming HTTP Server (Zero External Dependencies) ───────
async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    try:
        request_line = await asyncio.wait_for(reader.readline(), timeout=30.0)
        if not request_line:
            writer.close()
            return
        parts = request_line.decode("latin-1", "replace").strip().split(" ")
        if len(parts) < 2:
            writer.close()
            return
        method, path = parts[0].upper(), parts[1]

        headers: Dict[str, str] = {}
        while True:
            line = await asyncio.wait_for(reader.readline(), timeout=15.0)
            if not line or line in (b"\r\n", b"\n"):
                break
            decoded = line.decode("latin-1", "replace").strip()
            if ":" in decoded:
                hk, hv = decoded.split(":", 1)
                headers[hk.strip()] = hv.strip()

        content_length = int(headers.get("Content-Length") or headers.get("content-length") or 0)
        raw_body = await reader.readexactly(content_length) if content_length > 0 else b""

        # Normalize Kong stripped /jev prefix if needed
        if path in ("/health", "/healthz", "/v1/health"):
            await send_http_response(
                writer,
                200,
                {"Content-Type": "application/json"},
                json.dumps({
                    "status": "ok",
                    "service": "jev-tier-router",
                    "mode": "decision-only-streaming-proxy",
                    "port": PORT,
                    "upstream": UPSTREAM_ROUTER_URL,
                    "tiers": TIER_TO_COMBO,
                }).encode("utf-8"),
            )
            return

        if path == "/metrics":
            await send_http_response(
                writer,
                200,
                {"Content-Type": "text/plain; version=0.0.4; charset=utf-8"},
                format_prometheus_metrics().encode("utf-8"),
            )
            return

        if method == "OPTIONS":
            await send_http_response(
                writer,
                204,
                {
                    "Access-Control-Allow-Origin": headers.get("Origin", "http://localhost"),
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey, x-api-key, X-Jev-Decision",
                },
                b"",
            )
            return

        if method == "POST" and path in ("/v1/chat/completions", "/v1/responses", "/v1/messages", "/v1/completions"):
            try:
                payload = json.loads(raw_body.decode("utf-8")) if raw_body else {}
            except Exception:
                payload = None

            if isinstance(payload, dict):
                is_stream = bool(payload.get("stream", False))
                if is_stream:
                    await handle_streaming_proxy(writer, path, headers, payload)
                else:
                    await handle_non_streaming_proxy(writer, path, headers, payload)
                return

        # Transparent passthrough for GET /v1/models and other endpoints
        target_url = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{path}"
        up_headers = build_upstream_headers(headers)
        status, resp_headers, resp_body = await asyncio.to_thread(
            sync_upstream_json_request,
            target_url,
            method,
            up_headers,
            raw_body if method in ("POST", "PUT", "PATCH") else None,
        )
        await send_http_response(writer, status, resp_headers, resp_body)

    except Exception as exc:
        try:
            await send_http_response(
                writer,
                502,
                {"Content-Type": "application/json"},
                json.dumps({"error": "jev_proxy_error", "details": str(exc)}).encode("utf-8"),
            )
        except Exception:
            pass
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass


async def handle_non_streaming_proxy(
    writer: asyncio.StreamWriter,
    path: str,
    headers: Dict[str, str],
    payload: Dict[str, Any],
) -> None:
    target_url = f"{UPSTREAM_ROUTER_URL.rstrip('/')}{path}"

    async def _call_upstream(mod_payload: Dict[str, Any], decision: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        up_headers = build_upstream_headers(headers, decision)
        up_headers["Content-Type"] = "application/json"
        body_bytes = json.dumps(mod_payload).encode("utf-8")
        status, _, data = await asyncio.to_thread(
            sync_upstream_json_request,
            target_url,
            "POST",
            up_headers,
            body_bytes,
        )
        parsed = parse_upstream_json_or_sse(data)
        return status, parsed

    status, resp_json, decision = await execute_with_escalation(payload, headers, _call_upstream)
    decision_hdr = json.dumps(decision, separators=(",", ":"))
    resp_bytes = json.dumps(resp_json).encode("utf-8")
    await send_http_response(
        writer,
        status,
        {
            "Content-Type": "application/json",
            "X-Jev-Decision": decision_hdr,
            "X-Jev-Tier": decision["tier"],
            "X-Jev-Combo": decision["combo"],
        },
        resp_bytes,
    )


async def handle_streaming_proxy(
    writer: asyncio.StreamWriter,
    path: str,
    headers: Dict[str, str],
    payload: Dict[str, Any],
) -> None:
    """
    Async SSE streaming passthrough with pre-stream retry/escalation:
    - Evaluates Jev decision (<50ms fail-open).
    - Connects to upstream; if upstream returns non-200 before streaming begins,
      retries once at same tier then escalates one tier.
    - Streams SSE chunks (`data: ...\n\n`) directly to client without buffering.
    """
    t0 = time.perf_counter()
    prompt_text = extract_prompt_text(payload)
    session_id = get_session_id(headers, payload)
    prior_failures = SESSION_FAILURES.get(session_id, 0)

    engine_res, fail_open = await query_jev_engine(prompt_text, JEV_ENGINE_TIMEOUT_MS)
    eval_ms = round((time.perf_counter() - t0) * 1000.0, 2)
    METRICS["eval_latency_ms_sum"] += eval_ms
    METRICS["eval_latency_ms_count"] += 1
    if fail_open:
        METRICS["fail_open_total"] += 1

    decision = select_tier_and_model(
        payload=payload,
        headers=headers,
        session_failures=prior_failures,
        engine_result=engine_res,
        fail_open=fail_open,
    )
    decision["eval_ms"] = eval_ms
    initial_tier = decision["tier"]

    parsed_url = urllib.parse.urlsplit(f"{UPSTREAM_ROUTER_URL.rstrip('/')}{path}")
    up_host = parsed_url.hostname or "127.0.0.1"
    up_port = parsed_url.port or (443 if parsed_url.scheme == "https" else 80)
    up_path = parsed_url.path or "/v1/chat/completions"
    if parsed_url.query:
        up_path = f"{up_path}?{parsed_url.query}"

    attempts = 0
    escalation_history: List[Dict[str, Any]] = []

    while attempts < MAX_ATTEMPTS:
        attempts += 1
        current_tier = initial_tier if attempts <= 2 else escalate_tier(initial_tier, steps=1)
        if attempts > 1:
            decision["tier"] = current_tier
            if decision["sensitive_guarded"]:
                decision["selected_model"] = TRUSTED_SENSITIVE_MODEL
                decision["combo"] = TRUSTED_SENSITIVE_MODEL
            elif decision["has_tools"]:
                decision["combo"] = TOOL_CAPABLE_TIER_COMBO[current_tier]
                decision["selected_model"] = (
                    TIER_FALLBACK_MODEL[current_tier]
                    if escalation_history and str(escalation_history[-1].get("reason", "")).startswith(("http_", "stream_err"))
                    else decision["combo"]
                )
            else:
                decision["combo"] = TIER_TO_COMBO[current_tier]
                decision["selected_model"] = (
                    TIER_FALLBACK_MODEL[current_tier]
                    if escalation_history and str(escalation_history[-1].get("reason", "")).startswith(("http_", "stream_err"))
                    else decision["combo"]
                )

        mod_payload = apply_decision_to_payload(payload, decision)
        body_bytes = json.dumps(mod_payload).encode("utf-8")
        decision["attempts"] = attempts
        decision["escalated"] = current_tier != initial_tier
        decision["escalation_history"] = escalation_history

        up_headers = build_upstream_headers(headers, decision)
        up_headers["Content-Type"] = "application/json"
        up_headers["Accept"] = "text/event-stream"
        up_headers["Content-Length"] = str(len(body_bytes))
        up_headers["Host"] = f"{up_host}:{up_port}"

        try:
            up_reader, up_writer = await asyncio.wait_for(
                asyncio.open_connection(up_host, up_port),
                timeout=10.0,
            )
            req_lines = [f"POST {up_path} HTTP/1.1\r\n"]
            for hk, hv in up_headers.items():
                req_lines.append(f"{hk}: {hv}\r\n")
            req_lines.append("Connection: close\r\n\r\n")
            up_writer.write("".join(req_lines).encode("latin-1") + body_bytes)
            await up_writer.drain()

            status_line = await asyncio.wait_for(up_reader.readline(), timeout=45.0)
            if not status_line:
                up_writer.close()
                escalation_history.append({"attempt": attempts, "tier": current_tier, "reason": "empty_status_line"})
                continue

            status_parts = status_line.decode("latin-1", "replace").strip().split(" ", 2)
            status_code = int(status_parts[1]) if len(status_parts) > 1 and status_parts[1].isdigit() else 502

            resp_headers: Dict[str, str] = {}
            while True:
                hline = await asyncio.wait_for(up_reader.readline(), timeout=15.0)
                if not hline or hline in (b"\r\n", b"\n"):
                    break
                hdec = hline.decode("latin-1", "replace").strip()
                if ":" in hdec:
                    rk, rv = hdec.split(":", 1)
                    resp_headers[rk.strip()] = rv.strip()

            if status_code != 200 and attempts < MAX_ATTEMPTS:
                up_writer.close()
                escalation_history.append({"attempt": attempts, "tier": current_tier, "reason": f"http_{status_code}"})
                SESSION_FAILURES[session_id] = min(2, SESSION_FAILURES[session_id] + 1)
                continue

            # Send streaming headers to client with X-Jev-Decision
            decision_hdr = json.dumps(decision, separators=(",", ":"))
            client_hdrs = [
                f"HTTP/1.1 {status_code} OK\r\n",
                f"Content-Type: {resp_headers.get('Content-Type', resp_headers.get('content-type', 'text/event-stream'))}\r\n",
                "Cache-Control: no-cache\r\n",
                "Connection: close\r\n",
                f"X-Jev-Decision: {decision_hdr}\r\n",
                f"X-Jev-Tier: {decision['tier']}\r\n",
                f"X-Jev-Combo: {decision['combo']}\r\n",
                "\r\n",
            ]
            writer.write("".join(client_hdrs).encode("latin-1"))
            await writer.drain()

            is_chunked = "chunked" in resp_headers.get("Transfer-Encoding", resp_headers.get("transfer-encoding", "")).lower()
            accumulated_text: List[str] = []

            if is_chunked:
                while True:
                    size_line = await up_reader.readline()
                    if not size_line:
                        break
                    size_str = size_line.decode("latin-1", "replace").strip().split(";")[0]
                    if not size_str:
                        continue
                    chunk_len = int(size_str, 16)
                    if chunk_len == 0:
                        await up_reader.readline()
                        break
                    chunk_data = await up_reader.readexactly(chunk_len)
                    await up_reader.readexactly(2)  # trailing \r\n
                    writer.write(chunk_data)
                    await writer.drain()
                    accumulated_text.append(chunk_data.decode("utf-8", "replace"))
            else:
                while True:
                    chunk = await up_reader.read(4096)
                    if not chunk:
                        break
                    writer.write(chunk)
                    await writer.drain()
                    accumulated_text.append(chunk.decode("utf-8", "replace"))

            up_writer.close()
            SESSION_FAILURES[session_id] = 0
            METRICS["requests_total"][(
                decision["tier"],
                decision["combo"],
                decision["consumer"],
                str(decision["escalated"]).lower(),
            )] += 1
            asyncio.create_task(emit_langfuse_trace(payload, {"stream_chunks": len(accumulated_text)}, decision))
            return

        except Exception as exc:
            escalation_history.append({"attempt": attempts, "tier": current_tier, "reason": f"stream_err:{exc}"})
            SESSION_FAILURES[session_id] = min(2, SESSION_FAILURES[session_id] + 1)

    await send_http_response(
        writer,
        502,
        {"Content-Type": "application/json", "X-Jev-Decision": json.dumps(decision, separators=(",", ":"))},
        json.dumps({"error": "upstream_stream_exhausted", "jev_decision": decision}).encode("utf-8"),
    )


async def send_http_response(
    writer: asyncio.StreamWriter,
    status_code: int,
    headers: Dict[str, str],
    body: bytes,
) -> None:
    reason = {200: "OK", 204: "No Content", 400: "Bad Request", 401: "Unauthorized", 404: "Not Found", 502: "Bad Gateway"}.get(
        status_code, "OK"
    )
    lines = [f"HTTP/1.1 {status_code} {reason}\r\n"]
    for k, v in headers.items():
        if k.lower() not in ("transfer-encoding", "content-length", "connection"):
            lines.append(f"{k}: {v}\r\n")
    lines.append(f"Content-Length: {len(body)}\r\n")
    lines.append("Connection: close\r\n\r\n")
    writer.write("".join(lines).encode("latin-1") + body)
    await writer.drain()


async def main_async() -> None:
    server = await asyncio.start_server(handle_client, HOST, PORT)
    addrs = ", ".join(str(s.getsockname()) for s in server.sockets)
    print(f"Jev Tier Router (async streaming decision-only proxy) listening on {addrs} -> {UPSTREAM_ROUTER_URL}", flush=True)
    async with server:
        await server.serve_forever()


def run() -> None:
    try:
        asyncio.run(main_async())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    run()
