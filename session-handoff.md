# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `multi-desktop-matrix-otel-doctor-fleet-provisioning`
- **Last verified green:**
  - `./init.sh --worktree` -> PASSED (5/5 checks passed across all 3 machines: `z0r0`, `luffy`, `sanji`)
  - `treefmt --ci` -> PASSED (461 files formatted, 0 changes in 3.36s)
  - `deadnix` -> PASSED (0 unused declarations on touched experience, telemetry, and ISO paths)
  - `nix build .#packages.x86_64-linux.installer-iso --dry-run` -> PASSED (clean ISO derivation `/nix/store/m03wqpvgyadys61zv1sm8m59dyhj12f1-nixos-minimal-26.11.20261011.7fd4004-x86_64-linux.iso.drv`)
  - `nfp-doctor --hardware` -> PASSED live on workstation
  - `nfp-doctor --mesh` -> PASSED live across Tailnet nodes (`luffy` 3ms RTT, `sanji` 57ms RTT direct WireGuard)
- **Blockers:** None.

## Work Completed This Session

1. **Multi-Desktop Matrix (`layers/40-desktop/`)**:
   - Implemented `layers.desktop.experience` enum selector in `43.0-selector.nix` supporting 8 presets: `noctalia-hyprland` (default), `noctalia-niri`, `noctalia-umbriel`, `nixarchy-rise`, `custom-vibe-quickshell`, `micro-smol-ai`, `headless-console`, `none` (default on server tag).
   - De-bled Noctalia variables out of base modules (`zsh.nix`, `34-qt`) into `43-noctalia/default.nix`.
   - Registered independent Wayland session `.desktop` files in `/run/current-system/sw/share/wayland-sessions/` via `services.displayManager.sessionPackages` across all experience modules for no-reboot DM switching.
   - Integrated Umbriel compositor with `xdg-desktop-portal-umbriel` in `layers/40-desktop/41-compositors/umbriel/`. Registered `41-compositors` in `layers/NUMBERING.md`.
   - Packaged hermetic derivations for Nixarchy Rise, mutable hot-reload Vibe-Lab (`~/.config/quickshell/active/`), and low-power `micro-smol-ai` (`cage` + `wlopm` 60s idle blanking).
   - Extended pluggable greeters in `layers/30-theming/32-boot/greeter.nix` with `regreet-wayland` and One Piece video loops.

2. **OpenTelemetry Telemetry Pipeline (`mrVanDalo/nixos-telemetry`)**:
   - Created `layers/20-services/26-monitoring/telemetry.nix` deploying OTel collector for metrics (Prometheus :9090), logs (Loki :3100), and traces (Grafana Alloy / Langfuse).
   - Authored Python client `telemetry_client.py` and skill in `layers/70-agents/79-skills/telemetry/`.
   - Created Donut Browser agent & Make workflow contract scaffolding (`input-config.yaml`, `import-config.yaml`, `make-modules.yaml`, `telemetry-mcp.json`, `telemetry-agent.yaml`).

3. **Enhanced Doctor Hardware & Mesh Diagnostics**:
   - Created `nfp-doctor.sh` CLI in `layers/00-cyberia/06-scripts/` supporting `--all`, `--hardware`, `--mesh`, `--firmware`.
   - Pass 1 audits CPU governor, microcode, throttling, GPU acceleration, SSD TRIM, and Btrfs health.
   - Pass 2 runs reachability and latency matrix over Tailnet (`z0r0`, `luffy`, `sanji`) verifying Direct WireGuard vs DERP relays and core services (Caddy, Kong :8090, Brain-Service :8010, Homepage :3007).
   - Documented OpenCode slash command in `layers/70-agents/71-harness/opencode/commands/doctor.md`.

4. **Zero-Touch Fleet Provisioning & Live ISO**:
   - Created `layers/00-cyberia/08-iso/nfp-installer-iso.nix` exporting `packages.x86_64-linux.installer-iso`.
   - Implemented automated `nfp-install-host` wizard formatting Btrfs impermanence subvolumes (`@root`, `@persist`, `@nix`, `@swap`), generating Age/SOPS machine keys, and enrolling node into Headscale Tailnet.
   - Documented fleet onboarding guide in `layers/00-cyberia/01-docs/FLEET_PROVISIONING.md`.

## Next Workstreams

1. Ready for review packet confirmation and remote deployment via `clan machines update`.
