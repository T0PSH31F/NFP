# NFP Monitoring & Observability Architecture

This document describes the observability stack deployed in NFP across `z0r0` and `luffy`.

## Architecture Overview

```
                      +-------------------+
                      |   Grafana (:3008) |
                      +---------+---------+
                                |
             +------------------+------------------+
             |                                     |
    +--------v--------+                   +--------v--------+
    | Prometheus(:9090)|                   |   Loki (:3100)  |
    +--------+--------+                   +--------+--------+
             |                                     |
    +--------+------------------+                  | (pushed by Alloy)
    |        |                  |                  |
+---v----+ +-v----------+ +-----v--------+ +-------+-------+
|  Node  | | Postgres   | |   Langfuse   | | Systemd       |
|Exporter| | Exporter   | |   Exporter   | | Journald      |
|(:9100) | | (:9187)    | |   (:9898)    | | (Alloy shipper|
+--------+ +------------+ +--------------+ +---------------+
```

## Observability Pillars

### 1. Metrics Collection (Prometheus)
- **Port**: `9090`
- **Exporters**:
  - `node_exporter` (:9100): CPU, memory, filesystem, Btrfs stats, diskstats, systemd status.
  - `postgres_exporter` (:9187): PostgreSQL metrics for database health and pgvector performance.
  - `wireguard_exporter` (:9586): Mesh VPN peer telemetry and latency.
  - `langfuse-exporter` (:9898): Polling custom exporter fetching `/api/public/metrics` from Langfuse. Exposes `langfuse_traces_total`, `langfuse_tokens_total`, `langfuse_cost_dollars`, `langfuse_up`.
  - `blackbox_exporter` (:9115): Probes HTTP endpoints for all enabled `nfp.services` contracts cross-host via Tailnet MagicDNS (`<host>.lovelain.duckdns.org`).
  - Native service metrics endpoints: Caddy (`:2019/metrics`), Matrix Synapse (`:8008/_synapse/metrics`), n8n (`:5678/metrics`), Kong Gateway (`:8090/metrics`).
- **Dashboards**: Configured via file provisioning in Grafana from `layers/20-services/26-monitoring/dashboards/`.

### 2. Log Aggregation (Loki + Grafana Alloy)
- **Loki Port**: `3100`
- **Shipper**: Grafana Alloy runs systemd journald log collector.
- **Scope**: Streams journald entries for all `layers/20-services/` and `layers/70-agents/` systemd units.
- **Labels**: `job="systemd-journal"`, `unit="<service>.service"`, `hostname="<machine>"`.

### 3. Alerting & Notifications (Grafana & Prometheus Rules)
- **Prometheus Rules**: `services.prometheus.rules` evaluates rule `ServiceDown` when `up == 0` for > 5 minutes.
- **Notification Routing**: Webhook receivers route critical service outages.

### 4. Contract-Driven Fleet Healthcheck & Post-Deploy Gate
- **Module**: `layers/20-services/26-monitoring/fleet-healthcheck.nix`
- **Enablement**: Tag-gated via `network-router` tag (enabled on `luffy` & `nami`).
- **Runner**: `fleet-healthcheck.service` (+ `fleet-healthcheck.timer` every 15 min).
- **Behavior**: Evaluates all enabled `nfp.services` contracts, probes `http://<contractHost>.lovelain.duckdns.org:<port><path>` over Tailnet, checks non-HTTP services via systemd unit state, writes `/run/nfp/healthcheck-targets.json` and `/run/nfp/healthcheck-status.json`, and outputs structured journal logs.
- **Deploy Gate**: `./deploy.sh` (or `nix run .#deploy`) runs formatters/linters, `clan machines update`, waits for activation settling, and executes the fleet healthcheck gate prior to exit. Emergency override: `./deploy.sh --skip-healthcheck`.

## How to Add a New Service Target

### Adding a Prometheus Scrape Target
Edit `layers/20-services/26-monitoring/monitoring.nix`:
```nix
scrapeConfigs = [
  ...
  {
    job_name = "my-new-service";
    static_configs = [ { targets = [ "127.0.0.1:<PORT>" ]; } ];
  }
];
```

### Adding Log Extraction for a Unit
Grafana Alloy automatically captures all systemd units via `loki.source.journal`. Filter in Grafana using LogQL:
```logql
{unit="my-service.service"} |= `error`
```

### Adding a Grafana Alert Rule
Add rule definitions to `services.prometheus.rules` in `monitoring.nix` or provision via Grafana UI/JSON.
