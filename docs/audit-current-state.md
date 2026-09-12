# NFP Fleet Architecture & Current State Audit

*Date: 2026-09-10*

## 1. Fleet Inventory

| Host Name | Legacy Name | Primary Role & Hardware | Core Tags / Profiles | Persistence & Boot |
|-----------|-------------|-------------------------|----------------------|--------------------|
| **z0r0** | `z0r0` | Daily driver laptop workstation | `workstation`, `desktop`, `laptop`, `development` | Btrfs Impermanence (`/persist`), Linux Zen |
| **luffy** | `luffy` | Homelab / PKB / Media / Local AI node | `homelab`, `media-server`, `pkb-node`, `server` | Btrfs Impermanence (`/persist`), Linux CachyOS, NVIDIA 580 |
| **nami** | `nami` | Cloud control plane (Alibaba ECS `47.254.90.69`) | `network-router`, `ai-router`, `agent-orchestrator` | Standard ext4 root (Cloud VM), Headless Linux |

---

## 2. Core Subsystems Audit

### A. Networking & Mesh Infrastructure
- **Headscale Control Plane**: Active on `nami` (`headscale.nix`, port 8086).
- **Tailscale Clients**: Configured via `layers/20-services/21-networking/tailscale.nix` targeting `https://headscale.lovelain.duckdns.org`.
- **Legacy Meshes**: ZeroTier and Clan WireGuard fully decommissioned across `networking.nix` and `network-setup-guide.md`.
- **ACLs & MagicDNS**: Wildcard ACL currently applied (`/var/lib/headscale/acl/hujson`). Basic DNS enabled in Headscale options (`base_domain = "grandlix.net"`). Needs hardening for admin vs guest scopes and canonical hostname alignment.

### B. SSH & Emergency Access
- **Primary Admin Access**: OpenSSH over Tailnet. Key-only auth enforced on `nami` (`PasswordAuthentication = false`, `PermitRootLogin = "prohibit-password"`).
- **Break-Glass Access**: Cloud console for `nami`, physical console / live USB for `z0r0` and `luffy`.

### C. Homepage & Service Dashboards
- **Homepage Module**: Implemented in `layers/20-services/26-monitoring/homepage-dashboard.nix` (runs on `luffy:3007` and `nami`).
- **Reverse Proxy**: Caddy handles DuckDNS routing (`*.lovelain.duckdns.org`) on `luffy` and `nami`.
- **Multi-Machine Link Validation**: Script `layers/00-cyberia/06-scripts/validate-tailnet-mesh.sh` and test suite `homepage-dashboard.nix` present.

### D. Data Synchronization & Backups
- **Syncthing**: **Not yet implemented** in `layers/20-services/25-data/`.
- **Restic + Rclone Backups**: Implemented in `layers/20-services/25-data/restic-backups.nix`. Features Google Drive primary target, Teldrive secondary target, `pg_dumpall` pre-hook, and `restic-restore-drill` helper tool.

### E. Monitoring & Observability
- **Prometheus & Grafana**: Implemented in `layers/20-services/26-monitoring/monitoring.nix`.
- **Log Aggregation**: Alloy log shipper -> Loki aggregator.
- **Alerting**: `alertmanager-ntfy.nix` routes alerts to `ntfy.sh`.
- **Exporters**: Node exporter, Postgres, Wireguard, Caddy, Synapse, n8n, Exportarr (Sonarr, Radarr, etc.), qBittorrent, Tailscale, Langfuse exporter.

### F. Media & Self-Hosted Stack
- **Stack**: Jellyfin, Sonarr, Radarr, Readarr, Prowlarr, Bazarr, Recyclarr, Calibre-web, Kavita, Usenet, qBittorrent.
- **Nixarr Patterns**: Storage paths and container structures partially integrated.

### G. Desktop & Terminal Environment
- **Multiplexer**: `zellij.nix` and `yazelix-nova.nix` (`layers/50-cli-tui-programs/51-shells/yazelix-nova.nix`). Yazelix updated to Nova integration.
- **Desktop UI**: Hyprland + Noctalia greeter/shell on `z0r0` and `luffy`.

### H. Installer & Recovery ISO
- **Module**: `layers/00-cyberia/08-iso/noctalia-installer.nix`. Custom Hyprland GUI installer ISO with security/recovery tooling and SOPS integration.
