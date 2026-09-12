# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `kong-dual-upstreams-herdr-fix`
- **Last verified green:** `./init.sh` green; `z0r0`, `luffy`, `nami` system builds and evaluations passed 100%. `z0r0.config.programs.herdr.enable=true`, `z0r0.config.layers.layer-78.llm-routers.extreme-router.enable=true`, `nami.config.services.ai-services.kong-gateway.enable=true`, `nami.config.services.ai-services.omniroute.enable=true`.
- **Blockers:** None.

## Work Completed This Session
1. **Herdr AI Coding Agent Harness Refactor (`programs.herdr`)**:
   - Refactored `layers/70-agents/71-harness/herdr.nix` into `programs.herdr` module schema with freeform TOML `settings` written to `/etc/herdr/config.toml` & `/etc/xdg/herdr/config.toml`.
   - Pre-configured defaults: Catppuccin theme, kitty graphics, follow cwd, pane borders, outer borders, scrollbars, gaps, window title, resume agents on restore.
   - Added `herdr-setup-workspaces` helper script to initialize workspaces for `opencode`, `hermes`, and `antigravity-cli`.
   - Enabled `programs.herdr.enable = lib.mkDefault true;` in `layers/90-profiles/tags/ai-agent.nix`.
2. **Kong Gateway Dual Upstreams (ExtremeRouter + OmniRoute)**:
   - Updated `layers/70-agents/78-llm-routers/kong-gateway.nix` to run both `extremerouter-llm` (`http://z0r0:20128`) and `omniroute-llm` (`http://127.0.0.1:20129`) simultaneously.
   - Removed obsolete `codingRouter` enum and single-upstream XOR logic.
   - Added dual route rules (`/v1/*`, `/er/v1/*`, `/omni/v1/*`) with key-auth authentication.
   - Added dual request-transformer templates in `kong-secrets.nix`.
3. **ExtremeRouter Loopback & Tailnet Interface Binding**:
   - Updated `layers/70-agents/78-llm-routers/extreme-router.nix` port mapping to `${toString cfg.port}:20128`.
   - Restricted firewall to `networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ cfg.port ];` (no WAN exposure).
4. **OmniRoute Port Allocation & Homepage Dashboard**:
   - Set OmniRoute port to `20129` on `nami` in `omniroute.nix` and `homepage-dashboard.nix`.
   - Updated homepage dashboard labels from legacy `sanji` to `nami`.
5. **Documentation Updates**:
   - Updated `ports.md`, `services.md`, `agent-layers.md`, `post-rebuild-setup.md`, `kong-README.md`, `README.md`.

## Next Workstreams
1. **Fleet deployment**:
   - `clan machines update z0r0`
   - `clan machines update nami`
   - `clan machines update luffy`
2. **Runtime Verification**:
   - `curl -s http://nami:8090/v1/models -H "apikey: $KONG_KEY_HERMES" | jq '.data|length>0'`
   - `curl -s http://nami:8090/omni/v1/models -H "apikey: $KONG_KEY_HERMES" | jq '.data|length>0'`
   - Run `herdr-setup-workspaces` on `z0r0` to populate workspaces.
