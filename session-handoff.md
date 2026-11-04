# Session Handoff

## Last Session Accomplishments
1. **Single-Instance Fleet Orchestrators on `luffy` (`100.64.0.3` / `luffy.nfp.nix`)**:
   - Configured [`layers/70-agents/76-orchestrators/paperclip.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/76-orchestrators/paperclip.nix) (`:3101`), [`layers/70-agents/76-orchestrators/aionui.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/76-orchestrators/aionui.nix) (`:3006`), and [`layers/70-agents/76-orchestrators/mission-control.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/76-orchestrators/mission-control.nix) (`:3099`) to run as a single central instance exclusively on `luffy` (`enable = true` on `luffy`, `enable = false` on `z0r0` and `sanji`).
   - Updated [`layers/90-profiles/tags/ai-agent.nix`](file:///home/t0psh31f/Clan/NFP/layers/90-profiles/tags/ai-agent.nix), [`layers/90-profiles/tags/agent-orchestrator.nix`](file:///home/t0psh31f/Clan/NFP/layers/90-profiles/tags/agent-orchestrator.nix), [`machines/luffy/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/luffy/default.nix), [`machines/z0r0/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/z0r0/default.nix), and [`machines/sanji/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/sanji/default.nix) to enforce single-instance placement and fix Caddy reverse proxy ports on `luffy`.

2. **All 3 Machines (`luffy`, `z0r0`, `sanji`) Wired to Patch Into `luffy`**:
   - Added `paperclip`, `aionui`, and `mission-control` endpoints to [`layers/20-services/21-networking/endpoints.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/21-networking/endpoints.nix) and exported `PAPERCLIP_URL`, `PAPERCLIP_API_URL`, `AIONUI_URL`, `AIONUI_SERVER_URL`, and `MISSION_CONTROL_URL` across all machines.
   - Added `client.enable = true` and `remoteHost = "luffy.nfp.nix"` to all 3 orchestrator modules, provisioning `/etc/{paperclip,aionui,mission-control}/fleet-client.json` and `~/.paperclip/context.json` across `luffy`, `z0r0`, and `sanji`.

3. **Clan Vars (`clan.core.vars.generators`) & Build/Runtime Fixes**:
   - Declared `clan.core.vars.generators.{paperclip,aionui,mission-control}` and created SOPS-encrypted secrets under `vars/per-machine/luffy/{paperclip,aionui,mission-control}/`, deployed to `/run/secrets/vars/` on `luffy`.
   - Patched `aionui` `better-sqlite3` C++ addon in `preBuild` for Electron 43 V8 compatibility, packaged `aioncore-0.2.2` via `AIONUI_BACKEND_BIN`, and configured headless `--ozone-platform=headless --disable-gpu --no-sandbox --webui --remote --port=3006`.
   - Configured Paperclip `server.allowedHostnames` (`lan` bind + external PostgreSQL) and Mission Control `MC_ALLOW_ANY_HOST = "true"` / `MC_ALLOWED_HOSTS` for cross-machine tailnet access.

## Verification Evidence
1. `./layers/00-cyberia/06-scripts/nfp-check.sh static`: passed `0` warnings on touched files.
2. `./layers/00-cyberia/06-scripts/nfp-check.sh eval`: remote evaluation on `z0r0` succeeded across `z0r0`, `luffy`, and `sanji`.
3. Cross-machine live status & HTTP check:
   - `luffy`: `paperclip.service` (`active`), `aionui.service` (`active`), `podman-mission-control.service` (`active`).
   - `z0r0` & `sanji`: all 3 services `inactive`.
   - HTTP reachability from `sanji`, `z0r0`, and `luffy` to `http://100.64.0.3:3101/api/health`, `http://100.64.0.3:3006/`, and `http://100.64.0.3:3099/`: all returned `HTTP 200`.

## In-Flight (2026-11-04, uncommitted)
- Observability wiring for luffy orchestrators: edited monitoring.nix (blackbox probes to luffy for paperclip/aionui/mission-control/langfuse, langfuse-exporter -> luffy health), homepage-dashboard.nix + paperclip.nix (richer Paperclip card), new dashboards/fleet-orchestrators.json.
- Fleet eval (nfp-check.sh eval) was running; re-run it before committing. Then clan machines update z0r0 (Prometheus/Grafana host) and luffy.
- Open gaps: Alloy not on luffy (no luffy logs in Loki); Langfuse API key clan var missing (trace/token/cost counters = 0).
- Conversation id: d8f144c9-21f4-4eb6-b74f-14f0ae681661 (transcript: ~/.gemini/antigravity-cli/brain/d8f144c9-21f4-4eb6-b74f-14f0ae681661/.system_generated/logs/transcript.jsonl)
