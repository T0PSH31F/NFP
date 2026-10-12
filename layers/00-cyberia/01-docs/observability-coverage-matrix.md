# Observability Coverage Matrix & Architecture Audit

**Status**: Verified Audit  
**Date**: 2026-10-12  
**Authority**: Antigravity / NFP Fleet  

---

## 1. Unified Telemetry Model

NFP adheres strictly to the following division of observability responsibilities:

- **Prometheus** (`:9090`): Numerical metrics, time-series storage, recording rules, and alert rules.
- **Loki** (`:3100`): Log aggregation, indexing, and structured event streaming.
- **Grafana** (`:3000`): Unified visualization layer, dashboarding, correlation, and Grafana Explore queries.
- **Grafana Alloy** (systemd): Lightweight telemetry and log shipper; scrapes local logs and metrics, forwards to Loki/Prometheus, and serves as an OTLP pipeline receiver.
- **Alertmanager** (`:9093`) + **ntfy** (`:8080`): Alert deduplication, inhibition, routing, and mobile/desktop notification dispatch.
- **Netdata** (`:19999`): Primary real-time high-definition host telemetry engine (1s granularity CPU, RAM, disk, network, per-process vitals). Glances is completely decommissioned.
- **Langfuse** (`:3005`): LLM and agent execution trace authority (token consumption, prompt versioning, agent tool-call latency).

---

## 2. Host Observability Coverage

| Host | Role | Node Exporter | Netdata (:19999) | Glances | Alloy Shipper | Loki Shipping | Prometheus Scrape | Healthcheck Target | Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **z0r0** | Workstation / AI Server | Yes (:9100) | **Yes** (Primary) | **Purged** | Yes | Yes (systemd journal) | Yes | Yes | Nominal |
| **luffy** | Homelab Server / Control Plane | Yes (:9100) | **Yes** (Primary) | **Purged** | Yes | Yes (systemd journal) | Yes | Yes | Nominal |
| **nami** | Mini Edge / Ingress | Yes (:9100) | **Yes** (Primary) | **Purged** | Yes | Yes (systemd journal) | Yes | Yes | Nominal |

*Policy Note*: Glances has been completely disabled and removed across all host profiles, contracts, tests, and documentation. Netdata is the sole real-time engine for Grand Line Fleet Vitals.

---

## 3. Service Observability Coverage Matrix

