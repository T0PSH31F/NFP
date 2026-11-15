#!/usr/bin/env python3
"""
Modular Persona Manager for NFP / GLaDOS Voice Stack.

Dynamically loads declarative JSON persona manifests from `configs/personas/`
and manages hot-swappable active personality state in memory + SQLite.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import threading
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

DEFAULT_STATE_DB = Path(
    os.environ.get(
        "NFP_PERSONA_STATE_DB",
        str(Path.home() / ".local/share/pi-durable/state.sqlite"),
    )
)
DEFAULT_PERSONA_ID = os.environ.get("NFP_DEFAULT_PERSONA", "glados")


def resolve_personas_dir(explicit_dir: Optional[str | Path] = None) -> Path:
    """Resolve the declarative `configs/personas/` directory."""
    candidates: List[Path] = []
    if explicit_dir:
        candidates.append(Path(explicit_dir))
    if os.environ.get("NFP_PERSONAS_DIR"):
        candidates.append(Path(os.environ["NFP_PERSONAS_DIR"]))
    here = Path(__file__).resolve().parent
    candidates.extend(
        [
            here / "configs" / "personas",
            Path.cwd() / "configs" / "personas",
            Path.cwd() / "layers" / "70-agents" / "72-voice" / "configs" / "personas",
        ]
    )
    for c in candidates:
        if c.is_dir():
            return c
    return here / "configs" / "personas"


def _norm_key(value: str) -> str:
    return re.sub(r"[\s\-_]+", "_", value.strip().lower()).strip("_")


@dataclass
class PersonaConfig:
    """Declarative persona manifest loaded from `configs/personas/<id>.json`."""

    id: str
    name: str
    universe: str = "Unknown"
    system_prompt: str = ""
    tts_engine: str = "kokoro"
    voice_model: str = "en_us_female_bright"
    kokoro_voice: str = "af_alloy"
    style_instructions: str = ""
    personality_notes: str = ""
    reference_wav: str = ""
    target_node: str = "luffy"
    speed: float = 1.0
    pitch_shift: float = 0.0
    cadence: str = "normal"
    audio_filter: str = "none"
    suffix_injection: str = ""
    aliases: List[str] = field(default_factory=list)
    sample_phrase: str = ""
    manifest_path: str = ""

    @classmethod
    def from_dict(cls, data: Dict[str, Any], manifest_path: str = "") -> "PersonaConfig":
        return cls(
            id=str(data.get("id") or Path(manifest_path).stem),
            name=str(data.get("name") or data.get("id") or "Unknown"),
            universe=str(data.get("universe") or "Unknown"),
            system_prompt=str(data.get("system_prompt") or ""),
            tts_engine=str(data.get("tts_engine") or data.get("engine") or "kokoro"),
            voice_model=str(data.get("voice_model") or data.get("model") or "en_us_female_bright"),
            kokoro_voice=str(data.get("kokoro_voice") or "af_alloy"),
            style_instructions=str(data.get("style_instructions") or ""),
            personality_notes=str(data.get("personality_notes") or ""),
            reference_wav=str(data.get("reference_wav") or ""),
            target_node=str(data.get("target_node") or "luffy"),
            speed=float(data.get("speed", 1.0)),
            pitch_shift=float(data.get("pitch_shift", data.get("pitch", 0.0))),
            cadence=str(data.get("cadence") or "normal"),
            audio_filter=str(data.get("audio_filter") or "none"),
            suffix_injection=str(data.get("suffix_injection") or ""),
            aliases=[str(a) for a in (data.get("aliases") or [])],
            sample_phrase=str(data.get("sample_phrase") or ""),
            manifest_path=manifest_path,
        )

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class PersonaManager:
    """
    Loads and manages hot-swappable AI personalities and voice profiles.
    """

    def __init__(
        self,
        personas_dir: Optional[str | Path] = None,
        state_db: Optional[str | Path] = None,
        default_persona: str = DEFAULT_PERSONA_ID,
    ) -> None:
        self._lock = threading.RLock()
        self.personas_dir = resolve_personas_dir(personas_dir)
        self.state_db = Path(state_db) if state_db else DEFAULT_STATE_DB
        self.default_persona = default_persona
        self._personas: Dict[str, PersonaConfig] = {}
        self._alias_index: Dict[str, str] = {}
        self._active_id: str = default_persona
        self.reload()
        self._sync_active_from_db()

    def reload(self) -> int:
        """Reload all JSON persona manifests from `self.personas_dir`."""
        with self._lock:
            loaded: Dict[str, PersonaConfig] = {}
            aliases: Dict[str, str] = {}
            if self.personas_dir.is_dir():
                for path in sorted(self.personas_dir.glob("*.json")):
                    try:
                        with open(path, "r", encoding="utf-8") as f:
                            raw = json.load(f)
                        persona = PersonaConfig.from_dict(raw, manifest_path=str(path))
                        loaded[persona.id] = persona
                        aliases[_norm_key(persona.id)] = persona.id
                        aliases[_norm_key(persona.name)] = persona.id
                        for alias in persona.aliases:
                            aliases[_norm_key(alias)] = persona.id
                    except Exception:
                        continue

            self._personas = loaded
            self._alias_index = aliases
            if self._active_id not in self._personas:
                if self.default_persona in self._personas:
                    self._active_id = self.default_persona
                elif self._personas:
                    self._active_id = next(iter(self._personas))
            return len(self._personas)

    def _init_db(self) -> Optional[sqlite3.Connection]:
        try:
            self.state_db.parent.mkdir(parents=True, exist_ok=True)
            conn = sqlite3.connect(str(self.state_db))
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS session_attributes (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                """
            )
            conn.commit()
            return conn
        except Exception:
            return None

    def _sync_active_from_db(self) -> None:
        conn = self._init_db()
        if conn is None:
            return
        try:
            row = conn.execute(
                "SELECT value FROM session_attributes WHERE key = 'active_persona'"
            ).fetchone()
            if row and row[0]:
                resolved = self.resolve_id(row[0])
                if resolved:
                    self._active_id = resolved
        except Exception:
            pass
        finally:
            conn.close()

    def resolve_id(self, identifier: str) -> Optional[str]:
        """Resolve an exact ID, normalized ID, name, or alias to a canonical persona ID."""
        if not identifier:
            return None
        with self._lock:
            if identifier in self._personas:
                return identifier
            norm = _norm_key(identifier)
            if norm in self._alias_index:
                return self._alias_index[norm]
            for pid in self._personas:
                if norm in _norm_key(pid):
                    return pid
            return None

    def list_personas(self) -> List[Dict[str, Any]]:
        """Return all loaded persona metadata dicts."""
        with self._lock:
            return [p.to_dict() for p in self._personas.values()]

    def get_persona(self, identifier: Optional[str] = None) -> Optional[PersonaConfig]:
        """Get a persona by ID/alias, or return the active persona if identifier is None."""
        with self._lock:
            if identifier is None:
                return self._personas.get(self._active_id)
            pid = self.resolve_id(identifier)
            return self._personas.get(pid) if pid else None

    def get_active_persona(self) -> PersonaConfig:
        """Return the active PersonaConfig (falling back to a minimal GLaDOS config if dir is empty)."""
        with self._lock:
            p = self._personas.get(self._active_id)
            if p is not None:
                return p
            if self._personas:
                return next(iter(self._personas.values()))
            return PersonaConfig(
                id="glados",
                name="GLaDOS",
                universe="Portal / Aperture Science",
                system_prompt="You are GLaDOS. Respond in 1-2 short, crisp, dryly sarcastic sentences.",
                tts_engine="piper",
                voice_model="/home/t0psh31f/Projects/GLaDOS/models/TTS/glados.onnx",
                target_node="sanji",
            )

    def set_active_persona(self, identifier: str, persist: bool = True) -> Optional[PersonaConfig]:
        """Hot-swap the active persona mid-session without restarting the service."""
        with self._lock:
            pid = self.resolve_id(identifier)
            if not pid:
                return None
            self._active_id = pid
            if persist:
                conn = self._init_db()
                if conn is not None:
                    try:
                        now = datetime.now(timezone.utc).isoformat()
                        conn.execute(
                            """
                            INSERT INTO session_attributes (key, value, updated_at)
                            VALUES ('active_persona', ?, ?)
                            ON CONFLICT(key) DO UPDATE SET
                                value = excluded.value,
                                updated_at = excluded.updated_at;
                            """,
                            (pid, now),
                        )
                        conn.commit()
                    finally:
                        conn.close()
            return self._personas[pid]

    @staticmethod
    def apply_text_transforms(text: str, persona: PersonaConfig) -> str:
        """Apply persona-specific text transforms (e.g. Prinnies '-dood!' suffix injection)."""
        cleaned = text.strip()
        if not cleaned or not persona.suffix_injection:
            return cleaned
        suffix = persona.suffix_injection.strip()
        if suffix and not cleaned.lower().endswith(suffix.lstrip("-").lower()):
            cleaned = cleaned.rstrip(".!? ") + suffix
        return cleaned
