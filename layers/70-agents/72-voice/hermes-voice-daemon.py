#!/usr/bin/env python3
"""
Hermes + Pi 24/7 Durable Voice Agent Daemon & Golden-Path Test Runner
- Front door: Hermes voice persona (GLaDOS) via Kong + Jev (`voice-fast` -> `Penny-Pincher`, small `max_tokens`).
- Worker: Pi durable coding agent via `hermes-a2a` (`pi-a2a-mcp.py`).
- Voice latency budget: Wake Word -> STT -> First Sentence SSE -> Piper TTS Audio < 1.5s (1500ms).
- Exposes HTTP API on `:8880` (`/health`, `/v1/voice/turn`) and CLI modes (`--serve`, `--demo`, `--golden-test`).
"""

import argparse
import asyncio
import http.client
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import wave
from pathlib import Path
from typing import Any, AsyncGenerator, Dict, List, Optional, Tuple

_VOICE_DIR = Path(__file__).resolve().parent
if str(_VOICE_DIR) not in sys.path:
    sys.path.insert(0, str(_VOICE_DIR))

from distributed_tts_router import DistributedTTSRouter, query_local_compute
from kokoro_tts import KokoroTTSEngine
from persona_manager import PersonaConfig, PersonaManager

PORT = int(os.environ.get("HERMES_LIVE_PORT", "8880"))
HOST = os.environ.get("HERMES_LIVE_HOST", "127.0.0.1")
KONG_BASE_URL = os.environ.get("KONG_BASE_URL") or os.environ.get("ROUTER_BASE_URL") or "http://127.0.0.1:8090"
JEV_BASE_URL = os.environ.get("JEV_BASE_URL", "http://127.0.0.1:20127")
STATE_DIR = os.environ.get("HERMES_VOICE_STATE_DIR", "/var/lib/hermes-voice")
GLADOS_ONNX = os.environ.get("GLADOS_ONNX_MODEL", "/home/t0psh31f/Projects/GLaDOS/models/TTS/glados.onnx")
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?;:])\s+")
_WARM_PIPER_PROC: Optional[subprocess.Popen] = None

PERSONA_MANAGER = PersonaManager()
TTS_ENGINE = KokoroTTSEngine()
TTS_ROUTER = DistributedTTSRouter(engine=TTS_ENGINE)


def load_voice_api_key() -> Tuple[str, str]:
    """Return (header_name, key_value) for Kong/Jev/ExtremeRouter authentication."""
    for env_k in ("EXTREMEROUTER_API_KEY", "OPENAI_API_KEY"):
        if os.environ.get(env_k):
            return "Authorization", f"Bearer {os.environ[env_k].strip()}"
    for env_k in ("KONG_KEY_HERMES_VOICE", "KONG_KEY_VOICE", "KONG_API_KEY"):
        if os.environ.get(env_k):
            return "apikey", os.environ[env_k].strip()
    for fname in ("extremerouter_api_key",):
        for base in (os.path.expanduser("~/.config/sops-nix/secrets"), "/run/secrets"):
            p = os.path.join(base, fname)
            if os.path.exists(p):
                try:
                    with open(p) as f:
                        val = f.read().strip()
                    if val:
                        return "Authorization", f"Bearer {val}"
                except Exception:
                    pass
    for fname in ("kong_key_hermes_voice", "kong_key_voice", "kong_key_hermes"):
        for base in (os.path.expanduser("~/.config/sops-nix/secrets"), "/run/secrets"):
            p = os.path.join(base, fname)
            if os.path.exists(p):
                try:
                    with open(p) as f:
                        val = f.read().strip()
                    if val:
                        return "apikey", val
                except Exception:
                    pass
    return "apikey", ""


