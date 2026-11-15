#!/usr/bin/env python3
"""
Local Kokoro-82M / ONNX Runtime TTS Engine with espeak-ng phonemizer & fallback.

Execution priority per persona:
1. Kokoro-82M ONNX Runtime (`kokoro-v1.0.fp16.onnx` + `kokoro-voices-v1.0.bin` + `espeak-ng --ipa`)
2. Piper TTS (`piper --model <model.onnx>`)
3. Direct `espeak-ng` WAV synthesis (with persona speed/pitch mapping)
4. Pure-Python silent PCM WAV fallback
"""

from __future__ import annotations

import os
import json
import shutil
import subprocess
import time
import urllib.request
import wave
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from persona_manager import PersonaConfig

DEFAULT_F5TTS_URL = os.environ.get("NFP_F5TTS_URL", "http://127.0.0.1:8098")

DEFAULT_KOKORO_ONNX = Path(
    os.environ.get(
        "KOKORO_ONNX_MODEL",
        "/home/t0psh31f/Projects/GLaDOS/models/TTS/kokoro-v1.0.fp16.onnx",
    )
)
DEFAULT_KOKORO_VOICES = Path(
    os.environ.get(
        "KOKORO_VOICES_BIN",
        "/home/t0psh31f/Projects/GLaDOS/models/TTS/kokoro-voices-v1.0.bin",
    )
)
DEFAULT_GLADOS_ONNX = Path(
    os.environ.get(
        "GLADOS_ONNX_MODEL",
        "/home/t0psh31f/Projects/GLaDOS/models/TTS/glados.onnx",
    )
)

MAX_PHONEME_LENGTH = 510
KOKORO_SAMPLE_RATE = 24000


def _build_kokoro_vocab() -> Dict[str, int]:
    _pad = "$"
    _punctuation = ';:,.!?¡¿—…"«»“” '
    _letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    _letters_ipa = (
        "ɑɐɒæɓʙβɔɕçɗɖðʤəɘɚɛɜɝɞɟʄɡɠɢʛɦɧħɥʜɨɪʝɭɬɫɮʟɱɯɰŋɳɲɴøɵɸθœɶʘɹɺɾɻ"
        "ʀʁɽʂʃʈʧʉʊʋⱱʌɣɤʍχʎʏʑʐʒʔʡʕʢǀǁǂǃˈˌːˑʼʴʰʱʲʷˠˤ˞↓↑→↗↘'̩'ᵻ"
    )
    symbols = [_pad, *_punctuation, *_letters, *_letters_ipa]
    return {sym: idx for idx, sym in enumerate(symbols)}


KOKORO_VOCAB = _build_kokoro_vocab()


def _find_binary(name: str, extra_candidates: Tuple[str, ...] = ()) -> Optional[str]:
    found = shutil.which(name)
    if found:
        return found
    for cand in extra_candidates:
        if os.path.exists(cand) and os.access(cand, os.X_OK):
            return cand
    return None


def phonemize_espeak(text: str, lang: str = "en-us") -> str:
    """Convert text to IPA phonemes using `espeak-ng --ipa`."""
    espeak_bin = _find_binary(
        "espeak-ng",
        ("/run/current-system/sw/bin/espeak-ng", "/usr/bin/espeak-ng"),
    )
    if not espeak_bin:
        return text
    proc = subprocess.run(
        [espeak_bin, "-q", "--ipa", "-v", lang, text],
        capture_output=True,
        text=True,
        timeout=8,
    )
    if proc.returncode != 0:
        return text
    # Collapse newlines and stress artifacts while preserving IPA tokens
    ipa = " ".join(line.strip() for line in proc.stdout.splitlines() if line.strip())
    return ipa or text


def _espeak_lang_for_persona(persona: PersonaConfig) -> str:
    vm = persona.voice_model.lower()
    kv = persona.kokoro_voice.lower()
    if "gb" in vm or kv.startswith(("bm_", "bf_")):
        return "en-gb"
    return "en-us"


