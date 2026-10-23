# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `kong-jev-voice-router-stack-hardening`
- **Last verified green:**
  - `./init.sh --worktree` -> PASSED (5/5 checks passed across all 3 machines: `luffy`, `z0r0`, `sanji`)
  - `./layers/00-cyberia/06-scripts/nfp-llm-doctor.sh` -> PASSED (6/6 checks: `kong-gateway`, `pi`, `hermes`, `opencode`, `claude-code`, `codex` all discovering `537` models)
  - `python3 layers/70-agents/70-jev/tests/test_jev_router.py` -> PASSED (9/9 unit tests in 0.023s, zero network)
  - `python3 layers/70-agents/70-jev/tests/replay_harness.py` -> PASSED (16/16 golden prompts, 100.0% tier accuracy, 10.5% net cost reduction vs plain cascade)
  - `python3 layers/70-agents/72-voice/hermes-voice-daemon.py --golden-test` -> PASSED (4/4 live E2E: `537` models via Kong, streaming chat `Pong.`, tool-call round trip `get_node_health({"node":"sanji"})`, and `492.8ms` wake-to-first-audio `< 1500ms` latency budget)
- **Blockers:** None. Awaiting explicit user approval on the Review Packet before executing `clan machines update` or `git push`.

## Work Completed This Session

1. **Phase 0 & 1 — Kong Gateway (`layers/70-agents/78-llm-routers/`)**:
   - Diagnosed exact failure layers across ExtremeRouter (`:20128`), OmniRoute (`:20129`), and Kong (`:8090`).
   - Added global `pre-function` (access phase) in `kong-gateway.nix` that normalizes `/v1/v1/` -> `/v1/`, extracts `Authorization: Bearer <KONG_KEY>` or `x-api-key` into `apikey`, and clears the original header before `key-auth` runs.
   - Updated `kong-secrets.nix` (`kong-extremerouter-auth`, `kong-jev-auth`, `kong-omniroute-auth`) so `request-transformer` uses `remove` (`apikey`, `x-api-key`) + `replace` (`Authorization: Bearer <UPSTREAM_KEY>`) + `add` (`Authorization: Bearer <UPSTREAM_KEY>`), preventing client Bearer tokens from leaking upstream.
   - Added routes `/v1/messages`, `/v1/messages/count_tokens`, `/v1/responses`, `/v1/audio/speech`, `/v1/audio/transcriptions`, `/v1/images/generations`, and `/jev` with `OPTIONS` method and restricted CORS origins.
   - Switched rate limiting to `policy = "local"`, `limit_by = "consumer"` with dedicated `300/min, 6000/hr` plugins for `voice` and `hermes-voice`. Added `pi`, `hermes-voice`, and `voice` consumers and sops keys.
   - Reconciled `freellmpool` (`8083`) and `manifest` (`2099`) ports, fixed healthcheck paths, removed `127.0.0.11` Docker DNS resolver under `--network=host`, and pinned `docker.io/library/kong:3.9.1`.

2. **Phase 2 — Declarative Client Configs & `nfp-llm-doctor`**:
   - `pi-coding-agent.nix`: Declaratively generates `~/.pi/agent/models.json` (`PI_CODING_AGENT_DIR`) with `baseUrl` via Kong, `api = "openai-completions"`, `apiKey = "!cat ~/.config/sops-nix/secrets/kong_key_pi"`, and explicit model/combo IDs synced from `/v1/models` on Home Manager activation; removed unverified `PI_MODEL`, `PI_ROUTER_ENDPOINT`, and `~/.config/pi/config.json`.
   - `claude-code.nix`: Set `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN` (from sops), and `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`.
   - `codex.nix`: Fixed config path from `deepseek/config.toml` to `codex/config.toml` using provider `kong` and `wire_api = "responses"`.
   - `opencode.nix` & `hermes.nix`: Wired Kong provider blocks and sops keys.
   - Created `layers/00-cyberia/06-scripts/nfp-llm-doctor.sh` and registered `nfp-llm-doctor` in `common.nix`.

3. **Phase 3 — Jev Streaming Decision-Only Tier Router (`layers/70-agents/70-jev/`)**:
   - Rewrote `jev-router-proxy.py` as an async streaming reverse proxy (`127.0.0.1:20127`, `openFirewall = false`, `Restart = "always"`).
   - Never synthesizes an answer; selects canonical tier (`voice-fast` -> `Penny-Pincher`, `free-first` -> `Free`, `cascade-balanced` -> `Coding`, `frontier` -> `Judge`/`ag/claude-opus-4-6-thinking`), sets `X-Jev-Decision`, enforces tool/destructive/sensitive guardrails, validates output and tool-call JSON schemas, retries once at the same tier then escalates one tier (`MAX_ATTEMPTS = 3`), fails open in `<50ms`, and exports Prometheus `/metrics` + Langfuse traces.
   - Added `tests/test_jev_router.py`, `tests/replay_harness.py`, and `layers/00-cyberia/01-docs/jev-router-report.md`.

4. **Phase 4 — 24/7 Hermes + Pi Voice Agent (`layers/70-agents/71-harness/hermes/` & `72-voice/`)**:
   - Created `layers/70-agents/75-mcp/pi-a2a-mcp.py` (`hermes-a2a` MCP worker delegating coding/CLI tasks from Hermes front door to Pi).
   - Created `layers/70-agents/72-voice/hermes-voice-daemon.py` (`:8880`) with persistent warm Piper TTS subprocess (`<50ms` synthesis) achieving `492.8ms`–`600.2ms` wake-to-first-audio latency (`< 1500ms` budget).
   - Hardened `hermes-live-voice.nix`, `voice.nix`, and `wyoming.nix` with `Restart = "always"`, `/persist` state directories, `users.users.t0psh31f.linger = true`, `hermes-voice-watchdog` timer (every 2m), and `nfp-voice-golden-test` nightly timer (04:15).

5. **Phase 5 — Consolidate & Harden (`layers/70-agents/78-llm-routers/`)**:
   - Consolidated on `ExtremeRouter` (`:20128`) as primary router with `FreeLLMAPI` (`:3001`) and `FreeLLMPool` (`:8083`) as upstream custom providers; disabled unused secondary routers in `ai-router.nix`.
   - Moved hardcoded `FreeLLMAPI` `ENCRYPTION_KEY` to sops (`freellmapi_encryption_key`); replaced `0777 root:root` tmpfiles and `--user=0:0` with `0750 1000:1000`; enforced `REQUIRE_API_KEY=true`; documented `tos:avoid` / `web-cookie` providers in `layers/70-agents/78-llm-routers/README.md`.

## Next Workstreams

1. Await Erik's review of the Review Packet and explicit approval before running `clan machines update` or `git push`.
