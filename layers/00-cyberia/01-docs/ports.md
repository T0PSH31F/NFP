# Port Allocation Registry

> **Last updated:** 2026-08-21  
> **Purpose:** Canonical reference for all network port allocations across the fleet to prevent conflicts.  
> **NOTE:** This port allocation registry MUST be regenerated/updated whenever service port assignments or module defaults change.

## Legend
- **z0r0** = LG laptop workstation (`127.0.0.1` / Tailscale)
- **luffy** = Intel 9th-gen homelab server (`100.80.146.120` / Tailscale)
- **Both** = Deployed on both workstation and server

---

## Unified Fleet Port Registry

| Port     | Service                | Host   | Config Module Location                             | Notes / Interface               |
|:--------:|:-----------------------|:------:|:---------------------------------------------------|:--------------------------------|
| **22**   | SSH                    | Both   | System Foundation                                  | Secure Shell access             |
| **53**   | AdGuard DNS            | luffy  | `layers/20-services/21-networking/adguard.nix`    | DNS resolution & filtering      |
| **389**  | Vaultwarden LDAP       | luffy  | `layers/20-services/25-data/vaultwarden.nix`      | Internal LDAP auth              |
| **465**  | Himalaya SMTPS         | z0r0   | `layers/50-cli-tui-programs/53-tools/`             | Email client SMTP               |
| **993**  | Himalaya IMAPS         | z0r0   | `layers/50-cli-tui-programs/53-tools/`             | Email client IMAP               |
| **1337** | Jan AI                 | z0r0   | `layers/74-ai-infra/jan.nix`                       | Local AI Desktop API            |
| **3000** | Hermes Workspace       | z0r0   | `layers/70-agents/71-harness/hermes/`              | Hermes Agent Web GUI            |
| **3001** | HedgeDoc               | z0r0   | `machines/z0r0/default.nix`                        | Collaborative Markdown Editor   |
| **3002** | AdGuard Web            | luffy  | `layers/20-services/21-networking/adguard.nix`    | AdGuard Admin Dashboard         |
| **3003** | FreeLLMAPI             | z0r0   | `layers/70-agents/78-llm-routers/freellmapi.nix`  | Free-tier LLM API Router        |
| **3005** | Langfuse               | z0r0   | `layers/70-agents/73-memory/langfuse.nix`         | LLM Observability & Tracing     |
| **3006** | AionUI                 | z0r0   | `layers/70-agents/76-orchestrators/aionui.nix`    | AI Cowork Web Interface         |
| **3007** | N8N Web / Karakeep     | luffy  | `machines/luffy/default.nix`                       | Workflow Automation Primary     |
| **3008** | Grafana                | Both   | `layers/20-services/26-monitoring/`                | System Observability Dashboard  |
| **3099** | Mission Control        | z0r0   | `machines/z0r0/default.nix`                        | Container & Task Manager        |
| **3100** | Loki                   | z0r0   | `machines/z0r0/default.nix`                        | Log Aggregation Backend         |
| **3101** | Paperclip              | z0r0   | `layers/20-services/26-monitoring/`                | Task & Automation Agent         |
| **3333** | Mistral MCP            | z0r0   | `machines/z0r0/default.nix`                        | Mistral AI Tool Protocol        |
| **3457** | YourSpotify            | luffy  | `layers/20-services/24-communication/`             | Spotify Listening Analytics     |
| **5000** | Harmonia Nix Cache     | luffy  | `layers/20-services/28-clan-services/`             | Binary Cache Server             |
| **5050** | Kavita                 | luffy  | `layers/20-services/26-monitoring/`                | E-book & Digital Library        |
| **5432** | PostgreSQL             | Both   | System Services                                    | Relational Database             |
| **5678** | N8N Webhook            | luffy  | `machines/luffy/default.nix`                       | Workflow Automation Webhook     |
| **5680** | OpenCompany UI         | luffy  | `layers/70-agents/76-orchestrators/opencompany.nix` | AI Org Web Interface   |
| **5681** | OpenCompany Backend    | luffy  | `layers/70-agents/76-orchestrators/opencompany.nix` | AI Org Python Server   |
| **6080** | Camofox VNC            | z0r0   | `layers/20-services/24-communication/`             | Browser VNC Viewport            |
| **6333** | Qdrant HTTP            | z0r0   | `layers/20-services/25-data/qdrant.nix`             | Vector Database REST API        |
| **6334** | Qdrant gRPC            | z0r0   | `layers/20-services/25-data/qdrant.nix`             | Vector Database gRPC            |
| **6380** | Nextcloud              | luffy  | `layers/20-services/25-data/nextcloud.nix`         | Cloud File Synchronization      |
| **6767** | Bazarr                 | luffy  | `layers/20-services/23-media/media-stack.nix`     | Subtitle Manager                |
| **6800** | Aria2                  | luffy  | `layers/20-services/23-media/download-clients.nix`| Download Daemon RPC             |
| **7878** | Radarr                 | luffy  | `layers/20-services/23-media/media-stack.nix`     | Movie Management                |
| **8000** | SillyTavern            | z0r0   | `layers/70-agents/77-dash-desk-ui/sillytavern.nix` | LLM Frontend Interface          |
| **8004** | ChromaDB               | z0r0   | `layers/20-services/25-data/chromadb.nix`          | Vector Database HTTP API        |
| **8008** | Matrix Synapse         | luffy  | `machines/luffy/default.nix`                       | Matrix Federation & Homeserver  |
| **8010** | Brain Service          | luffy  | `layers/70-agents/73-memory/brain-service.nix`    | Personal Knowledge Base API     |
| **8080** | Signal CLI             | z0r0   | `machines/z0r0/default.nix`                        | Signal Messenger REST Daemon    |
| **8081** | Kong Gateway (legacy)  | nami   | `layers/70-agents/78-llm-routers/kong-gateway.nix` | Deprecated stale reference      |
| **8082** | Homepage Dashboard     | z0r0   | `layers/20-services/26-monitoring/`                | Main Desktop Service Dashboard  |
| **8083** | FreeLLMPool            | z0r0   | `layers/70-agents/78-llm-routers/freellmpool.nix`  | Free-tier LLM Provider Pool     |
| **8084** | Paperless-ngx          | luffy  | `machines/luffy/default.nix`                       | Document Archival System        |
| **8085** | Hermes Agent Gateway   | z0r0   | `layers/70-agents/71-harness/hermes/`              | Hermes Agent MCP Control Gateway|
| **8086** | Headscale              | nami   | `layers/20-services/21-networking/headscale.nix`  | Tailscale Control Plane         |
| **8088** | Open WebUI             | luffy  | `layers/70-agents/77-dash-desk-ui/open-webui.nix` | LLM Web Chat Interface          |
| **8090** | Kong Gateway (proxy)   | nami   | `layers/70-agents/78-llm-routers/kong-gateway.nix` | Unified LLM/API gateway         |
| **8091** | Kong Admin API         | nami   | `layers/70-agents/78-llm-routers/kong-gateway.nix` | Kong declarative admin API      |
| **8092** | EverOS Memory Server   | z0r0   | `layers/70-agents/73-memory/everos.nix`           | Memory consolidation engine     |
| **8093** | CalibreWeb (luffy) / Kong Manager GUI (z0r0, loopback) | luffy  | `layers/20-services/26-monitoring/` | E-book Web Reader (luffy); Kong dashboard is loopback-only on z0r0 at `http://127.0.0.1:8093` |
| **8095** | qBittorrent WebUI      | luffy  | `layers/20-services/23-media/download-clients.nix`| Torrent Client Web Interface    |
| **8096** | Jellyfin               | luffy  | `layers/20-services/23-media/media-stack.nix`     | Media Streaming Server          |
| **8098** | RomM                   | luffy  | `layers/20-services/23-media/romm.nix`             | ROM Manager & Web Emulator      |
| **8099** | ntfy-sh                | Both   | `layers/20-services/26-monitoring/ntfy-sh.nix`     | Push Notification Service       |
| **8443** | HTTPS Alt 1            | luffy  | `machines/luffy/default.nix`                       | Secondary TLS Ingress           |
| **8444** | Element Web            | luffy  | `machines/luffy/default.nix`                       | Matrix Client Web App           |
| **8686** | Lidarr                 | luffy  | `layers/20-services/23-media/media-stack.nix`     | Music Collection Manager        |
| **8787** | Readarr                | luffy  | `layers/20-services/23-media/media-stack.nix`     | Book Collection Manager         |
| **8788** | Hermes Standalone WebUI| z0r0   | `layers/20-services/26-monitoring/`                | Hermes Standalone Web UI        |
| **8880** | Hermes Live Voice      | z0r0   | `layers/70-agents/76-hermes-agent/`                | Real-time Voice Control Gateway |
| **8888** | SearXNG                | luffy  | `layers/20-services/27-automation/`               | Meta Search Engine              |
| **8989** | Sonarr                 | luffy  | `layers/20-services/23-media/media-stack.nix`     | TV Series Management            |
| **9090** | Prometheus             | Both   | `machines/*/default.nix`                           | Metrics Collection Daemon       |
| **9100** | Glances / Node Exporter| z0r0   | `layers/20-services/26-monitoring/`                | Node Hardware Stats Daemon      |
| **8384** | Syncthing Web GUI      | Both   | `layers/20-services/25-data/syncthing.nix`         | Syncthing Web Management UI     |
| **9115** | Blackbox Exporter      | z0r0   | `layers/20-services/26-monitoring/`                | HTTP Probe Exporter             |
| **9119** | Hermes Dashboard       | z0r0   | `layers/70-agents/76-hermes-agent/`                | Hermes Agent Control Center     |
| **9187** | Postgres Exporter      | Both   | `layers/20-services/26-monitoring/`                | PostgreSQL Database Metrics     |
| **9586** | WireGuard Exporter     | Both   | `layers/20-services/26-monitoring/`                | WireGuard Mesh VPN Metrics      |
| **9898** | Langfuse Exporter      | z0r0   | `layers/20-services/26-monitoring/`                | Custom Langfuse Metrics Exporter|
| **9377** | Camofox Browser        | z0r0   | `machines/z0r0/default.nix`                        | Anti-Detection Browser CDP      |
| **9696** | Prowlarr               | luffy  | `layers/20-services/23-media/media-stack.nix`     | Indexer Proxy Manager           |
| **11434**| Ollama                 | Both   | `layers/20-services/22-ai/ollama.nix`              | Local LLM Inference Engine      |
| **20128**| ExtremeRouter          | z0r0   | `layers/70-agents/78-llm-routers/extreme-router.nix` | Coding LLM router — 154+ providers, web UI + `/v1/*` API |
| **20129**| OmniRoute              | nami   | `layers/70-agents/78-llm-routers/omniroute.nix`      | Next.js LLM router & RTK compressor |
| **21027**| Syncthing Discovery    | Both   | `layers/20-services/25-data/syncthing.nix`         | Syncthing UDP Discovery         |
| **21116**| RustDesk Signal        | z0r0   | `layers/20-services/24-communication/`             | Remote Desktop Signaling        |
| **22000**| Syncthing Sync         | Both   | `layers/20-services/25-data/syncthing.nix`         | Syncthing Peer Transfer Port    |
| **25600**| Komga                  | luffy  | `layers/20-services/26-monitoring/`                | Comic & Manga Server            |
| **29317**| Mautrix WhatsApp       | luffy  | `layers/20-services/24-communication/`             | WhatsApp Matrix Bridge          |
| **29318**| Mautrix Signal         | luffy  | `layers/20-services/24-communication/`             | Signal Matrix Bridge            |
| **32768**| Spacedrive             | luffy  | `layers/20-services/26-monitoring/`                | Distributed File Manager        |
| **32784**| MaxKB                  | luffy  | `layers/20-services/26-monitoring/`                | Knowledge Base AI System        |
| **32790**| SimStudio              | luffy  | `machines/luffy/containers.nix`                    | Multi-agent Workflow Sandbox    |
| **51820**| WireGuard VPN          | Both   | `clan.nix`                                         | Encrypted Mesh VPN Port         |
| **61208**| Glances Web Stats      | z0r0   | `layers/20-services/26-monitoring/`                | Glances Web Performance Monitor |

---

## Reserved & Disabled Services

| Port | Service | Machine | Reason |
|:----:|:--------|:-------:|:-------|
| — | Langgraph | z0r0 | Module disabled: `langgraph.server` not packaged in nixpkgs |

---

## Fleet Port Rules

1. **Before adding a new service**, check this file for the desired port
2. **Default ports** (e.g., 3000, 8080, 8000) are often claimed — always verify
3. **Document immediately** when assigning a port to a new service
4. **Services should use the same port across machines** — use module defaults, don't override per-machine
5. **Prefer high ports** (8000+) for custom services to avoid system conflicts
