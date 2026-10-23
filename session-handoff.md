# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `desktop-resilience-agent-mcp-cleanup-and-browser-homepage`
- **Last verified green:**
  - `./init.sh --worktree` -> PASSED (5/5 checks passed across all 3 machines: `luffy`, `z0r0`, `sanji`)
  - `curl -sf http://127.0.0.1:8089/healthz` -> PASSED (`pi-durable-daemon` active)
  - `curl -sf http://luffy.nfp.nix:3007/` -> PASSED (`NFP Homepage Dashboard` running)
  - `nfp-todo list --rofi` -> PASSED (multi-agent fenced sections and write guards verified)
- **Blockers:** Awaiting confirmation to commit and deploy via `clan machines update sanji`.

## Work Completed This Session

1. **Status Bar Launch Resilience (`32-nixarchy-rise/default.nix`)**:
   - Added `exec-once = systemctl --user start --no-block nixarchy-state-init.service omarchy-shell.service quickshell-rise.service` in `hypr/experiences/nixarchy-rise.conf`.
   - Guarantees Quickshell Rise bar and Omarchy shell launch even if session manager (UWSM) is bypassed or after raw TTY restart.

2. **Pi, Antigravity & Kiro MCP Pruning (`pi-coding-agent.nix`, `antigravity.nix`, `kiro-cli.nix`)**:
   - Purged dead/retired phantom endpoints (`context-forge` and `hermes-a2a`) that were failing in Pi's runtime.
   - Restored `mcp-nixos` (`lib.getExe pkgs.mcp-nixos`) in Pi and Kiro CLI.
   - Immediately refreshed user-level runtime files (`~/.pi/agent/mcp.json` and `~/.config/pi/agent/mcp.json`).

3. **Hermes Skills Context Token Optimization & MCP Sanitization (`hermes.nix`)**:
   - Enabled `coding_context: focus` under `agent:` to activate Hermes' built-in category compaction, shrinking prompt index tokens by ~85% while keeping all skills loadable via `skill_view`.
   - Disabled 10 missing-dependency toolsets (`browser-cdp`, `computer_use`, `feishu_doc`, etc.).
   - Purged failing/unpinned MCP servers (`brain-service`, `codegraph`, `headroom`, `ncp`, `forage`, `mistral`) and wired `mcp-nixos`.
   - Converted `custom_providers` from a legacy dictionary into the required YAML list format.

4. **Declarative Browser Homepage Dashboard (`brave.nix`, `firefox.nix`, `qutebrowser.nix`)**:
   - Brave: System-wide (`/etc/brave/policies/managed/` and `/etc/chromium/policies/managed/`) and user-level (`~/.config/BraveSoftware/Brave-Browser/policies/managed/`) policies for `HomepageLocation`, `NewTabPageLocation`, and `RestoreOnStartupURLs` pointing to `http://luffy.nfp.nix:3007/`.
   - Firefox: `policies.Homepage` pointing to `http://luffy.nfp.nix:3007/`.
   - Qutebrowser: Canonical default `dashboardUrl = "http://luffy.nfp.nix:3007/"`.

5. **Nixpkgs Priority Attribute Fix (`camofox-browser.nix`)**:
   - Fixed `lib.lowPriority` to `lib.lowPrio`.

## Next Workstreams

1. Commit all modified files and run `clan machines update sanji`.
2. Verify `brave` and `pi` live post-activation.
