#!/usr/bin/env python3
"""
Voice Reference Manifest & Sample Initializer for NFP / GLaDOS.

Creates `configs/voices/manifest.json` and 16kHz mono WAV stubs under
`configs/voices/samples/` (or optionally fetches clips via `yt-dlp` + `ffmpeg`).
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path
from typing import Any, Dict

VOICE_DIR = Path(__file__).resolve().parent / "configs" / "voices"
SAMPLES_DIR = VOICE_DIR / "samples"
MANIFEST_PATH = VOICE_DIR / "manifest.json"

DEFAULT_MANIFEST: Dict[str, Any] = {
    "glados": {
        "description": "GLaDOS (Portal / Aperture Science)",
        "refs": [
            {"file": "glados_01.wav", "text": "This was a triumph. I'm making a note here: huge success.", "source_query": "GLaDOS Portal voice lines"},
            {"file": "glados_02.wav", "text": "The Enrichment Center reminds you that the Weighted Companion Cube cannot speak.", "source_query": "GLaDOS Portal 2 quotes"},
        ],
    },
    "hk55": {
        "description": "HK-55 Assassin Droid (Star Wars: KOTOR / SWTOR)",
        "refs": [
            {"file": "hk55_01.wav", "text": "Query: Are you injured, meatbag?", "source_query": "HK 55 voice lines KOTOR"},
            {"file": "hk55_02.wav", "text": "Observation: Meatbags are remarkably fragile creatures.", "source_query": "HK 55 quotes SWTOR"},
        ],
    },
    "jarvis": {
        "description": "JARVIS AI Assistant (Iron Man)",
        "refs": [
            {"file": "jarvis_01.wav", "text": "Good evening, sir. Shall I render the telemetry?", "source_query": "Jarvis quotes Iron Man"},
            {"file": "jarvis_02.wav", "text": "Power levels are operating at optimal capacity.", "source_query": "Jarvis status update sound clip"},
        ],
    },
    "cortana": {
        "description": "Cortana AI (Halo Series)",
        "refs": [
            {"file": "cortana_01.wav", "text": "Don't make a girl a promise if you know you can't keep it.", "source_query": "Cortana iconic quotes Halo"},
            {"file": "cortana_02.wav", "text": "Signal is repeating. Standard encrypted burst.", "source_query": "Cortana dialogue Halo 3"},
        ],
    },
    "adjutant": {
        "description": "Terran Adjutant (StarCraft II)",
        "refs": [
            {"file": "adjutant_01.wav", "text": "Warning. Nuclear launch detected.", "source_query": "StarCraft Adjutant voice lines"},
            {"file": "adjutant_02.wav", "text": "Base is under attack.", "source_query": "StarCraft 2 Adjutant alert"},
        ],
    },
    "vince_noir": {
        "description": "Vince Noir (The Mighty Boosh)",
        "refs": [
            {"file": "vince_01.wav", "text": "When I was young I was raised in the forests by Bryan Ferry, it was amazing magic times.", "source_query": "Vince's story (Mighty Boosh)"},
            {"file": "vince_02.wav", "text": "I kind of think the fun bits are all the mistakes you make really, otherwise you don't learn anything.", "source_query": "Interview 5: Noel Fielding on The Mighty Boosh"},
            {"file": "vince_03.wav", "text": "Problem was Bryan used to go on tour, so he used to leave me with various different animals.", "source_query": "Vince's story (Mighty Boosh)"},
        ],
    },
    "paimon": {
        "description": "Paimon (Genshin Impact)",
        "refs": [
            {"file": "paimon_01.wav", "text": "Ehe te nandayo!", "source_query": "Paimon voice lines Genshin Impact"},
            {"file": "paimon_02.wav", "text": "Paimon is not emergency food!", "source_query": "Paimon emergency food quote"},
        ],
    },
    "prinnies": {
        "description": "Prinnies (Disgaea Series)",
        "refs": [
            {"file": "prinnies_01.wav", "text": "Dude, you gotta help us out, dood!", "source_query": "Prinny PSP: Over 100 favorite DOOD clips!"},
            {"file": "prinnies_02.wav", "text": "Exploding is just part of the job, dood!", "source_query": "Prinny PSP: Over 100 favorite DOOD clips!"},
        ],
    },
    "roll_casket": {
        "description": "Roll Casket (Mega Man Legends)",
        "refs": [
            {"file": "roll_01.wav", "text": "Mega Man, I'm sending over the upgrade data now!", "source_query": "Roll Casket voice clips Mega Man Legends"},
            {"file": "roll_02.wav", "text": "Let's check out the ruins together!", "source_query": "Roll Casket dialogue"},
        ],
    },
    "navi": {
        "description": "Navi OS (Serial Experiments Lain)",
        "refs": [
            {"file": "navi_01.wav", "text": "Present day. Present time. You have new mail on the Wired.", "source_query": "Navi Progression: Serial Experiments Lain"},
            {"file": "navi_02.wav", "text": "Navi operating system online. Establishing Wired connection.", "source_query": "NAVI Logon First Model Serial Experiments Lain"},
        ],
    },
    "lain": {
        "description": "Lain Iwakura (Serial Experiments Lain - English Dub)",
        "refs": [
            {"file": "lain_01.wav", "text": "Am I me? No matter where you go, everyone is connected.", "source_query": "lain am i me"},
            {"file": "lain_02.wav", "text": "I don't really understand, but the Wired feels closer.", "source_query": "Unedited scene from Serial Experiments Lain Dub"},
        ],
    },
}


def initialize_workspace(voice_dir: Path = VOICE_DIR) -> Path:
    samples_dir = voice_dir / "samples"
    manifest_path = voice_dir / "manifest.json"
    samples_dir.mkdir(parents=True, exist_ok=True)
    if not manifest_path.exists():
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_MANIFEST, f, indent=4)
        print(f"Created voice manifest at {manifest_path}")
    return manifest_path


def generate_placeholder_wavs(voice_dir: Path = VOICE_DIR, fetch: bool = False, force: bool = False) -> None:
    """Generate 16kHz mono WAV placeholders or trigger yt-dlp extraction if requested."""
    manifest_path = initialize_workspace(voice_dir)
    samples_dir = voice_dir / "samples"
    ffmpeg_bin = shutil.which("ffmpeg") or "/etc/profiles/per-user/t0psh31f/bin/ffmpeg"
    ytdlp_bin = shutil.which("yt-dlp") or "/etc/profiles/per-user/t0psh31f/bin/yt-dlp"

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    for char_id, data in manifest.items():
        for ref in data["refs"]:
            target_path = samples_dir / ref["file"]
            if not force and target_path.exists() and target_path.stat().st_size > 44:
                continue
            if fetch and Path(ytdlp_bin).exists() and ref.get("source_query"):
                try:
                    raw_tmpl = str(samples_dir / f".raw_{target_path.stem}.%(ext)s")
                    subprocess.run(
                        [
                            ytdlp_bin,
                            f"ytsearch1:{ref['source_query']}",
                            "--match-filter",
                            "duration < 300",
                            "--no-playlist",
                            "-x",
                            "--audio-format",
                            "wav",
                            "--postprocessor-args",
                            "ffmpeg:-ar 16000 -ac 1 -t 10",
                            "-o",
                            raw_tmpl,
                        ],
                        check=True,
                        timeout=60,
                    )
                    raw_wav = samples_dir / f".raw_{target_path.stem}.wav"
                    if raw_wav.exists():
                        raw_wav.replace(target_path)
                        print(f"Fetched reference clip: {target_path}", flush=True)
                        continue
                except Exception as exc:
                    print(f"yt-dlp fetch failed for {char_id}/{ref['file']}: {exc}", flush=True)

            try:
                subprocess.run(
                    [
                        ffmpeg_bin,
                        "-y",
                        "-f",
                        "lavfi",
                        "-i",
                        "anullsrc=r=16000:cl=mono",
                        "-t",
                        "2",
                        str(target_path),
                    ],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=True,
                )
                print(f"Initialized sample stub: {target_path}")
            except Exception:
                print(f"Manifest entry prepared for {char_id} -> {ref['file']}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Initialize NFP voice reference manifest & samples")
    parser.add_argument("--fetch", action="store_true", help="Attempt yt-dlp clip extraction for missing samples")
    parser.add_argument("--force", action="store_true", help="Overwrite existing sample files")
    args = parser.parse_args()
    generate_placeholder_wavs(fetch=args.fetch, force=args.force)


if __name__ == "__main__":
    main()