class KokoroTTSEngine:
    """
    Hybrid local TTS engine supporting Kokoro-82M ONNX Runtime + espeak-ng,
    Piper ONNX, and espeak-ng WAV fallback.
    """

    def __init__(
        self,
        kokoro_onnx: Path = DEFAULT_KOKORO_ONNX,
        kokoro_voices: Path = DEFAULT_KOKORO_VOICES,
        glados_onnx: Path = DEFAULT_GLADOS_ONNX,
    ) -> None:
        self.kokoro_onnx = Path(kokoro_onnx)
        self.kokoro_voices = Path(kokoro_voices)
        self.glados_onnx = Path(glados_onnx)
        self._ort = None
        self._np = None
        self._ort_sess = None
        self._voices: Optional[Dict[str, Any]] = None
        self._load_error: Optional[str] = None
        self._try_init_kokoro()

    def _try_init_kokoro(self) -> None:
        if not (self.kokoro_onnx.exists() and self.kokoro_voices.exists()):
            self._load_error = "kokoro_model_files_missing"
            return
        try:
            import numpy as np
            import onnxruntime as ort

            ort.set_default_logger_severity(4)
            providers = ort.get_available_providers()
            for skip in ("TensorrtExecutionProvider", "CoreMLExecutionProvider"):
                if skip in providers:
                    providers.remove(skip)

            self._np = np
            self._ort = ort
            self._voices = np.load(self.kokoro_voices)
            self._ort_sess = ort.InferenceSession(
                str(self.kokoro_onnx),
                sess_options=ort.SessionOptions(),
                providers=providers,
            )
            self._load_error = None
        except Exception as exc:
            self._ort_sess = None
            self._load_error = str(exc)

    def capabilities(self) -> Dict[str, Any]:
        return {
            "kokoro_ready": self._ort_sess is not None,
            "kokoro_onnx": str(self.kokoro_onnx),
            "kokoro_voices": str(self.kokoro_voices),
            "kokoro_error": self._load_error,
            "onnx_providers": self._ort.get_available_providers() if self._ort else [],
            "espeak_ng": _find_binary(
                "espeak-ng",
                ("/run/current-system/sw/bin/espeak-ng", "/usr/bin/espeak-ng"),
            ),
            "piper": _find_binary(
                "piper",
                ("/run/current-system/sw/bin/piper", "/etc/profiles/per-user/t0psh31f/bin/piper"),
            ),
        }

    def _synthesize_kokoro_wav(self, text: str, persona: PersonaConfig, out_wav_path: str) -> bool:
        if self._ort_sess is None or self._voices is None or self._np is None:
            return False

        np = self._np
        voice_name = persona.kokoro_voice
        if voice_name not in self._voices:
            # Fallback to first available voice in pack
            avail = list(self._voices.keys())
            if not avail:
                return False
            voice_name = avail[0]

        lang = _espeak_lang_for_persona(persona)
        phonemes = phonemize_espeak(text, lang=lang)
        ids = [KOKORO_VOCAB[ch] for ch in phonemes if ch in KOKORO_VOCAB]
        if not ids:
            return False
        ids = ids[:MAX_PHONEME_LENGTH]

        voice_vec = self._voices[voice_name]
        style_idx = min(len(ids), len(voice_vec) - 1)
        style = voice_vec[style_idx]
        tokens = [[0, *ids, 0]]
        speed = np.ones(1, dtype=np.float32) * float(max(0.5, min(2.0, persona.speed)))

        audio = self._ort_sess.run(
            None,
            {"tokens": tokens, "style": style, "speed": speed},
        )[0]
        pcm = np.clip(np.asarray(audio, dtype=np.float32), -1.0, 1.0)
        pcm_int16 = (pcm * 32767.0).astype(np.int16)

        with wave.open(out_wav_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(KOKORO_SAMPLE_RATE)
            wf.writeframes(pcm_int16.tobytes())
        return os.path.exists(out_wav_path) and os.path.getsize(out_wav_path) > 44

    def _synthesize_piper_wav(self, text: str, persona: PersonaConfig, out_wav_path: str) -> bool:
        piper_bin = _find_binary(
            "piper",
            ("/run/current-system/sw/bin/piper", "/etc/profiles/per-user/t0psh31f/bin/piper"),
        )
        if not piper_bin:
            return False

        model_path = persona.voice_model if persona.voice_model.endswith(".onnx") else str(self.glados_onnx)
        if not os.path.exists(model_path):
            if os.path.exists(self.glados_onnx):
                model_path = str(self.glados_onnx)
            else:
                return False

        proc = subprocess.run(
            [piper_bin, "--model", model_path, "--output_file", out_wav_path],
            input=text.encode("utf-8"),
            capture_output=True,
            timeout=12,
        )
        return proc.returncode == 0 and os.path.exists(out_wav_path) and os.path.getsize(out_wav_path) > 44

    def _synthesize_espeak_wav(self, text: str, persona: PersonaConfig, out_wav_path: str) -> bool:
        espeak_bin = _find_binary(
            "espeak-ng",
            ("/run/current-system/sw/bin/espeak-ng", "/usr/bin/espeak-ng"),
        )
        if not espeak_bin:
            return False

        lang = _espeak_lang_for_persona(persona)
        wpm = int(max(90, min(320, round(175 * persona.speed))))
        pitch = int(max(0, min(99, round(50 + persona.pitch_shift * 7))))
        proc = subprocess.run(
            [espeak_bin, "-v", lang, "-s", str(wpm), "-p", str(pitch), "-w", out_wav_path, text],
            capture_output=True,
            timeout=10,
        )
        return proc.returncode == 0 and os.path.exists(out_wav_path) and os.path.getsize(out_wav_path) > 44

    def _apply_audio_effects(self, wav_path: str, persona: PersonaConfig) -> None:
        """Apply optional persona pitch_shift / audio_filter via ffmpeg if installed."""
        if persona.audio_filter in ("none", "") and abs(persona.pitch_shift) < 0.1:
            return
        ffmpeg_bin = _find_binary(
            "ffmpeg",
            ("/run/current-system/sw/bin/ffmpeg", "/etc/profiles/per-user/t0psh31f/bin/ffmpeg"),
        )
        if not ffmpeg_bin:
            return

        filters: List[str] = []
        if abs(persona.pitch_shift) >= 0.1:
            # Approximate pitch shift in semitones via asetrate + atempo
            factor = 2.0 ** (persona.pitch_shift / 12.0)
            factor = max(0.5, min(2.0, factor))
            filters.append(f"asetrate=24000*{factor:.4f},aresample=24000,atempo={1.0/factor:.4f}")
        if persona.audio_filter == "metallic":
            # SWTOR / KOTOR HK-series droid voicebox:
            # 350Hz-4.5kHz bandpass + 2kHz nasal honk + 145Hz true ring-mod + metallic comb + hard compression
            filters.append(
                "highpass=f=350,lowpass=f=4500,"
                "equalizer=f=2000:t=q:w=1.5:g=6,"
                "aeval='0.55*val(0)+0.45*val(0)*sin(2*PI*145*t)',"
                "aecho=0.8:0.88:6|12:0.65|0.45,"
                "acrusher=bits=11:mode=log:mix=0.25,"
                "acompressor=threshold=-20dB:ratio=8:attack=2:release=50:makeup=4,"
                "alimiter=limit=0.95"
            )
        elif persona.audio_filter == "synth_robotic":
            filters.append("highpass=f=450,lowpass=f=3200,aeval='0.6*val(0)+0.4*val(0)*sin(2*PI*110*t)',aecho=0.8:0.8:10:0.45,acompressor=threshold=-18dB:ratio=4")
        elif persona.audio_filter == "compressed":
            # Disgaea Prinny: fast squeaky cartoon boost + punchy compression
            filters.append(
                "highpass=f=320,"
                "equalizer=f=2300:t=q:w=1.3:g=8,"
                "acompressor=threshold=-18dB:ratio=6:makeup=4,"
                "alimiter=limit=0.95"
            )

        if not filters:
            return

        tmp_out = f"{wav_path}.fx.wav"
        try:
            proc = subprocess.run(
                [ffmpeg_bin, "-y", "-i", wav_path, "-af", ",".join(filters), tmp_out],
                capture_output=True,
                timeout=8,
            )
            if proc.returncode == 0 and os.path.exists(tmp_out) and os.path.getsize(tmp_out) > 44:
                os.replace(tmp_out, wav_path)
        except Exception:
            if os.path.exists(tmp_out):
                os.unlink(tmp_out)

    def _synthesize_f5tts_wav(self, text: str, persona: PersonaConfig, out_wav_path: str) -> bool:
        """Call the local/remote F5-TTS zero-shot voice cloning server if reachable."""
        payload = json.dumps(
            {
                "text": text,
                "persona": persona.id,
                "speed": persona.speed,
            }
        ).encode("utf-8")
        req = urllib.request.Request(
            f"{DEFAULT_F5TTS_URL.rstrip('/')}/synthesize",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                if resp.status == 200:
                    data = resp.read()
                    if len(data) > 44:
                        Path(out_wav_path).write_bytes(data)
                        return True
        except Exception:
            pass
        return False

    def synthesize_to_wav(
        self,
        text: str,
        persona: PersonaConfig,
        out_wav_path: str,
    ) -> Tuple[bool, float, str]:
        """
        Synthesize `text` for `persona` to `out_wav_path`.
        Returns (success, elapsed_ms, engine_used).
        """
        t0 = time.perf_counter()
        engine_used = "fallback_silence"

        if persona.tts_engine == "piper":
            if self._synthesize_piper_wav(text, persona, out_wav_path):
                engine_used = "piper"
            elif self._synthesize_kokoro_wav(text, persona, out_wav_path):
                engine_used = "kokoro_onnx"
            elif self._synthesize_espeak_wav(text, persona, out_wav_path):
                engine_used = "espeak-ng"
        else:
            if self._synthesize_f5tts_wav(text, persona, out_wav_path):
                engine_used = "f5tts"
            elif self._synthesize_kokoro_wav(text, persona, out_wav_path):
                engine_used = "kokoro_onnx"
            elif self._synthesize_piper_wav(text, persona, out_wav_path):
                engine_used = "piper"
            elif self._synthesize_espeak_wav(text, persona, out_wav_path):
                engine_used = "espeak-ng"

        if engine_used == "fallback_silence":
            with wave.open(out_wav_path, "wb") as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(16000)
                wf.writeframes(b"\x00\x00" * 1600)
        elif engine_used != "f5tts":
            self._apply_audio_effects(out_wav_path, persona)

        elapsed_ms = round((time.perf_counter() - t0) * 1000.0, 2)
        return True, elapsed_ms, engine_used
