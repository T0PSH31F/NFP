# Session Handoff

## Last Session Accomplishments
1. **Quickshell & Omarchy Desktop Shell Restored**:
   - Restarted `quickshell-rise.service` and `omarchy-shell.service`.
   - Added declarative `exec-once` fallback in [`layers/30-environments/32-nixarchy-rise/default.nix`](file:///home/t0psh31f/Clan/NFP/layers/30-environments/32-nixarchy-rise/default.nix#L286-L288).
2. **Fixed Pi Failing MCP Servers**:
   - Removed legacy `:8094/mcp` (`context-forge`) and `:8085/mcp` (`hermes-a2a`) from [`pi-coding-agent.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/71-harness/pi-coding-agent.nix), [`antigravity.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/71-harness/antigravity.nix), and [`kiro-cli.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/71-harness/kiro-cli.nix).
   - Replaced `~/.pi/agent/mcp.json` with clean configuration featuring `mcp-nixos`.
3. **Hermes Skills & Context Optimization**:
   - Configured `coding_context: focus` in [`layers/70-agents/71-harness/hermes/hermes.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/71-harness/hermes/hermes.nix) to prune skill description overhead by ~85%.
   - Pruned dead MCP endpoints and disabled unpinned toolsets.
4. **Browser Default Homepage Lockdown**:
   - Configured Brave, Firefox, and Qutebrowser policies to set default homepage, new tab page, and startup restore URLs to `http://luffy.nfp.nix:3007/`.
   - Deployed live managed policy to `~/.config/BraveSoftware/Brave-Browser/policies/managed/homepage.json`.
5. **Diagnosed & Fully Resolved Kong 502 / Pi Routing Failure**:
   - **Root Cause 1 (`z0r0`)**: Kong and Jev upstream route `/v1/chat/completions` to `extremerouter-llm` at `http://100.64.0.1:20128`. On `z0r0`, `podman-extreme-router.service` was crashing with exit code 1 because `--user=1000:1000` prevented internal `su-exec` from dropping root privileges. Fixed in [`layers/70-agents/78-llm-routers/extreme-router.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/extreme-router.nix) by removing `--user=1000:1000`. ExtremeRouter is now healthy (`http://100.64.0.1:20128/api/health` -> `{"ok":true}`).
   - **Root Cause 2 (`sanji`)**: `machines/sanji/default.nix` had `freellmpool.port = lib.mkForce 8080`, causing Kong to route free-tier requests to `signal-cli-rest-api` instead of `freellmpool` (`127.0.0.1:8083`). Fixed and deployed via Clan.
   - **Root Cause 3 (Kong path prefixes)**: Fixed prefix stripping for `/llm/free`, `/llm/coding`, and `/llm` in [`layers/70-agents/78-llm-routers/kong-gateway.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/kong-gateway.nix).
   - **End-to-End Verification**: Tested `pi --provider kong --model openrouter/auto --print "Say 'Aperture Science online'"`. Verified clean `Aperture Science online.` response with exit code 0.

## Next Session Recommendations
1. Deploy `clan machines update z0r0` to make the extreme-router unit drop-in permanent in z0r0's nix closure.
2. Review remaining ExtremeRouter combo cascade providers (e.g. refresh antigravity tokens or promote openrouter/local-slm in the cascade).
