# ADR: NFP Dashboard MCP — Declarative Contract Projection & Security Model

**Status**: Accepted  
**Date**: 2026-10-12  
**Context**: NFP Production Fleet (z0r0, luffy, nami)  
**Authors**: Antigravity / t0psh31f  

---

## 1. Context & Motivation

Upstream Homepage (`gethomepage/homepage`) relies on mutable YAML configuration files (`services.yaml`, `widgets.yaml`, `settings.yaml`). Upstream Homepage MCP implementations expose toolsets designed to mutate, add, or overwrite these YAML files at runtime.

In NFP, **NixOS Dendritic Flake Contracts (`nfp.services.*`) are the Single Source of Truth**. Every service card, proxy destination, health probe, and telemetry widget is hermetically evaluated at build time from declarative Nix contracts. Mutating runtime YAML would destroy determinism, cause configuration drift across machines, and violate the Clan/NixOS architecture.

We require an MCP server that grants AI agents and tooling rich visibility into the dashboard state, contract validity, and live fleet vitals while strictly enforcing read-only projection and secret isolation.

---

## 2. Decision: Read-Only Contract Projection over Local Stdio

1. **Protocol & Transport**:
   - The NFP Dashboard MCP server is implemented as a local `stdio` server (`layers/70-agents/75-mcp/nfp-dashboard-mcp.py`).
   - Registered declaratively in `layers/70-agents/75-mcp/server-catalog.nix` under `servers.nfp-dashboard`.
   - Accessible to local agent harnesses (Claude, OpenCode, Hermes, Pi, Antigravity) via standard JSON-RPC 2.0 stdio pipes.

2. **Single Source of Truth**:
   - The MCP server queries the live dashboard daemon projection (`http://127.0.0.1:3007/api/config`, `/api/widget/{id}`, `/api/fleet/vitals`).
   - Does NOT read raw SOPS plaintext, encrypted files, `.env` secret stores, or raw systemd credentials.

3. **Tool Allowlist (10 Sanitized Read-Only Tools)**:
   - `list_dashboard_services`: List all enabled user-facing services and their canonical contracts.
   - `get_dashboard_service`: Query specific service contract metadata, client URL, role, and satellite assignment.
   - `get_dashboard_health`: Read health status without mutating or restarting services.
   - `get_dashboard_metrics`: Read parsed telemetry metrics and bounty figure.
   - `list_fleet_hosts`: List machines in the Grand Line fleet (`z0r0`, `luffy`, `nami`).
   - `get_fleet_host_vitals`: Query real-time Netdata vitals (CPU %, RAM GB/%, Disk %, Net RX/TX, Load, Uptime).
   - `list_dashboard_categories`: List active crew categories in canonical IA order.
   - `validate_dashboard_contracts`: Verify contract invariants (Tailnet domain purity, absence of `.local` or raw IPs).
   - `list_observability_targets`: List telemetry collection points across Prometheus, Loki, Grafana, and Netdata.
   - `get_observability_coverage`: Return full observability matrix and gaps across fleet hosts and services.

4. **Security Boundary & Invariants**:
   - **Zero Writes**: No edit, delete, or restart actions are permitted in this pass.
   - **Secret Masking**: Metric API tokens (Sonarr, Radarr, Prowlarr, Jellyfin, Overseerr, etc.) are consumed exclusively server-side in the daemon via systemd credentials; the MCP projection returns only parsed numerical metrics.
   - **Domain Purity**: Enforces `*.nfp.nix` (Tailnet MagicDNS) and `*.lovelain.duckdns.org` (WAN Caddy). Forbids `.local` or raw IPs in browser-facing URLs.
   - **Remote Transport Restriction**: Remote HTTP/SSE transport is deferred. If ever enabled, it must be restricted to Tailscale/Headscale mesh authenticated sockets with SOPS-derived bearer tokens.

---

## 3. Consequences

- **Pros**:
  - Deterministic: Evaluated NixOS contracts remain the sole authority.
  - Safe: Impossible for an agent to corrupt dashboard state or leak SOPS secrets.
  - High observability: Agents can query live cluster health and host vitals in one structured tool call.
- **Cons**:
  - Requires the local dashboard daemon (`homepage-dashboard.service`) to be active to retrieve real-time widget metrics. Fallback modes return evaluated configuration if daemon is temporarily offline.
