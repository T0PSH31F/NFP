#!/usr/bin/env python3
"""
Distributed Tailscale TTS Routing Layer for NFP Fleet (sanji, luffy, z0r0).

Checks Tailscale node availability and compute/VRAM headroom, then routes
synthesis either locally or via HTTP RPC to the optimal fleet node.
"""

from __future__ import annotations

import json
import os
import shutil
import socket
import subprocess
import time
import urllib.request
from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional, Tuple

from kokoro_tts import KokoroTTSEngine
from persona_manager import PersonaConfig

DEFAULT_TTS_PORT = int(os.environ.get("HERMES_LIVE_PORT", "8880"))
MIN_GPU_VRAM_MB = int(os.environ.get("NFP_TTS_MIN_VRAM_MB", "600"))
PROBE_TIMEOUT_SEC = float(os.environ.get("NFP_TTS_PROBE_TIMEOUT", "0.45"))
RPC_TIMEOUT_SEC = float(os.environ.get("NFP_TTS_RPC_TIMEOUT", "4.0"))
HEALTH_CACHE_TTL_SEC = 5.0


@dataclass
class FleetNodeSpec:
    name: str
    tailscale_ip: str
    port: int
    role: str
    total_vram_mb: int
    accelerator: str


FLEET_NODES: Dict[str, FleetNodeSpec] = {
    "sanji": FleetNodeSpec(
        name="sanji",
        tailscale_ip=os.environ.get("NFP_TS_SANJI", "100.64.0.6"),
        port=int(os.environ.get("NFP_TTS_PORT_SANJI", str(DEFAULT_TTS_PORT))),
        role="coordinator+ollama",
        total_vram_mb=6144,
        accelerator="cuda_rtx_1000_ada",
    ),
    "luffy": FleetNodeSpec(
        name="luffy",
        tailscale_ip=os.environ.get("NFP_TS_LUFFY", "100.64.0.3"),
        port=int(os.environ.get("NFP_TTS_PORT_LUFFY", str(DEFAULT_TTS_PORT))),
        role="tts_worker",
        total_vram_mb=2048,
        accelerator="cuda_quadro_p620",
    ),
    "z0r0": FleetNodeSpec(
        name="z0r0",
        tailscale_ip=os.environ.get("NFP_TS_Z0R0", "100.64.0.1"),
        port=int(os.environ.get("NFP_TTS_PORT_Z0R0", str(DEFAULT_TTS_PORT))),
        role="cpu_fallback",
        total_vram_mb=0,
        accelerator="cpu_iris_xe",
    ),
}


def query_local_compute() -> Dict[str, Any]:
    """Inspect local GPU VRAM (via nvidia-smi) and CPU load average."""
    free_vram_mb: Optional[int] = None
    total_vram_mb: Optional[int] = None
    nvidia_smi = shutil.which("nvidia-smi")
    if nvidia_smi:
        try:
            out = subprocess.check_output(
                [nvidia_smi, "--query-gpu=memory.free,memory.total", "--format=csv,noheader,nounits"],
                text=True,
                timeout=1.5,
            ).strip()
            if out:
                parts = [p.strip() for p in out.splitlines()[0].split(",")]
                if len(parts) == 2:
                    free_vram_mb = int(float(parts[0]))
                    total_vram_mb = int(float(parts[1]))
        except Exception:
            pass

    load_1m = 0.0
    try:
        load_1m = round(os.getloadavg()[0], 2)
    except Exception:
        pass

    return {
        "hostname": socket.gethostname().lower(),
        "free_vram_mb": free_vram_mb,
        "total_vram_mb": total_vram_mb,
        "cpu_load_1m": load_1m,
    }


