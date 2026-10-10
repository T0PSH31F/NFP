# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `homepage-launch-urls-fleet-services-constellation`
- **Last verified green:**
  - `./init.sh --worktree` -> PASSED (5/5 checks passed across all 3 machines)
  - `nix build .#checks.x86_64-linux.homepage-contract-coverage` -> PASSED (100% service coverage & validity)
  - `nix build .#checks.x86_64-linux.tailnet-dns-guard` -> PASSED (all 8 checks passed)
  - `nix build .#checks.x86_64-linux.luffy-service-scope` -> PASSED
  - `nix build .#checks.x86_64-linux.homepage-dashboard-test.driver` -> PASSED (driver and test derivations generated)
  - Evaluated fleet toplevels clean: `z0r0`, `luffy`, `nami`
  - Real client diagnostics from `z0r0`: probed 22 live fleet endpoints over Pattern A `http://${host}.nfp.nix:${port}`
- **Blockers:** None. Deployment/push awaiting Erik's review packet confirmation.

## Work Completed This Session
1. **Launch URL Architecture & Diagnosis**:
   - Diagnosed root cause of broken "Board Ship" links: prior config generated `http://${svc.tailnetName}.nfp.nix` for services with TLS != none; Headscale / Tailscale MagicDNS only registers host nodes (`luffy.nfp.nix`, `z0r0.nfp.nix`, `nami.nfp.nix`) and returns NXDOMAIN for arbitrary subdomains; Let's Encrypt rejected ACME for `.nfp.nix` (non-public TLD).
   - Added `homepage.dashboardUrl` option to `mkServiceContract.nix` to cleanly separate backend/upstream endpoint, server-side metrics endpoint, local health endpoint, external/client reachability probe, and user-facing dashboard URL.
   - Updated `homepage-dashboard.nix` URL resolution: resolves explicit `dashboardUrl` if set, otherwise falls back to Pattern A `http://${mkTailnetHost host}:${port}`.
2. **Recursion-Safe Fleet Contract Aggregation**:
   - Upgraded `homepage-dashboard.nix` to aggregate remote service contracts across all evaluated `inputs.self.nixosConfigurations` without evaluation recursion by strictly filtering out `localHost`.
   - Distinguishes multi-instance services via `${id}@${remoteName}` while displaying host provenance (`${title} (${remoteHost})`).
3. **Missing Fleet Services Restoration**:
   - Netdata: Updated policy per Erik's directive. Re-enabled on Homepage across `luffy`, `z0r0`, and `nami` on port 19999, bound to `0.0.0.0`, opened firewall, labeled with machine hostnames. Updated `flake/checks.nix` and `homepage-contract-coverage-test.nix`.
   - Headplane: Fixed default port collision (3000 collided with Hermes Workspace on `nami`), allocated port 3050 in `ports.md` and firewall, added `HEADPLANE_CONFIG_PATH = "${headplaneConfig}"` and `/etc/headplane/config.yaml` symlink, updated icon to `headplane`.
   - OmniRoute: Changed compose container port binding from `127.0.0.1:${port}:20128` to `${port}:20128`, opened firewall on `nami`, updated contract host to `config.networking.hostName`.
   - Paperclip: Reconciled port collision (default was 3100 colliding with Loki), set port to 3101 per `ports.md`, bound to `0.0.0.0`, replaced localhost public URL with `${host}.nfp.nix:3101`.
   - AionUI: Added explicit `nfp.services.aionui` contract with `icon = "aionui"`, bound to `0.0.0.0`, opened firewall.
   - File-manager: Audited existing `filebrowser` service on `nami:8085` (already returning 200 OK). Added to `requiredServices` in coverage test.
   - Loki: Split contract from Grafana in `monitoring.nix`. Provided dedicated "Loki Logs" entry pointing to Grafana Explore (`http://${host}.nfp.nix:3008/explore`).
   - Grafana: Bound to `0.0.0.0` port 3008 with icon `grafana`.
   - Prometheues & Glances: Validated contracts and icons.
   - Matrix Synapse: Set `dashboardUrl = "https://${settings.app_domain}"` (Element Web).
   - Created missing local SVG icons: `headplane.svg`, `aionui.svg`, `loki.svg`.
4. **Constellation Layout & Truthful Telemetry**:
   - In `homepage-theme.css`: added `min-width: 0` to `.services-grid > *` and `.wanted-card`, removed overflow-clipping risks, bounded constellation to 420x420 with responsive tablet/mobile fallback (`@media (max-width: 768px)`).
   - In `homepage-theme.js`: added `role="button" tabindex="0"` and keyboard navigation (`Enter`/`Space`) to Stella and satellites; replaced fake `99.9%` uptime with "Not measured" / live stats; defaulted snail to checking state; dynamically updated category summaries to `${reachable}/${total} REACHABLE`.
5. **Acceptance Tests**:
   - Updated `layers/00-cyberia/05-tests/homepage-dashboard.nix` with explicit assertions for Pattern A URLs, custom dashboard URLs, zero localhost leaks, keyboard accessibility, and truthful indicators.

## Next Workstreams
1. Present 10-point review packet to Erik.
2. Await Erik's explicit confirmation before deploying with `clan machines update`.
