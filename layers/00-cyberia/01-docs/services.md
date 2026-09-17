# NFP Services Reference

> Ports, URLs, and default logins for all services across the fleet.

## Machine Roles

| Machine | LAN IP | Role | Services |
|---------|--------|------|----------|
| **z0r0** (LG Gram 17) | 192.168.1.39 | Dev workstation, AI agent, media server | Hermes, monitoring, AdGuard, Jellyfin stack, llama.cpp |
| **luffy** (Custom Desktop) | 192.168.1.54 | Primary server, homelab, AI, cache | Caddy reverse proxy, Matrix, most *arr/media, all containers |

---

## z0r0 Services

| Port | Service | URL | Default Login |
|------|---------|-----|---------------|
| 53 | AdGuard Home (DNS) | `http://z0r0:3002` | `admin` / `admin` (change on first login) |
| 3002 | AdGuard Home (web) | `http://z0r0:3002` | `admin` / `admin` |
| 3000 | Hermes Workspace | `http://z0r0:3000` | User `t0psh31f` |
| 3001 | freellmapi (free LLM router, 339 models) | `http://z0r0:3001/v1` | First-run setup code in journal |
| 3005 | Langfuse (LLM tracing) | `http://z0r0:3005` | Auto-generated (see sops) |
| 3008 | Grafana | `http://z0r0:3008` | `admin` / sops `grafana_admin_password` |
| 3080 | Prometheus | `http://z0r0:3090` | No auth |
| 3100 | Loki | `http://z0r0:3100` | No auth |
| 8080 | Signal-CLI REST API | `http://z0r0:8080` | No auth (json-rpc mode) |
| 8081 | llama.cpp server | `http://z0r0:8081` | No auth |
| 8642 | Hermes Agent API | `http://z0r0:8642` | Via env token |
| 9119 | Hermes Dashboard | `http://z0r0:9119` | `admin` / sops-hashed password |
| 61208 | Glances (system monitor) | `http://z0r0:61208` | No auth |

### Also on z0r0 (no web UI):
- **Jellyfin** — if enabled via media-stack tag, port 8096
- **Ollama** — runs on luffy (port 11434), not z0r0. Access via Tailscale: `http://100.72.46.75:11434`
- **Fleet Healthcheck Runner** — CLI `fleet-healthcheck-runner` (service `fleet-healthcheck.service`, probe targets generated from `nfp.services` contracts)

---

## luffy Services

### Web Services (via Caddy reverse proxy)

| URL | Backend Port | Service | Default Login |
|-----|-------------|---------|---------------|
| `https://lovelain.duckdns.org` | 3007 | Homepage Dashboard | See widgets below |
| `https://chat.lovelain.duckdns.org` | 3004 | Ollama WebUI | `WEBUI_AUTH=false` (no login) |
| `https://adguard.lovelain.duckdns.org` | 3002 | AdGuard Home | `admin` / `admin` |
| `https://n8n.lovelain.duckdns.org` | 5678 | n8n workflow | Set on first login |
| `https://vault.lovelain.duckdns.org` | 8222 | Vaultwarden | Register first account (becomes admin) |
| `https://spotify.lovelain.duckdns.org` | 3457 | Your Spotify | Set on first login |
| `https://headscale.lovelain.duckdns.org` | 8086 | Headscale | CLI `headscale` on luffy |
| `https://matrix.lovelain.duckdns.org` | 8443 | Matrix Synapse | Admin: `t0psh31f` |
| `https://element.lovelain.duckdns.org` | 8444 | Element Web | Login via Matrix |
| `https://crawl4ai.lovelain.duckdns.org` | 32775 | Crawl4AI | No auth |
| `https://skyvern.lovelain.duckdns.org` | 32776 | Skyvern UI | Set on first login |
| `https://simstudio.lovelain.duckdns.org` | 32790 | Sim Studio | No auth |
| `https://maxkb.lovelain.duckdns.org` | 32784 | MaxKB | `admin` / `admin` |
| `https://spacedrive.lovelain.duckdns.org` | 32768 | Spacedrive | Auth disabled |
| `https://openclaw.lovelain.duckdns.org` | 59879 | OpenClaw | Via API token |
| `https://kavita.lovelain.duckdns.org` | 5000 | Kavita e-reader | `admin` / `admin` |

### Direct Port Access (luffy LAN)

| Port | Service | Default Login |
|------|---------|---------------|
| 22 | SSH | User `t0psh31f` via SSH key |
| 53 | AdGuard DNS | — |
| 3007 | Homepage Dashboard | `admin` / `admin` (widgets) |
| 5000 | Harmonia (nix cache) | No auth (LAN) |
| 5678 | n8n | Set on first login |
| 8008 | Matrix Synapse (internal) | Token auth |
| 8082 | Open WebUI | `WEBUI_AUTH=false` |
| 8085 | FileBrowser | Set on first login |
| 8096 | Jellyfin | Set on first login |
| 8123 | Home Assistant | Set on first login |
| 8222 | Vaultwarden | Register first account |
| 8888 | SearXNG | No auth |
| 11434 | Ollama API | No auth (LAN) |
| 5432 | PostgreSQL (ai/vectordb) | `trust` (local), `md5` (host) |

