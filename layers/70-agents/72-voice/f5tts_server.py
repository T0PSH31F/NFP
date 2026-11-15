#!/usr/bin/env python3
"""
Local F5-TTS zero-shot voice cloning HTTP server for NFP 72-voice.
Keeps F5TTS_v1_Base loaded in GPU VRAM and serves POST /synthesize -> audio/wav.
"""

import argparse
import json
import os
import tempfile
from pathlib import Path
from typing import Optional

import torch
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from f5_tts.api import F5TTS


VOICE_DIR = Path(__file__).resolve().parent / "configs" / "voices"


class SynthesizeRequest(BaseModel):
    text: str
    persona: Optional[str] = None
    ref_file: Optional[str] = None
    ref_text: Optional[str] = None
    speed: float = 1.0
    nfe_step: int = 32


def resolve_reference(
    persona: Optional[str],
    ref_file: Optional[str],
    ref_text: Optional[str],
    voice_dir: Path,
) -> tuple[str, str]:
    if ref_file and os.path.exists(ref_file):
        return ref_file, ref_text or ""

    f5_manifest_path = voice_dir / "f5_manifest.json"
    if persona and f5_manifest_path.exists():
        f5m = json.loads(f5_manifest_path.read_text(encoding="utf-8"))
        entry = f5m.get(persona)
        if entry:
            wav_path = voice_dir / "samples" / entry["file"]
            if wav_path.exists():
                return str(wav_path), ref_text or entry.get("text", "")

    manifest_path = voice_dir / "manifest.json"
    if persona and manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        entry = manifest.get(persona)
        if entry and entry.get("refs"):
            ref = entry["refs"][0]
            wav_path = voice_dir / "samples" / ref["file"]
            if wav_path.exists():
                return str(wav_path), ref_text or ref.get("text", "")

    raise HTTPException(status_code=404, detail=f"No valid reference WAV found for persona={persona!r}")


def create_app(voice_dir: Path = VOICE_DIR) -> FastAPI:
    app = FastAPI(title="NFP F5-TTS Voice Cloning Server")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = F5TTS(model="F5TTS_v1_Base", device=device)

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok", "engine": "f5-tts", "model": "F5TTS_v1_Base", "device": device}

    @app.post("/synthesize")
    def synthesize(req: SynthesizeRequest) -> Response:
        if not req.text.strip():
            raise HTTPException(status_code=400, detail="Empty text")
        ref_wav, ref_txt = resolve_reference(req.persona, req.ref_file, req.ref_text, voice_dir)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            out_wav = tmp.name
        try:
            model.infer(
                ref_file=ref_wav,
                ref_text=ref_txt,
                gen_text=req.text,
                file_wave=out_wav,
                speed=max(0.5, min(2.0, req.speed)),
                nfe_step=req.nfe_step,
                remove_silence=True,
            )
            data = Path(out_wav).read_bytes()
            return Response(content=data, media_type="audio/wav")
        finally:
            if os.path.exists(out_wav):
                os.unlink(out_wav)

    return app


def main() -> None:
    parser = argparse.ArgumentParser(description="NFP F5-TTS Voice Cloning Server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8098)
    parser.add_argument("--voice-dir", default=str(VOICE_DIR))
    args = parser.parse_args()
    app = create_app(Path(args.voice_dir))
    uvicorn.run(app, host=args.host, port=args.port, log_level="warning")


if __name__ == "__main__":
    main()
