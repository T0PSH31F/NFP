# Session Handoff

## Last Session Accomplishments
1. **Always-On Jarvis System Architecture & Router/Voice Refactor**:
   - **Router Architecture Refactor**:
     - Bypassed Kong Gateway (`:8090`) for all `/v1/*` streaming and completion requests to eliminate SSE buffering; disabled Kong in [`machines/sanji/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/sanji/default.nix) and [`layers/90-profiles/tags/ai-router.nix`](file:///home/t0psh31f/Clan/NFP/layers/90-profiles/tags/ai-router.nix).
     - Configured ExtremeRouter ([`layers/70-agents/78-llm-routers/extreme-router.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/extreme-router.nix)) with `ENABLE_RTK=true`, `ENABLE_HEADROOM=true`, and defined declarative combo `cascade/agent` (Tier 0: `ollama/qwen3.5:9b`, Tier 1: `opencode/deepseek-v4`, `google/gemini-2.5-flash`, `openrouter/free`, Tier 2: `hermes/claude-sonnet-4.5`, `google/gemini-2.5-pro`).
     - Seeded SQLite combos table in `/var/lib/extreme-router/db/data.sqlite` and established symlink `extremerouter.nix -> extreme-router.nix`.
     - Deprecated standalone runtime dependencies on `freellmapi` and `freellmpool`.
   - **Jev System-1 Pre-Flight Classifier Daemon (`:20127`)**:
     - Implemented [`layers/70-agents/78-llm-routers/jev_classifier.py`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/jev_classifier.py) with two-stage triage: Stage 1 zero-token heuristic filter dropping routine status 200 OKs and pings, and Stage 2 Ollama local SLM classification (`qwen3.5:9b`) computing actionability, risk level, target persona, and verdict (`IGNORE`, `NOTIFY`, `DISPATCH_AGENT`).
     - Created Nix module [`layers/70-agents/78-llm-routers/jev.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/jev.nix) managing `nfp-jev-classifier.service`.
   - **Local Voice Pipeline & Persona Registry (`72-voice`)**:
     - Created manifest [`layers/70-agents/72-voice/personas.json`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/72-voice/personas.json) defining 11 pre-registered personas (`jarvis-classic`, `glados-auditor`, `samuel-jackson`, `orc-peon`, `hk-55`, `sc-adjutant`, `johnny-5`, `gandalf`, `paimon`, `cortana`, and `eccentric-jp-girl`).
     - Implemented daemon [`layers/70-agents/72-voice/nfp_voice_interrupter.py`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/72-voice/nfp_voice_interrupter.py) supporting Silero VAD barge-in interrupts (instantly killing active playback processes on detected speech) and regex trigger parsing (`Switch voice to [Persona]`) hot-swapping active state in `~/.local/share/pi-durable/state.sqlite`.
   - **Network NAS Backup & SQLite State Replication**:
     - Declared network NAS mounts in [`layers/10-system/nas-mounts.nix`](file:///home/t0psh31f/Clan/NFP/layers/10-system/nas-mounts.nix) targeting `/mnt/nas/backups/nfp-durable/` with CIFS/NFS automount, soft error handling, and symlinks.
     - Configured Litestream live WAL frame replication (`nfp-pi-durable-litestream.service`) streaming `~/.local/share/pi-durable/state.sqlite` directly to `/mnt/nas/backups/nfp-durable/state.db` with startup recovery auto-pull (`litestream restore -if-replica-exists`) and periodic backup snapshot timer.
     - Enabled `layers.layer-10.system.config.nas-mounts.enable = true;` in [`machines/sanji/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/sanji/default.nix).
   - **A2UI Schema & Pi Agent Alignment**:
     - Saved JSON Schema [`layers/70-agents/77-dash-desk-ui/a2ui_action_card_schema.json`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/77-dash-desk-ui/a2ui_action_card_schema.json) with interactive action buttons, diff previews, risk levels, and fallback TTL rules.
     - Updated Jev classifier and Pi durable daemon ([`layers/70-agents/71-harness/pi-durable-daemon.py`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/71-harness/pi-durable-daemon.py)) to emit compliant A2UI cards.
     - Routed `OPENAI_BASE_URL` and `ANTHROPIC_BASE_URL` across Pi, Hermes, OpenCode, and DSH harnesses to ExtremeRouter (`http://127.0.0.1:20128/v1`).

## Verification Evidence
1. `python3 layers/70-agents/78-llm-routers/jev_classifier.py --test`: 5/5 assertions passed.
2. `python3 layers/70-agents/72-voice/nfp_voice_interrupter.py --test`: 4/4 assertions passed.
3. Tested `litestream replicate -once` and `litestream restore` cycles with verified zero data loss.
4. `./init.sh --worktree`: passed 5/5 evaluating `sanji`, `z0r0`, and `luffy` cleanly.

## Next Session Recommendations
1. Deploy updates live to `sanji` via `clan machines update sanji`.
2. Inspect `systemctl status nfp-jev-classifier` and `systemctl status nfp-pi-durable-litestream`.