### Media Services (luffy)

| Port | Service | Default Login |
|------|---------|---------------|
| 7878 | Radarr | API key in `/var/lib/radarr` |
| 8787 | Readarr | API key in `/var/lib/readarr` |
| 8989 | Sonarr | API key in `/var/lib/sonarr` |
| 9696 | Prowlarr | API key in `/var/lib/prowlarr` |
| 8096 | Jellyfin | Set on first login |
| 8112 | Deluge | Auto-generated random password |
| 8080 | qBittorrent | `admin` / `adminadmin` |
| 9091 | Transmission | RPC whitelist disabled |
| 6800 | Aria2 RPC | Auto-generated secret |
| 8081 | SABnzbd | Set on first login |
| 6789 | NZBGet | Set on first login |
| 5076 | NZBHydra2 | Set on first login |

### OCI Containers (luffy — port range 32768-32790)

| Port | Container | Default Login |
|------|-----------|---------------|
| 32768 | Spacedrive API | Auth disabled |
| 32769 | Spacedrive Web | Auth disabled |
| 32775 | Crawl4AI | No auth |
| 32776 | Skyvern UI | Set on first login |
| 32779 | Skyvern API | Token auth |
| 32780 | Skyvern Chrome | No auth |
| 32784 | MaxKB | `admin` / `admin` |
| 32789 | Sim Studio RT | No auth |
| 32790 | Sim Studio | No auth |

### Mautrix Bridges (luffy — Matrix <-> Chat)

| Port | Bridge | Port | Bridge |
|------|--------|------|--------|
| 29317 | Telegram | 29328 | Signal |
| 29318 | WhatsApp | 29330 | Instagram |
| 29319 | Facebook | 29334 | Discord |
| 29320 | Google Chat | 29335 | Slack |
| 29327 | Twitter | 29336 | Google Messages |

---

## Hermes Agent (z0r0 — 16 Personalities)

| Endpoint | Port | Purpose |
|----------|------|---------|
| MCP Gateway | 8085 | Tool orchestration |
| Dashboard | 9119 | Admin panel (`admin` / sops password) |
| API Server | 8642 | Agent API |

Set personality: `export HERMES_PERSONA=glados`

| Persona | Description |
|---------|-------------|
| `jarvis` (default) | Formal, dry British humor, addresses "Sir" |
| `glados` | Sarcastic, passive-aggressive, 1-2 sentences |
| `hal` | Soft-spoken, polite, no contractions, "Dave" |
| `cortana` | Witty, tactical, loyal |
| `pirate` | "Arrr, ye be talkin' to Captain Hermes" |
| `catgirl` | Anime, "nya~", (=^･ω･^=) |
| `kawaii` | (◕‿◕) Sparkles and warmth |
| `noir` | Film noir detective |
| `noir` | Film noir detective |
| `shakespeare` | Bardic prose |
| `surfer` | "Duuude, totally rad" |
| `uwu` | *nuzzles your code* OwO |
| `hype` | OVER-THE-TOP ENTHUSIASM |
| `philosopher` | Contemplates deeper meaning |
| `teacher` | Patient explanations |
| `samantha` | Warm, empathetic (from Her) |
| `adjutant` | Clinical, monotone, tactical |
| `concise` | Brief, to the point |
| `creative` | Outside-the-box |
| `helpful` | Friendly |
| `technical` | Detailed |

---

## Credential Management

### Where passwords live

| Source | Format | How to Read |
|--------|--------|-------------|
| **sops secrets** (external_services.yaml) | Encrypted at rest | `sops layers/00-cyberia/03-treasure/secrets/external_services.yaml` |
| **Auto-generated** (on first deploy) | Random (openssl) | Check systemd service files or `/var/lib/<service>/` |
| **Clan vars** | Nix-defined + prompted | `clan vars list <machine>` |
| **Default passwords** (change on first login) | Hardcoded defaults | See table below |

### Services with auto-generated credentials

| Service | Credential | Location |
|---------|-----------|----------|
| Vaultwarden admin token | Random (openssl) | Check service journal |
| Langfuse NEXTAUTH_SECRET | Random (openssl) | Check service journal |
| Nextcloud admin password | Random (openssl) | `nixos-rebuild` output |
| Harmonia signing key | Auto-generated | `/var/lib/harmonia/` |
| Deluge auth | Random (openssl) | `/var/lib/deluge/auth` |
| Aria2 RPC secret | Random (base64) | `/var/lib/aria2/` |
| SearXNG secret key | Random (openssl) | `/var/lib/searxng/searxng-settings.yml` |

### Common default credentials (CHANGE ON FIRST LOGIN)

