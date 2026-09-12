# NFP Homelab Cutover & Hardening Inventory

> Phase 0 inventory document for NFP fleet hardening. Source of truth for machine tags, media state directories, DNS, reverse proxies, monitoring, and backups.

---

## 1. Machine Tag Inventory

| Machine | Clan Target Host | Primary Role | Assigned Profile Tags |
| :--- | :--- | :--- | :--- |
| **`luffy`** | `root@100.64.0.3` (Tailscale) | Media, Memory, Homelab | `server`, `homelab`, `ai-agent`, `ai-server`, `pkb-node`, `gpu-compute`, `cache-server`, `media`, `intel-9th-gen` |
| **`z0r0`** | `root@127.0.0.1` | Workstation, Dev | `desktop`, `workstation`, `laptop`, `development`, `gaming`, `ai-agent`, `intel-12th-gen` |
| **`nami`** (or `sanji`) | `root@47.254.90.69` | Network & AI Control Plane | `server`, `homelab`, `network-router`, `ai-router`, `agent-orchestrator`, `media` |

---

## 2. Media Storage & State Paths

### Root-Owned Base Paths (`nixarr` Blocker Check)
`nixarr` requires all media and state paths to live under root-owned parents:
- **Media Parent Directory**: `/data/media` (placeholder local directory now; future mount point for external 2TB USB)
- **Backup Target Directory**: `/data/backups` (placeholder local directory now; future mount point for external 2TB USB; `nofail` option enabled)
- **State Parent Directory**: `/data/.state/nixarr`
- **Human Owner / User**: `t0psh31f` (included in `nixarr.mediaUsers`)

### Service Integration & Komga
- **Komga**: Cut over to `nixarr.komga.enable = true`. Legacy `layers/20-services/23-media/komga.nix` removed.

### Legacy Service State Migration Targets
Prior `/var/lib/*` directories to be migrated into `/data/.state/nixarr/` or managed by `nixarr`:
- Jellyfin: `/var/lib/jellyfin`
- Komga: `/var/lib/komga`
- Sonarr: `/var/lib/sonarr`
- Radarr: `/var/lib/radarr`
- Prowlarr: `/var/lib/prowlarr`
- Recyclarr: `/var/lib/recyclarr`
- SABnzbd: `/var/lib/sabnzbd`

---

## 3. Headscale Domain, MagicDNS & Virtual Hosts

- **Headscale Control Plane**: `https://headscale.lovelain.duckdns.org:8086`
- **MagicDNS Domain**: `*.ts.net` / `*.lovelain.duckdns.org`
- **Caddy Virtual Hosts**: Bound to Headscale / localhost loopback (`127.0.0.1`). WAN 80/443 public exposure disabled.
- **Service HTTPS Routing**: Tailscale / Headscale TLS certs or Caddy tailnet listener.

---

## 4. WAN Firewall & Internet Access Policy

- **Outbound Internet**: Allowed unconditionally. Downloads, web browsing, updates, external API calls work normally.
- **Inbound WAN Ports**: Closed (80, 443, 8096, etc.). Eliminates exposure to internet port scanners and attack bots.
- **Remote UI Access**: Secure encrypted Headscale VPN tunnel required on client phone/laptop.

---

## 5. AdGuard DNS Allocation

- **Host**: `luffy` (homelab tag)
- **Plain DNS Listeners**: Port `53` on Headscale interface only.
- **DoH / DoT Listeners**: Enabled on localhost and Headscale interface.
- **Upstream DNS**: Encrypted client DNS (DoH/DoT to trusted resolvers like Quad9/Cloudflare over TLS).
- **Split DNS**: Headscale MagicDNS handles `*.ts.net` / local domain; all other DNS requests forwarded to AdGuard.

---

## 6. Monitoring & Telemetry Extension

- **Telemetry Framework**: `github:mrVanDalo/nixos-telemetry`
- **Local Scrapers**: OpenTelemetry collector + local scrapers on all fleet machines (`z0r0`, `luffy`, `nami`).
- **Central Storage Host (`luffy`)**: Prometheus + Loki + Grafana. Remote-write metrics and push logs from client machines (`z0r0`, `nami`) over Headscale.
- **Grafana Security**: Admin password injected via Clan SOPS (`sops.secrets.grafana_admin_password`). Insecure anonymous auth disabled. Bound to `127.0.0.1` + Caddy reverse-proxy.

---

## 7. Restic Backup Repositories & Snapshot Specs

Two restic backends configured in `restic-backups.nix`:
1. **Local Storage Target (`luffy`)**: `/data/backups` (`nofail` mount check). Placeholder local dir now; mount point for 2TB USB when plugged in. Includes media metadata & SQLite DBs.
2. **Cloud GCS Repository**: `rclone:gcs:...` using service account stored in Clan SOPS (`sops.secrets`). Excludes large video binary blobs to prevent cost overrun.

### Backup Inclusion Matrix
- `nixarr` state directory (`/data/.state/nixarr`)
- PostgreSQL dumps (`pg_dumpall` pre-hook) & SQLite *Arr DBs
- Caddy / AdGuard / Headscale state
- Monitoring / Telemetry dashboards and configuration
- Declarative `nfp.services.<name>.backup.paths`