class DistributedTTSRouter:
    """
    Routes TTS synthesis across Tailscale nodes (sanji, luffy, z0r0)
    based on persona target_node, VRAM headroom, and node reachability.
    """

    def __init__(self, engine: Optional[KokoroTTSEngine] = None) -> None:
        self.engine = engine or KokoroTTSEngine()
        self.local_hostname = socket.gethostname().lower()
        self._health_cache: Dict[str, Tuple[float, Dict[str, Any]]] = {}

    def _is_local_node(self, node_name: str) -> bool:
        return self.local_hostname == node_name.lower() or self.local_hostname.startswith(f"{node_name.lower()}.")

    def probe_node(self, node_name: str, force: bool = False) -> Dict[str, Any]:
        """Probe a Tailscale node for TTS availability and compute/VRAM telemetry."""
        spec = FLEET_NODES.get(node_name)
        if spec is None:
            return {"node": node_name, "reachable": False, "error": "unknown_node"}

        now = time.monotonic()
        if not force and node_name in self._health_cache:
            ts, cached = self._health_cache[node_name]
            if now - ts < HEALTH_CACHE_TTL_SEC:
                return cached

        if self._is_local_node(node_name):
            comp = query_local_compute()
            caps = self.engine.capabilities()
            res = {
                **asdict(spec),
                "local": True,
                "reachable": True,
                "free_vram_mb": comp["free_vram_mb"],
                "cpu_load_1m": comp["cpu_load_1m"],
                "kokoro_ready": caps["kokoro_ready"],
                "vram_ok": (comp["free_vram_mb"] is None) or (comp["free_vram_mb"] >= MIN_GPU_VRAM_MB),
            }
            self._health_cache[node_name] = (now, res)
            return res

        url = f"http://{spec.tailscale_ip}:{spec.port}/health"
        try:
            req = urllib.request.Request(url, method="GET")
            with urllib.request.urlopen(req, timeout=PROBE_TIMEOUT_SEC) as resp:
                data = json.loads(resp.read().decode("utf-8", "replace"))
            comp = data.get("compute") or {}
            free_vram = comp.get("free_vram_mb")
            res = {
                **asdict(spec),
                "local": False,
                "reachable": resp.status == 200,
                "free_vram_mb": free_vram,
                "cpu_load_1m": comp.get("cpu_load_1m"),
                "kokoro_ready": bool((data.get("tts_capabilities") or {}).get("kokoro_ready", False)),
                "vram_ok": (free_vram is None) or (int(free_vram) >= MIN_GPU_VRAM_MB),
            }
        except Exception as exc:
            res = {
                **asdict(spec),
                "local": False,
                "reachable": False,
                "free_vram_mb": None,
                "cpu_load_1m": None,
                "kokoro_ready": False,
                "vram_ok": False,
                "error": str(exc),
            }

        self._health_cache[node_name] = (now, res)
        return res

    def get_fleet_status(self, force: bool = False) -> Dict[str, Any]:
        """Return health and compute/VRAM telemetry for all fleet nodes."""
        nodes = {name: self.probe_node(name, force=force) for name in ("sanji", "luffy", "z0r0")}
        return {
            "local_host": self.local_hostname,
            "min_vram_mb": MIN_GPU_VRAM_MB,
            "nodes": nodes,
        }

    def select_node(self, persona: PersonaConfig, node_override: Optional[str] = None) -> str:
        """
        Choose the optimal fleet node for TTS rendering.
        Priority: explicit override -> persona.target_node (if healthy & VRAM ok) -> luffy -> z0r0 -> local.
        """
        if node_override and node_override in FLEET_NODES:
            status = self.probe_node(node_override)
            if status.get("reachable"):
                return node_override

        candidates: List[str] = []
        if persona.target_node in FLEET_NODES:
            candidates.append(persona.target_node)
        for fallback in ("luffy", "z0r0", "sanji"):
            if fallback not in candidates:
                candidates.append(fallback)

        # Pass 1: reachable + VRAM headroom ok
        for cand in candidates:
            st = self.probe_node(cand)
            if st.get("reachable") and st.get("vram_ok", True):
                return cand

        # Pass 2: any reachable node
        for cand in candidates:
            if self.probe_node(cand).get("reachable"):
                return cand

        return self.local_hostname

    def synthesize(
        self,
        text: str,
        persona: PersonaConfig,
        out_wav_path: str,
        node_override: Optional[str] = None,
    ) -> Tuple[bool, float, str, str]:
        """
        Route synthesis to the best Tailscale node and write WAV to `out_wav_path`.
        Returns (success, elapsed_ms, engine_used, executed_node).
        """
        selected = self.select_node(persona, node_override=node_override)

        if selected in FLEET_NODES and not self._is_local_node(selected):
            spec = FLEET_NODES[selected]
            t0 = time.perf_counter()
            try:
                payload = json.dumps({"text": text, "persona": persona.id}).encode("utf-8")
                req = urllib.request.Request(
                    f"http://{spec.tailscale_ip}:{spec.port}/v1/tts/synthesize",
                    data=payload,
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=RPC_TIMEOUT_SEC) as resp:
                    wav_bytes = resp.read()
                if resp.status == 200 and len(wav_bytes) > 44:
                    with open(out_wav_path, "wb") as wf:
                        wf.write(wav_bytes)
                    elapsed_ms = round((time.perf_counter() - t0) * 1000.0, 2)
                    engine = resp.headers.get("X-TTS-Engine", "remote_kokoro")
                    return True, elapsed_ms, engine, selected
            except Exception:
                # Transparent fallback to local execution
                pass

        ok, elapsed_ms, engine = self.engine.synthesize_to_wav(text, persona, out_wav_path)
        return ok, elapsed_ms, engine, self.local_hostname