| Service | Username | Password |
|---------|----------|----------|
| AdGuard Home | `admin` | `admin` |
| Grafana | `admin` | sops `grafana_admin_password` |
| Homepage Dashboard | `admin` | `admin` (widgets) |
| qBittorrent | `admin` | `adminadmin` |
| Kavita | `admin` | `admin` |
| MaxKB | `admin` | `admin` |
| Hermes Dashboard | `admin` | sops-hashed (hardcoded in hermes.nix) |

---

## First-Time Setup

After deploying via `clan machines update`, some services need manual steps:

### Pre-pull OCI container images (luffy)
All OCI containers use pinned digests. Pull them explicitly so systemd
doesn't fail on first start:

```bash
# From luffy
sudo podman pull public.ecr.aws/skyvern/skyvern-ui@sha256:...
sudo podman pull public.ecr.aws/skyvern/skyvern@sha256:...
sudo podman pull ghcr.io/browserless/chromium@sha256:...
sudo podman pull ghcr.io/simstudioai/simstudio@sha256:...
sudo podman pull unclecode/crawl4ai@sha256:...
sudo podman pull 1panel/maxkb@sha256:...
sudo podman pull ghcr.io/spacedriveapp/spacedrive/server@sha256:...

# Or restart failing services to trigger pull:
sudo systemctl restart podman-skyvern-api
sudo systemctl restart podman-skyvern-ui
```

### First-login setup for web services

| Service | What to do |
|---------|------------|
| **AdGuard Home** | Visit `http://<machine>:3002`, set admin password on first visit |
| **Vaultwarden** | Visit `https://vault.lovelain.duckdns.org`, register first account (becomes admin) |
| **Jellyfin** | Visit `http://<machine>:8096`, create admin account on first launch |
| **Home Assistant** | Visit `http://luffy:8123`, onboard (takes ~10 min on first boot) |
| **n8n** | Visit `https://n8n.lovelain.duckdns.org`, create admin account |
| **Grafana** | `admin` / sops `grafana_admin_password` |
| **qBittorrent** | `http://luffy:8080`, user `admin` / `adminadmin` |
| **MaxKB** | `https://maxkb.lovelain.duckdns.org`, `admin` / `admin` |
| **Kavita** | `https://kavita.lovelain.duckdns.org`, `admin` / `admin` |
| **Homepage Dashboard** | Widgets use `admin` / `admin` |

### Seed the Hermes agent .env
The Hermes activation script now merges sops secrets automatically.
Verify it worked:

```bash
journalctl -u hermes-agent --no-pager | head -20
# Should NOT show "cat: ... input file is output file"
```

### Fix user/group IDs (impermanence)
If you see impermanence UID warnings:
```
Neither /var/lib/nixos nor any of its parents are persisted.
The following users are missing a uid: ...
```

This is cosmetic unless you need stable UIDs across reboots. To fix:

```bash
# Add to impermanence config:
sudo mkdir -p /persist/var/lib/nixos
```

Then ensure `environment.persistence."/persist".directories` includes
`/var/lib/nixos` in `layers/10-system/15-filesystem/impermanence.nix`.

### Verify all services are running

```bash
sudo systemctl list-units --type=service --state=running | grep -c "\.service"
# Should be 80+ on luffy, 40+ on z0r0

# Check for failed units
sudo systemctl --failed
```

## Quick Commands

```bash
# Check service status
systemctl status hermes-agent
systemctl status jellyfin

# View auto-generated credentials
journalctl -u vaultwarden | grep "admin token"

# Read sops secrets
sops layers/00-cyberia/03-treasure/secrets/external_services.yaml

# List all running services on current machine
systemctl list-units --type=service --state=running | grep -E "(caddy|adguard|jellyfin|sonarr|radarr|hermes|ollama)"

# Check open ports
ss -tlnp
```

## Configuration Files

| Service | Config Path |
|---------|------------|
| All services | `layers/20-services/<category>/<service>.nix` |
| Hermes agent | `layers/70-agents/76-hermes-agent/hermes.nix` |
| Reverse proxy (Caddy) | `layers/20-services/21-networking/caddy.nix` |
| Machine-specific | `machines/z0r0/default.nix` or `machines/luffy/default.nix` |
| Tag profiles | `layers/90-profiles/tags/<tag>.nix` |

## CLI-Only Services (No Web UI)

| CLI Tool | Purpose | Primary Location | Command / Setup |
|----------|---------|------------------|-----------------|
| **OpenCode** | Multi-provider terminal AI agent | `layers/70-agents/71-coding/opencode.nix` | `opencode` |
| **Claude Code** | Anthropic CLI agent | `layers/70-agents/` | `claude` |
| **Hermes CLI** | Hermes autonomous agent CLI | `layers/70-agents/76-hermes-agent/` | `hermes` |
| **pxpipe** | PyPI pipeline tool (intentionally non-Nix) | User environment (`pipx`/`uv`) | `pipx install pxpipe` (persisted in `/persist/home/*/.local`) |
| **clan** | Clan machine deployment CLI | `flake.nix` | `clan machines update` |