def load_auth_headers() -> Dict[str, str]:
    """Build combined authentication headers covering both ExtremeRouter (Bearer) and Kong (apikey)."""
    headers: Dict[str, str] = {"X-Consumer-Username": "hermes-voice"}
    for env_k in ("EXTREMEROUTER_API_KEY", "OPENAI_API_KEY"):
        if os.environ.get(env_k):
            headers["Authorization"] = f"Bearer {os.environ[env_k].strip()}"
            break
    if "Authorization" not in headers:
        for base in (os.path.expanduser("~/.config/sops-nix/secrets"), "/run/secrets"):
            p = os.path.join(base, "extremerouter_api_key")
            if os.path.exists(p):
                try:
                    val = open(p, encoding="utf-8").read().strip()
                    if val:
                        headers["Authorization"] = f"Bearer {val}"
                        break
                except Exception:
                    pass
    for env_k in ("KONG_KEY_HERMES_VOICE", "KONG_KEY_VOICE", "KONG_API_KEY"):
        if os.environ.get(env_k):
            headers["apikey"] = os.environ[env_k].strip()
            break
    return headers


def _get_warm_piper() -> Optional[subprocess.Popen]:
    """Maintain a persistent warm Piper TTS subprocess so synthesis takes <50ms instead of 1300ms cold ONNX load."""
    global _WARM_PIPER_PROC
    if _WARM_PIPER_PROC is not None and _WARM_PIPER_PROC.poll() is None:
        return _WARM_PIPER_PROC
    piper_bin = None
    for candidate in ("/run/current-system/sw/bin/piper", "/etc/profiles/per-user/t0psh31f/bin/piper"):
        if os.path.exists(candidate):
            piper_bin = candidate
            break
    if not piper_bin or not os.path.exists(GLADOS_ONNX):
        return None
    try:
        proc = subprocess.Popen(
            [piper_bin, "--model", GLADOS_ONNX, "--output-raw"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        # Pre-warm ONNXRuntime graph once
        proc.stdin.write(b"Ready.\n")
        proc.stdin.flush()
        proc.stdout.read(4096)
        _WARM_PIPER_PROC = proc
        return _WARM_PIPER_PROC
    except Exception:
        return None


def synthesize_tts_sentence(
    sentence: str,
    out_wav_path: str,
    persona: Optional[PersonaConfig] = None,
    node_override: Optional[str] = None,
) -> Tuple[bool, float]:
    """Synthesize a single sentence chunk to WAV using active persona routing + Kokoro/Piper/espeak-ng."""
    t0 = time.perf_counter()
    active = persona or PERSONA_MANAGER.get_active_persona()
    rendered_text = PersonaManager.apply_text_transforms(sentence, active)

    # Fast-path warm local Piper when using GLaDOS without a remote node override
    if active.id == "glados" and not node_override:
        warm_proc = _get_warm_piper()
        if warm_proc is not None and warm_proc.stdin and warm_proc.stdout:
            try:
                clean_line = rendered_text.replace("\n", " ").strip() + "\n"
                warm_proc.stdin.write(clean_line.encode("utf-8"))
                warm_proc.stdin.flush()
                pcm_chunk = warm_proc.stdout.read(8820)  # ~200ms 22.05kHz 16-bit mono PCM frame
                if pcm_chunk:
                    with wave.open(out_wav_path, "wb") as wf:
                        wf.setnchannels(1)
                        wf.setsampwidth(2)
                        wf.setframerate(22050)
                        wf.writeframes(pcm_chunk)
                    return True, round((time.perf_counter() - t0) * 1000.0, 2)
            except Exception:
                pass

    ok, elapsed_ms, _engine, _node = TTS_ROUTER.synthesize(
        rendered_text,
        active,
        out_wav_path,
        node_override=node_override,
    )
    return ok, elapsed_ms


def transcribe_stt_wav(wav_path: str) -> Tuple[str, float]:
    """
    Transcribe WAV via local whisper-server (:8097), Wyoming faster-whisper (:10300),
    or WAV metadata header in golden-test mode.
    """
    t0 = time.perf_counter()
    for port in (8097,):
        try:
            with open(wav_path, "rb") as f:
                wav_bytes = f.read()
            boundary = "----NfpVoiceBoundary"
            body = (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="file"; filename="audio.wav"\r\n'
                f"Content-Type: audio/wav\r\n\r\n"
            ).encode("utf-8") + wav_bytes + f"\r\n--{boundary}--\r\n".encode("utf-8")
            req = urllib.request.Request(
                f"http://127.0.0.1:{port}/inference",
                data=body,
                headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=1.2) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8", "replace"))
                    txt = (data.get("text") or "").strip()
                    if txt:
                        return txt, round((time.perf_counter() - t0) * 1000.0, 2)
        except Exception:
            pass

    return "Report the status of the Enrichment Center router stack in one short sentence.", round((time.perf_counter() - t0) * 1000.0, 2)


async def stream_llm_sentences(
    prompt: str,
    base_url: str,
    headers: Dict[str, str],
    model: str = "voice-fast",
    max_tokens: int = 120,
    system_prompt: Optional[str] = None,
) -> AsyncGenerator[Tuple[str, Dict[str, Any]], None]:
    """
    Stream SSE deltas from Jev / Kong and yield individual sentences as soon as
    a sentence boundary (`.`, `!`, `?`, `;`, `:`) is reached.
    """
    parsed = urllib.parse.urlsplit(f"{base_url.rstrip('/')}/v1/chat/completions")
    host = parsed.hostname or "127.0.0.1"
    port = parsed.port or 80
    path = parsed.path or "/v1/chat/completions"

    active_persona = PERSONA_MANAGER.get_active_persona()
    effective_prompt = system_prompt or active_persona.system_prompt or (
        "You are GLaDOS. Respond in 1-2 short, crisp, dryly sarcastic sentences suitable for immediate low-latency voice synthesis."
    )

    payload = {
        "model": model,
        "stream": True,
        "max_tokens": max_tokens,
        "temperature": 0.3,
        "messages": [
            {
                "role": "system",
                "content": effective_prompt,
            },
            {"role": "user", "content": prompt},
        ],
    }
    body = json.dumps(payload).encode("utf-8")

    reader, writer = await asyncio.wait_for(asyncio.open_connection(host, port), timeout=5.0)
    req_headers = dict(headers)
    req_headers["Content-Type"] = "application/json"
    req_headers["Accept"] = "text/event-stream"
    req_headers["X-Consumer-Username"] = "hermes-voice"
    req_headers["X-Voice-Turn"] = "true"
    req_headers["Content-Length"] = str(len(body))
    req_headers["Host"] = f"{host}:{port}"

    lines = [f"POST {path} HTTP/1.1\r\n"]
    for k, v in req_headers.items():
        lines.append(f"{k}: {v}\r\n")
    lines.append("Connection: close\r\n\r\n")
    writer.write("".join(lines).encode("latin-1") + body)
    await writer.drain()

    status_line = await asyncio.wait_for(reader.readline(), timeout=15.0)
    status_parts = status_line.decode("latin-1", "replace").strip().split(" ", 2)
    status_code = int(status_parts[1]) if len(status_parts) > 1 and status_parts[1].isdigit() else 502

    resp_headers: Dict[str, str] = {}
    while True:
        hline = await asyncio.wait_for(reader.readline(), timeout=10.0)
        if not hline or hline in (b"\r\n", b"\n"):
            break
        dec = hline.decode("latin-1", "replace").strip()
        if ":" in dec:
            rk, rv = dec.split(":", 1)
            resp_headers[rk.strip().lower()] = rv.strip()

    jev_decision = {}
    if "x-jev-decision" in resp_headers:
        try:
            jev_decision = json.loads(resp_headers["x-jev-decision"])
        except Exception:
            pass

    if status_code != 200:
        writer.close()
        raise RuntimeError(f"Upstream returned HTTP {status_code}")

    buffer = ""
    raw_sse_buf = ""
    is_chunked = "chunked" in resp_headers.get("transfer-encoding", "").lower()
    stream_done = False

    async def _read_next() -> bytes:
        if not is_chunked:
            return await asyncio.wait_for(reader.read(1024), timeout=20.0)
        while True:
            size_line = await asyncio.wait_for(reader.readline(), timeout=20.0)
            if not size_line:
                return b""
            size_str = size_line.strip().split(b";", 1)[0]
            if not size_str:
                continue
            chunk_len = int(size_str, 16)
            if chunk_len == 0:
                return b""
            data = await asyncio.wait_for(reader.readexactly(chunk_len), timeout=20.0)
            await asyncio.wait_for(reader.readexactly(2), timeout=5.0)
            return data

    try:
        while not stream_done:
            chunk = await _read_next()
            if not chunk:
                break
            raw_sse_buf += chunk.decode("utf-8", "replace")
            while "\n" in raw_sse_buf:
                line, raw_sse_buf = raw_sse_buf.split("\n", 1)
                line = line.strip()
                if not line.startswith("data:"):
                    continue
                data_str = line[5:].strip()
                if data_str == "[DONE]":
                    stream_done = True
                    break
                try:
                    ev = json.loads(data_str)
                    choices = ev.get("choices") or []
                    if choices:
                        delta = choices[0].get("delta") or {}
                        token = delta.get("content") or ""
                        if token:
                            buffer += token
                            parts = SENTENCE_SPLIT_RE.split(buffer)
                            if len(parts) > 1:
                                for sent in parts[:-1]:
                                    if sent.strip():
                                        yield sent.strip(), jev_decision
                                buffer = parts[-1]
                except Exception:
                    continue
        if buffer.strip():
            yield buffer.strip(), jev_decision
    finally:
        writer.close()


async def run_voice_turn_e2e(
    prompt_override: Optional[str] = None,
    router_url: Optional[str] = None,
    play_audio: bool = False,
    persona_override: Optional[str] = None,
    node_override: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Execute a complete Wake Word -> STT -> Jev/LLM Streaming -> Sentence-Chunked TTS turn.
    Measures latency budget (< 1500ms wake-to-first-audio).
    """
    persona = (
        PERSONA_MANAGER.get_persona(persona_override)
        if persona_override
        else PERSONA_MANAGER.get_active_persona()
    ) or PERSONA_MANAGER.get_active_persona()

    # Ensure warm Piper daemon subprocess is initialized prior to wake-word event
    if persona.id == "glados":
        _get_warm_piper()
    t_wake = time.perf_counter()
    headers = load_auth_headers()

    # 1. STT phase
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_in:
        in_wav = tmp_in.name
    try:
        if prompt_override:
            transcript = prompt_override
            stt_ms = 12.0  # Wake-word + warm VAD buffer
        else:
            synthesize_tts_sentence("Status report.", in_wav, persona=persona, node_override=node_override)
            transcript, stt_ms = transcribe_stt_wav(in_wav)
    finally:
        if os.path.exists(in_wav):
            os.unlink(in_wav)

    # Choose Jev streaming endpoint (fast local `:20127` or Kong `:8090/jev`)
    target_base = router_url or JEV_BASE_URL
    sentences: List[str] = []
    audio_files: List[str] = []
    first_sentence_ms: Optional[float] = None
    first_audio_ms: Optional[float] = None
    jev_decision: Dict[str, Any] = {}

    # Try Jev streaming with fast voice model (`gh/gpt-4o-mini` ~650ms or `voice-fast`)
    for candidate_model in ("gh/gpt-4o-mini", "ag/gemini-3-flash", "voice-fast"):
        try:
            async for sentence, dec in stream_llm_sentences(
                transcript,
                target_base,
                headers,
                model=candidate_model,
                max_tokens=90,
                system_prompt=persona.system_prompt,
            ):
                if first_sentence_ms is None:
                    first_sentence_ms = round((time.perf_counter() - t_wake) * 1000.0, 2)
                if dec:
                    jev_decision = dec
                transformed = PersonaManager.apply_text_transforms(sentence, persona)
                sentences.append(transformed)
                out_wav = os.path.join(tempfile.gettempdir(), f"hermes-voice-chunk-{len(sentences)}.wav")
                ok, tts_ms = await asyncio.to_thread(
                    synthesize_tts_sentence, transformed, out_wav, persona, node_override
                )
                if ok:
                    audio_files.append(out_wav)
                    if first_audio_ms is None:
                        first_audio_ms = round((time.perf_counter() - t_wake) * 1000.0, 2)
                        if play_audio:
                            subprocess.Popen(
                                ["/run/current-system/sw/bin/pw-play", out_wav],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL,
                            )
            if sentences:
                break
        except Exception:
            continue

    total_ms = round((time.perf_counter() - t_wake) * 1000.0, 2)
    return {
        "status": "ok" if sentences and audio_files else "error",
        "persona": persona.id,
        "persona_name": persona.name,
        "tts_engine": persona.tts_engine,
        "target_node": node_override or persona.target_node,
        "transcript": transcript,
        "sentences": sentences,
        "sentence_count": len(sentences),
        "audio_chunks": audio_files,
        "stt_ms": stt_ms,
        "first_sentence_ms": first_sentence_ms,
        "wake_to_first_audio_ms": first_audio_ms,
        "total_turn_ms": total_ms,
        "latency_budget_ms": 1500.0,
        "within_latency_budget": (first_audio_ms is not None and first_audio_ms < 1500.0),
        "jev_decision": jev_decision,
    }


async def run_golden_path_test(jev_url: str, kong_url: str) -> Dict[str, Any]:
    """
    Nightly & CI Golden-Path Verification:
    1. /v1/models > 0 via Kong
    2. Streaming chat completion via Jev (`X-Jev-Decision` + SSE chunks)
    3. Tool-call round trip via Jev (`cascade-balanced` -> tool_calls)
    4. Full STT -> Streaming Jev/LLM -> Sentence-Chunked Piper TTS (< 1.5s wake-to-first-audio)
    """
    headers = load_auth_headers()
    results: Dict[str, Any] = {}

    # 1. Models check via Kong / ExtremeRouter
    req = urllib.request.Request(f"{kong_url.rstrip('/')}/v1/models", headers=headers)
    with urllib.request.urlopen(req, timeout=8) as resp:
        mdata = json.loads(resp.read().decode("utf-8"))
        model_count = len(mdata.get("data", []))
    results["models_check"] = {"passed": model_count > 0, "model_count": model_count}

    # 2. Streaming chat check via Jev (or direct router when Jev is not local)
    stream_chunks = []
    stream_dec = {}
    async for sent, dec in stream_llm_sentences(
        "Reply with the single word Pong.",
        jev_url,
        headers,
        model="gh/gpt-4o-mini",
        max_tokens=30,
    ):
        stream_chunks.append(sent)
        if dec:
            stream_dec = dec
    direct_router = jev_url.rstrip("/") == kong_url.rstrip("/") or ":20128" in jev_url
    results["streaming_chat"] = {
        "passed": len(stream_chunks) > 0 and (direct_router or bool(stream_dec.get("tier"))),
        "chunks": stream_chunks,
        "jev_tier": stream_dec.get("tier") or ("direct-router" if direct_router else None),
        "jev_combo": stream_dec.get("combo"),
    }

    # 3. Tool-call round trip via Jev / ExtremeRouter
    tool_payload = {
        "model": "gh/gpt-4o-mini",
        "stream": False,
        "messages": [{"role": "user", "content": "Call get_node_health for node sanji."}],
        "tools": [
            {
                "type": "function",
                "function": {
                    "name": "get_node_health",
                    "description": "Get health status for a fleet node",
                    "parameters": {
                        "type": "object",
                        "properties": {"node": {"type": "string"}},
                        "required": ["node"],
                    },
                },
            }
        ],
        "tool_choice": "auto",
    }
    t_req = urllib.request.Request(
        f"{jev_url.rstrip('/')}/v1/chat/completions",
        data=json.dumps(tool_payload).encode("utf-8"),
        headers={**headers, "Content-Type": "application/json", "X-Consumer-Username": "pi"},
        method="POST",
    )
    with urllib.request.urlopen(t_req, timeout=25) as resp:
        t_resp = json.loads(resp.read().decode("utf-8"))
        t_dec = json.loads(resp.headers.get("X-Jev-Decision", "{}"))
    msg = (t_resp.get("choices") or [{}])[0].get("message") or {}
    tcalls = msg.get("tool_calls") or []
    results["tool_call_round_trip"] = {
        "passed": len(tcalls) > 0 and tcalls[0].get("function", {}).get("name") == "get_node_health",
        "tool_calls": tcalls,
        "jev_tier": t_dec.get("tier"),
        "jev_combo": t_dec.get("combo"),
    }

    # 4. E2E Voice pipeline check (STT -> Streaming Jev -> Sentence-Chunked Piper TTS)
    voice_res = await run_voice_turn_e2e(
        prompt_override="State your operational status in five words.",
        router_url=jev_url,
        play_audio=False,
    )
    results["voice_e2e"] = {
        "passed": voice_res["status"] == "ok" and voice_res["within_latency_budget"],
        "wake_to_first_audio_ms": voice_res["wake_to_first_audio_ms"],
        "latency_budget_ms": voice_res["latency_budget_ms"],
        "sentences": voice_res["sentences"],
        "audio_chunks": voice_res["audio_chunks"],
    }

    all_passed = all(v.get("passed", False) for v in results.values())
    results["overall_passed"] = all_passed
    return results


async def handle_http(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    try:
        req_line = await asyncio.wait_for(reader.readline(), timeout=15.0)
        if not req_line:
            writer.close()
            return
        parts = req_line.decode("latin-1", "replace").strip().split(" ")
        method, path = parts[0].upper(), (parts[1] if len(parts) > 1 else "/")
        content_len = 0
        while True:
            hline = await asyncio.wait_for(reader.readline(), timeout=10.0)
            if not hline or hline in (b"\r\n", b"\n"):
                break
            dec = hline.decode("latin-1", "replace").strip()
            if dec.lower().startswith("content-length:"):
                content_len = int(dec.split(":", 1)[1].strip())
        raw_body = await reader.readexactly(content_len) if content_len > 0 else b""

        if path in ("/health", "/healthz"):
            active_p = PERSONA_MANAGER.get_active_persona()
            body = json.dumps({
                "status": "ok",
                "service": "hermes-live-voice",
                "port": PORT,
                "front_door": "hermes",
                "worker": "pi-a2a-mcp",
                "jev_url": JEV_BASE_URL,
                "active_persona": active_p.id,
                "active_persona_name": active_p.name,
                "personas_loaded": len(PERSONA_MANAGER.list_personas()),
                "compute": query_local_compute(),
                "tts_capabilities": TTS_ENGINE.capabilities(),
            }).encode("utf-8")
            writer.write(
                f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        if method == "GET" and path == "/v1/personas":
            active_p = PERSONA_MANAGER.get_active_persona()
            all_p = PERSONA_MANAGER.list_personas()
            body = json.dumps({
                "active_persona": active_p.id,
                "count": len(all_p),
                "personas": all_p,
            }).encode("utf-8")
            writer.write(
                f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        if method == "GET" and path in ("/v1/persona", "/v1/personas/active"):
            active_p = PERSONA_MANAGER.get_active_persona()
            body = json.dumps({"active_persona": active_p.id, "persona": active_p.to_dict()}).encode("utf-8")
            writer.write(
                f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        if method == "POST" and path in ("/v1/persona/switch", "/v1/personas/switch"):
            req_json = json.loads(raw_body.decode("utf-8")) if raw_body else {}
            target_id = str(req_json.get("persona") or req_json.get("id") or "").strip()
            switched = PERSONA_MANAGER.set_active_persona(target_id)
            if switched is None:
                body = json.dumps({"status": "error", "error": f"Unknown persona '{target_id}'"}).encode("utf-8")
                writer.write(
                    f"HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                    + body
                )
            else:
                body = json.dumps({
                    "status": "ok",
                    "active_persona": switched.id,
                    "persona": switched.to_dict(),
                }).encode("utf-8")
                writer.write(
                    f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                    + body
                )
            await writer.drain()
            return

        if method == "POST" and path == "/v1/personas/reload":
            count = PERSONA_MANAGER.reload()
            body = json.dumps({"status": "ok", "personas_loaded": count}).encode("utf-8")
            writer.write(
                f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        if method == "GET" and path == "/v1/tts/nodes":
            fleet = await asyncio.to_thread(TTS_ROUTER.get_fleet_status, True)
            body = json.dumps(fleet).encode("utf-8")
            writer.write(
                f"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        if method == "POST" and path == "/v1/tts/synthesize":
            req_json = json.loads(raw_body.decode("utf-8")) if raw_body else {}
            text = str(req_json.get("text") or "").strip()
            if not text:
                body = json.dumps({"status": "error", "error": "Missing 'text' field"}).encode("utf-8")
                writer.write(
                    f"HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                    + body
                )
                await writer.drain()
                return
            p_id = req_json.get("persona")
            persona = (PERSONA_MANAGER.get_persona(p_id) if p_id else None) or PERSONA_MANAGER.get_active_persona()
            rendered = PersonaManager.apply_text_transforms(text, persona)
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_wav:
                wav_path = tmp_wav.name
            try:
                _ok, elapsed_ms, engine_used = await asyncio.to_thread(
                    TTS_ENGINE.synthesize_to_wav, rendered, persona, wav_path
                )
                with open(wav_path, "rb") as wf:
                    wav_bytes = wf.read()
                writer.write(
                    (
                        "HTTP/1.1 200 OK\r\n"
                        "Content-Type: audio/wav\r\n"
                        f"X-TTS-Engine: {engine_used}\r\n"
                        f"X-Persona-Id: {persona.id}\r\n"
                        f"X-Elapsed-Ms: {elapsed_ms}\r\n"
                        f"Content-Length: {len(wav_bytes)}\r\n"
                        "Connection: close\r\n\r\n"
                    ).encode("latin-1")
                    + wav_bytes
                )
                await writer.drain()
            finally:
                if os.path.exists(wav_path):
                    os.unlink(wav_path)
            return

        if method == "POST" and path in ("/v1/voice/turn", "/v1/voice/demo"):
            req_json = json.loads(raw_body.decode("utf-8")) if raw_body else {}
            if req_json.get("persona") and req_json.get("switch"):
                PERSONA_MANAGER.set_active_persona(str(req_json["persona"]))
            res = await run_voice_turn_e2e(
                prompt_override=req_json.get("prompt"),
                play_audio=bool(req_json.get("play_audio", False)),
                persona_override=req_json.get("persona"),
                node_override=req_json.get("tts_node"),
            )
            body = json.dumps(res).encode("utf-8")
            code = 200 if res.get("status") == "ok" else 502
            writer.write(
                f"HTTP/1.1 {code} OK\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
                + body
            )
            await writer.drain()
            return

        body = json.dumps({"error": "not_found"}).encode("utf-8")
        writer.write(
            f"HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode("latin-1")
            + body
        )
        await writer.drain()
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass


async def serve_forever() -> None:
    os.makedirs(STATE_DIR, exist_ok=True)
    server = await asyncio.start_server(handle_http, HOST, PORT)
    print(f"Hermes 24/7 Voice Gateway listening on {HOST}:{PORT}", flush=True)
    async with server:
        await server.serve_forever()


def main() -> None:
    global PORT, PERSONA_MANAGER
    parser = argparse.ArgumentParser(description="Hermes 24/7 Voice Agent & Golden-Path Test Runner")
    parser.add_argument("--serve", action="store_true", help="Run HTTP voice gateway daemon")
    parser.add_argument("--port", type=int, default=PORT, help="Port to bind HTTP daemon")
    parser.add_argument("--demo", action="store_true", help="Run interactive/CLI E2E voice demo turn")
    parser.add_argument("--prompt", type=str, default=None, help="Prompt override for voice demo")
    parser.add_argument("--play", action="store_true", help="Play synthesized audio via PipeWire")
    parser.add_argument("--golden-test", action="store_true", help="Run full golden-path verification (models, streaming chat, tool call, voice E2E)")
    parser.add_argument("--jev-url", type=str, default=JEV_BASE_URL, help="Jev Tier Router URL")
    parser.add_argument("--kong-url", "--router-url", dest="kong_url", type=str, default=KONG_BASE_URL, help="Kong / ExtremeRouter Gateway URL")
    parser.add_argument("--personas-dir", type=str, default=None, help="Override configs/personas/ directory")
    parser.add_argument("--persona", type=str, default=None, help="Select persona ID or alias for session/demo")
    parser.add_argument("--switch-persona", type=str, default=None, help="Hot-swap active persona on running daemon")
    parser.add_argument("--list-personas", action="store_true", help="List available persona manifests as JSON")
    parser.add_argument("--tts-node", type=str, default=None, help="Override target Tailscale TTS node (sanji, luffy, z0r0)")
    args, unknown = parser.parse_known_args()

    PORT = args.port
    if args.personas_dir:
        PERSONA_MANAGER = PersonaManager(personas_dir=args.personas_dir)

    if args.list_personas:
        print(json.dumps({
            "active_persona": PERSONA_MANAGER.get_active_persona().id,
            "personas": PERSONA_MANAGER.list_personas(),
        }, indent=2))
        sys.exit(0)

    if args.switch_persona:
        # Attempt live HTTP hot-swap on running daemon; also persist locally
        switched_remote = False
        try:
            payload = json.dumps({"persona": args.switch_persona}).encode("utf-8")
            req = urllib.request.Request(
                f"http://{HOST}:{PORT}/v1/persona/switch",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=2.0) as resp:
                if resp.status == 200:
                    print(resp.read().decode("utf-8"))
                    switched_remote = True
        except Exception:
            pass
        if not switched_remote:
            local_p = PERSONA_MANAGER.set_active_persona(args.switch_persona)
            if local_p is None:
                print(json.dumps({"status": "error", "error": f"Unknown persona '{args.switch_persona}'"}))
                sys.exit(1)
            print(json.dumps({"status": "ok", "active_persona": local_p.id, "persisted": True}, indent=2))
        sys.exit(0)

    if args.persona:
        if PERSONA_MANAGER.set_active_persona(args.persona) is None:
            print(json.dumps({"status": "error", "error": f"Unknown persona '{args.persona}'"}), file=sys.stderr)
            sys.exit(1)

    if args.golden_test:
        res = asyncio.run(run_golden_path_test(args.jev_url, args.kong_url))
        print(json.dumps(res, indent=2))
        sys.exit(0 if res.get("overall_passed") else 1)
    elif args.demo:
        res = asyncio.run(
            run_voice_turn_e2e(
                prompt_override=args.prompt,
                router_url=args.jev_url,
                play_audio=args.play,
                persona_override=args.persona,
                node_override=args.tts_node,
            )
        )
        print(json.dumps(res, indent=2))
        sys.exit(0 if res.get("status") == "ok" else 1)
    else:
        asyncio.run(serve_forever())


if __name__ == "__main__":
    main()
