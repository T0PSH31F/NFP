#!/usr/bin/env python3
"""Merge free-tier connectors into every ExtremeRouter combo, idempotently.

ExtremeRouter exposes no admin HTTP API without a browser session, so this
operates on its SQLite store directly. The caller MUST stop the container
first; writing while the app runs risks a stale in-memory config overwriting
the change.

Usage:
  podman stop <extreme-router-container>
  python3 extreme-router-combos.py --db /var/lib/extreme-router/db/data.sqlite
  podman start <extreme-router-container>
"""

import argparse
import datetime
import json
import shutil
import sqlite3
import sys

# Free-tier connectors per combo, appended after the existing paid chain.
FREE_ADDITIONS = {
    "Coding": [
        "cerebras/gpt-oss-120b",
        "groq/openai/gpt-oss-120b",
        "ollama/gpt-oss:120b",
    ],
    "Research": [
        "groq/llama-3.3-70b-versatile",
        "cerebras/qwen-3-235b-a22b-instruct-2507",
        "ollamacloud/kimi-k2.6",
    ],
    "Free": [
        "agnes-api/agnes-2.5-flash",
        "cerebras/zai-glm-4.7",
        "groq/qwen/qwen3-32b",
        "ollama/glm-5",
        "ollamacloud/deepseek-v4-flash",
        "veo-free/veo",
    ],
    "Judge": [
        "cerebras/zai-glm-4.7",
        "nvidia/z-ai/glm-5.2",
    ],
    "Penny-Pincher": [
        "groq/llama-3.3-70b-versatile",
        "cerebras/gpt-oss-120b",
    ],
    "DailyDrive": [
        "ollama/gpt-oss:120b",
        "groq/qwen/qwen3-32b",
        "cerebras/llama-3.3-70b",
    ],
    "deepseek-swarm": [
        "ollamacloud/deepseek-v4-flash",
        "nvidia/deepseek-ai/deepseek-v4-flash",
        "ollama/glm-5",
    ],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = f"{args.db}.bak-{stamp}"
    if not args.dry_run:
        shutil.copy2(args.db, backup)
        print(f"backup: {backup}")

    con = sqlite3.connect(args.db)
    rows = con.execute("select id, name, models from combos").fetchall()
    if not rows:
        print("no combos found", file=sys.stderr)
        return 1

    changed = 0
    for cid, name, models_json in rows:
        try:
            models = json.loads(models_json or "[]")
        except ValueError:
            print(f"{name}: unparseable models, skipped", file=sys.stderr)
            continue
        additions = FREE_ADDITIONS.get(name, [])
        existing = list(models)
        added = [m for m in additions if m not in existing]
        if not added:
            print(f"{name}: already has free connectors ({len(models)} total)")
            continue
        new_models = existing + added
        print(f"{name}: +{len(added)} free -> {len(new_models)} total")
        if not args.dry_run:
            con.execute(
                "update combos set models=?, revision=revision+1, updatedAt=? where id=?",
                (json.dumps(new_models), datetime.datetime.now().isoformat(), cid),
            )
        changed += 1

    if not args.dry_run:
        con.commit()
    con.close()
    print(f"combos changed: {changed}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
