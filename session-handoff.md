# Session Handoff

## Last Session Accomplishments
1. **Secondary Fleet Audit & Live Prometheus Verification**:
   - Polled live Prometheus on `luffy:9090` (`100.64.0.3`): verified that 53 of 56 targets are active and UP.
   - Verified that Grafana on `luffy:3008` is responding HTTP 200 with all 7 dashboards valid and wired to `prometheus` and `loki`.
   - Verified that Hermes Agent (`:8642`), Brain Service (`:8010`), and Pi Durable Daemon (`:8089`) are healthy and returning HTTP 200 on `luffy`.

2. **Five Critical Defects & Regressions Remedied**:
   - **Mopidy Tag Priority Conflict**: Re-scoped `mopidy.enable = lib.mkOptionDefault false;` in [`layers/90-profiles/tags/desktop.nix`](file:///home/t0psh31f/Clan/NFP/layers/90-profiles/tags/desktop.nix) to prevent collision with `media.nix`.
   - **Jev Exporter Permissions**: Fixed `status=238/STATE_DIRECTORY` failure by setting `DynamicUser = false; User = "root";` in [`layers/70-agents/70-jev/jev-exporter.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/70-jev/jev-exporter.nix), granting read access to `/var/lib/jev-engine/metrics.json`.
   - **Matrix Synapse Metrics 404**: Added `settings.enable_metrics = true;` to [`layers/20-services/28-clan-services/matrix-synapse/module.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/28-clan-services/matrix-synapse/module.nix) so Synapse serves `/_synapse/metrics`.
   - **Port 8888 Collision**: Removed erroneous `otel-collector` scrape on port 8888 in [`layers/20-services/26-monitoring/monitoring.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/26-monitoring/monitoring.nix), resolving collision with SearXNG.
   - **Mautrix PostgreSQL Assertion Failure**: Removed `ensureDBOwnership = true;` on `mautrix-meta-instagram` and `mautrix-meta-facebook` in [`layers/20-services/24-communication/mautrix.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/24-communication/mautrix.nix), aligning with existing database ownership of `mautrix-instagram` and `mautrix-facebook`.

## Verification Evidence
1. `./layers/00-cyberia/06-scripts/nfp-check.sh static`: Clean exit (code 0).
2. `./layers/00-cyberia/06-scripts/nfp-check.sh eval`: Remote evaluation on `100.64.0.1` (`z0r0`) passed across `z0r0`, `luffy`, and `sanji`.
3. Verified live Prometheus targets on `luffy`: 53/56 targets UP; eliminated all false-alarm and crashing service scrape targets.

## Next Actions / Deploy Instructions
- When ready to apply the latest fixes live to the cluster:
  ```bash
  clan machines update luffy
  clan machines update z0r0
  clan machines update sanji
  ```