| Service | Host | User UI URL | /metrics | Native Exporter | Contract Metrics | Prom Scrape | Loki Logs | Grafana Link | Alert Rule | Trace Authority | Telemetry Gaps / Action |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **AdGuard Home** | luffy | `http://adguard.nfp.nix` | Yes (:3000) | Native API | `queriesToday`, `blockedCount`, `blockedPercent` | Yes | Yes | Yes | Yes | N/A | Full coverage |
| **Caddy** | luffy | `http://caddy.nfp.nix` | Yes (:2019) | Native API | `routes`, `uptime` | Yes | Yes | Yes | Yes | OTLP (future) | Full coverage |
| **Headscale** | luffy | `http://headscale.nfp.nix` | Yes (:9090) | Native API | `nodes` | Yes | Yes | Yes | Yes | N/A | Full coverage |
| **Jellyfin** | luffy | `http://jellyfin.nfp.nix` | Yes (:8096) | Plugin / API | `movies`, `series`, `activeStreams` | Yes | Yes | Yes | No | N/A | Alert rule for transcoding failure needed |
| **Sonarr** | luffy | `http://sonarr.nfp.nix` | Via API (:8989) | Native API | `series`, `episodes`, `monitored` | No | Yes | Yes | No | N/A | Scrape via exportarr optional |
| **Radarr** | luffy | `http://radarr.nfp.nix` | Via API (:7878) | Native API | `movies`, `monitored` | No | Yes | Yes | No | N/A | Scrape via exportarr optional |
| **Prowlarr** | luffy | `http://prowlarr.nfp.nix` | Via API (:9696) | Native API | `indexers` | No | Yes | Yes | No | N/A | Scrape via exportarr optional |
| **Bazarr** | luffy | `http://bazarr.nfp.nix` | Via API (:6767) | Health-only | Health-only | No | Yes | Yes | No | N/A | Native adapter optional |
| **Overseerr (Seerr)** | luffy | `http://seerr.nfp.nix` | Via API (:5055) | Native API | `requests` | No | Yes | Yes | No | N/A | Full coverage |
| **RomM** | luffy | `http://romm.nfp.nix` | Via API (:8082) | Health-only | Health-only | No | Yes | Yes | No | N/A | Health checked |
| **Komga** | luffy | `http://komga.nfp.nix` | Yes (:25600) | Spring Actuator | Health-only | Yes | Yes | Yes | No | N/A | Prometheus scrape active |
| **Calibre-Web** | luffy | `http://calibre.nfp.nix` | SQLite DB | Direct DB Query | `books`, `authors` | No | Yes | Yes | No | N/A | Full coverage |
| **Audiobookshelf** | luffy | `http://audiobookshelf.nfp.nix` | Via API (:8000) | Native API | `items` | No | Yes | Yes | No | N/A | Full coverage |
| **Feishin** | luffy | `http://feishin.nfp.nix` | Client Web | Health-only | Health-only | No | Yes | Yes | No | N/A | Health checked |
| **Your Spotify** | luffy | `http://spotify.nfp.nix` | Client Web | Health-only | Health-only | No | Yes | Yes | No | N/A | Health checked |
| **Lidarr** | luffy | `http://lidarr.nfp.nix` | Via API (:8686) | Native API | `artists`, `albums` | No | Yes | Yes | No | N/A | Health checked |
| **Prometheus** | nami | `http://prometheus.nfp.nix` | Yes (:9090) | Native | `targetsUp`, `targetsTotal`, `alertsActive` | Yes | Yes | Yes | Yes | N/A | Self-monitoring active |
| **Grafana** | nami | `http://grafana.nfp.nix` | Yes (:3000) | Native | `version`, `database` | Yes | Yes | Yes | Yes | N/A | Full coverage |
| **Loki** | nami | `http://loki.nfp.nix` | Yes (:3100) | Native | Health-only (Grafana Explore target) | Yes | Yes | Yes | Yes | N/A | Explore logs destination |
| **Netdata** | fleet | `http://{host}.nfp.nix:19999` | Yes (:19999) | Native API | Full host vitals | Yes | Yes | Yes | Yes | N/A | Primary Fleet Vitals source |
| **ntfy** | luffy | `http://ntfy.nfp.nix` | Yes (:8080) | Native | Health-only | Yes | Yes | Yes | No | N/A | Full coverage |
| **n8n** | luffy | `http://n8n.nfp.nix` | Yes (:5678) | Native API | Health-only | Yes | Yes | Yes | No | N/A | Full coverage |
| **Home Assistant** | luffy | `http://homeassistant.nfp.nix` | Yes (:8123) | Native API | Health-only | Yes | Yes | Yes | No | N/A | Full coverage |
| **Hermes Dashboard** | z0r0 | `http://hermes.nfp.nix` | Yes (:9119) | Native API | Health-only | No | Yes | Yes | No | Langfuse | LLM spans forwarded to Langfuse |
| **Polyfloor** | nami | `http://polyfloor.nfp.nix` | Yes (:8000) | Native API | Health-only | No | Yes | Yes | No | Langfuse | SSE event bus active |
| **Paperclip** | nami | `http://paperclip.nfp.nix` | Yes (:3100) | Native API | `activeIssues`, `totalIssues` | No | Yes | Yes | No | Langfuse | Full coverage |
| **AionUI** | nami | `http://aionui.nfp.nix` | Yes (:8084) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Full coverage |
| **Mission Control** | nami | `http://missioncontrol.nfp.nix` | Yes (:3008) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Full coverage |
| **Kong Gateway** | nami | `http://kong.nfp.nix` | Yes (:8001) | Native | Health-only | Yes | Yes | Yes | Yes | OTLP (future) | Prometheus scrape active |
| **ExtremeRouter** | z0r0 | `http://extreme-router.nfp.nix` | Yes (:8002) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Router health active |
| **OmniRoute** | nami | `http://omniroute.nfp.nix` | Yes (:8003) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Router health active |
| **Open WebUI** | nami | `http://openwebui.nfp.nix` | Yes (:8080) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Full coverage |
| **SillyTavern** | nami | `http://sillytavern.nfp.nix` | Yes (:8000) | Native API | Health-only | No | Yes | Yes | No | Langfuse | Full coverage |
| **Langfuse** | luffy | `http://langfuse.nfp.nix` | Yes (:3005) | Native | Health-only | Yes | Yes | Yes | Yes | Langfuse | LLM trace authority |
| **Matrix Synapse** | luffy | `http://matrix.nfp.nix` | Yes (:8008) | Native (:9092) | Health-only | Yes | Yes | Yes | Yes | N/A | Full coverage |
| **SearXNG** | luffy | `http://searxng.nfp.nix` | Yes (:8080) | Native API | Health-only | No | Yes | Yes | No | N/A | Full coverage |

---

## 4. Distributed Tracing Evaluation: Tempo vs. Jaeger

### Context
The prompt requests an audit of OTLP emission across fleet services and a clear architectural decision regarding general (non-LLM) distributed tracing.

### Findings
1. **Current State**:
   - LLM and Agent workflows (Hermes, Polyfloor, AionUI, Paperclip, Open WebUI) already target **Langfuse** for prompt telemetry, token tracking, agent tool call spans, and execution trees.
   - Non-LLM infrastructure services (Caddy, Kong Gateway, Synapse, Matrix) currently emit structured logs to Loki via Grafana Alloy, but do not emit active distributed traces into a trace storage backend.
   - Neither Tempo nor Jaeger is currently running or enabled in production.

2. **Analysis**:
   - **Do NOT install both Tempo and Jaeger**: Running parallel trace collectors creates port collisions (gRPC 4317 / HTTP 4318), wasted memory, and fragmented telemetry silos.
   - **Tempo with Grafana Alloy (Recommended)**:
     - Grafana Tempo integrates natively with the existing Grafana + Loki stack.
     - Tempo supports 100% object storage (local disk / MinIO / S3) without requiring Elasticsearch, Cassandra, or OpenSearch.
     - Grafana Alloy can serve as the local OTLP receiver endpoint (`4317/4318`), batching and routing trace spans into Tempo, metrics into Prometheus, and logs into Loki.
     - Allows seamless "Logs-to-Traces" and "Traces-to-Logs" deep-linking inside Grafana Explore.

### Recommendation
- **Do not deploy Tempo or Jaeger in this pass** to preserve memory and adhere strictly to scope.
- Maintain **Langfuse** as the dedicated trace and observability authority for all LLMs, agents, and swarms.
- Record the recommendation for a future ADR: when general microservice tracing is required, deploy `tempo` on `luffy` with `alloy` as the unified OTLP receiver.
