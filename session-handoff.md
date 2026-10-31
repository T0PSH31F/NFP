# Session Handoff

## Last Session Accomplishments
1. **Homepage Dashboard Vitals & Multi-Instance Card Deduplication**:
   - Swapped fleet vitals queries from decommissioned `nami` to `sanji` Netdata (`:19999`) in [`layers/20-services/26-monitoring/homepage-dashboard.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/26-monitoring/homepage-dashboard.nix).
   - Enabled Netdata on `sanji`: `layers.layer-20.services.config.netdata.enable = true;` in [`machines/sanji/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/sanji/default.nix).
   - Verified multi-instance grouping in [`layers/00-cyberia/02-assets/templates/homepage-theme.js`](file:///home/t0psh31f/Clan/NFP/layers/00-cyberia/02-assets/templates/homepage-theme.js): deduplicates identical cross-machine cards into a single clean card with dynamic node switcher pills (`[luffy] [z0r0] [sanji]`), status indicators, and direct quick links.

2. **Fleet Service Rebalancing (Paperclip, OmniRoute, ExtremeRouter, Headplane)**:
   - **Paperclip**: Enabled `layers.layer-76.orchestrators.paperclip.enable = true;` on `luffy` in [`machines/luffy/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/luffy/default.nix), disabled on `sanji` (`machines/sanji/default.nix`). Configured declarative PostgreSQL database and role provisioning in [`layers/70-agents/76-orchestrators/paperclip.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/76-orchestrators/paperclip.nix).
   - **ExtremeRouter**: Confined strictly to `z0r0` via `layers.layer-78.llm-routers.extreme-router.enable = true;` in [`machines/z0r0/default.nix`](file:///home/t0psh31f/Clan/NFP/machines/z0r0/default.nix), disabled on `sanji` and `luffy`.
   - **OmniRoute**: Enabled on `luffy` (`:20129`) via `services.ai-services.omniroute = { enable = true; port = 20129; environmentFile = config.sops.templates."omniroute-env".path; };` in `machines/luffy/default.nix`, disabled on `sanji`.
   - **Headplane**: Enabled on `luffy` (`:3050`) via `layers.layer-20.services.config.headplane = { enable = true; port = 3050; headscaleUrl = "http://127.0.0.1:8086"; };` in `machines/luffy/default.nix`.

3. **Syncthing & Impermanence Vaults**:
   - Expanded Syncthing in [`layers/20-services/25-data/syncthing.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/25-data/syncthing.nix) to sync `notes-vault` (`~/Notes`), `icons-vault` (`~/.icons`), `cursors-vault` (`~/.cursors`), and `background-vault` (`~/.background`) across `[ "z0r0" "luffy" "sanji" ]`.
   - Added `.icons` to user persisted directories in [`layers/10-system/15-filesystem/impermanence.nix`](file:///home/t0psh31f/Clan/NFP/layers/10-system/15-filesystem/impermanence.nix).

4. **Langfuse PostgreSQL TCP Trust**:
   - Diagnosed Prisma error P1010 caused by container UID 1001 failing Postgres peer socket auth and SCRAM password rejection.
   - Added trusted TCP loopback rules (`host langfuse all 127.0.0.1/32 trust` and `host paperclip all 127.0.0.1/32 trust`) in [`layers/20-services/25-data/postgresql-vectordb.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/25-data/postgresql-vectordb.nix).
   - Updated default `databaseUrl` to `postgresql://postgres@127.0.0.1:5432/langfuse` in [`layers/70-agents/73-memory/langfuse.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/73-memory/langfuse.nix).

5. **Complete Eradication of Kong Gateway**:
   - Stripped container definition from [`layers/70-agents/78-llm-routers/kong-gateway.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/kong-gateway.nix) while keeping tombstone option `enable = lib.mkForce false;`.
   - Stripped all Kong environment templates and consumer configs from [`layers/70-agents/78-llm-routers/kong-secrets.nix`](file:///home/t0psh31f/Clan/NFP/layers/70-agents/78-llm-routers/kong-secrets.nix).
   - Removed firewall ports 8090 and 8091 from [`layers/10-system/11-foundation/networking.nix`](file:///home/t0psh31f/Clan/NFP/layers/10-system/11-foundation/networking.nix).
   - Removed `kong` endpoint from [`layers/20-services/21-networking/endpoints.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/21-networking/endpoints.nix) and Prometheus Kong scrape job from [`layers/20-services/26-monitoring/monitoring.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/26-monitoring/monitoring.nix).
   - Updated agent harnesses (`claude-code.nix`, `codex.nix`, `hermes.nix`, `hermes-live-voice.nix`, `opencode.nix`) to route directly to ExtremeRouter (`http://127.0.0.1:20128/v1`) or Jev (`http://127.0.0.1:20127/v1`).

6. **Grafana Admin Credentials Retrieved**:
   - Decrypted credentials via SOPS:
     - **Username**: `admin`
     - **Password**: `G0!nc0c4nut5`

7. **NAS Mounts**:
   - Configured SMB 1.0 (`vers=1.0`) in [`layers/10-system/nas-mounts.nix`](file:///home/t0psh31f/Clan/NFP/layers/10-system/nas-mounts.nix) for the Buffalo LinkStation.
   - Identified that physical NAS at `192.168.1.158` is currently unpowered or disconnected on the LAN (100% packet loss).

## Verification Evidence
1. `./init.sh --worktree`: passed 5/5 with 0 errors across `z0r0`, `luffy`, and `sanji`.
2. `feature_list.json`: strictly 265 lines (< 300 line cap).
3. `statix` & `deadnix`: clean check with zero fatal errors.
