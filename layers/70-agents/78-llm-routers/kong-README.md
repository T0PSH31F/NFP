# Kong AI Gateway Stack

Unified LLM/API gateway for all agents and services. All LLM traffic flows through Kong (`nami:8090`) → upstream routers → providers.

## Architecture

```
Agents (Hermes, OpenCode, Claude-Code, Codex, Cursor, Deerflow, Polyfloor)
  │  1 Kong endpoint (http://nami:8090/v1) + 1 API key
  ▼
Kong AI Gateway on nami (:8090 proxy, :8091 admin)
  ├── /v1/*                     → ExtremeRouter on z0r0:20128 (default primary)
  ├── /er/v1/*                  → ExtremeRouter on z0r0:20128 (explicit)
  ├── /omni/v1/*                → OmniRoute on 127.0.0.1:20129 (explicit)
  ├── /llm/v1/chat/completions  → FreeLLMAPI (free+paid pool)
  ├── /llm/frontier/v1/...      → Manifest (frontier models)
  ├── /llm/free/v1/...          → freellmpool (pure free tier)
  └── /mcp                      → MCP gateway
  ▼
Upstream Routers
  ├── ExtremeRouter :20128 (z0r0 — 154+ providers, RTK savings)
  ├── OmniRoute :20129      (nami — Next.js router, RTK compression)
  ├── Manifest :2099       (frontier: GPT-5, Claude, Gemini, DeepSeek)
  ├── FreeLLMAPI :3003     (aggregated pool)
  └── freellmpool :8083     (pure free tier)
  ▼
Providers (OpenRouter, Anthropic, Gemini, Groq, Cerebras, etc.)
```

## Files

| File | Purpose |
|------|---------|
| `layers/70-agents/78-llm-routers/kong-gateway.nix` | Kong container, declarative kong.base.yml, routes, plugins |
| `layers/70-agents/78-llm-routers/kong-secrets.nix` | Sops secrets → env files + consumers.yml for all services |
| `layers/70-agents/78-llm-routers/omniroute.nix` | OmniRoute OCI container (Next.js app, port 20129) |
| `layers/70-agents/78-llm-routers/extreme-router.nix` | ExtremeRouter OCI container (z0r0:20128, tailnet firewall) |
| `layers/70-agents/78-llm-routers/freellmpool.nix` | freellmpool native package (Python, single httpx dep) |
| `layers/70-agents/78-llm-routers/manifest.nix` | Manifest service (frontier router) |
| `layers/70-agents/78-llm-routers/freellmapi.nix` | FreeLLMAPI service (aggregated pool) |
| `layers/20-services/26-monitoring/dashboards/kong-ai-gateway.json` | Grafana dashboard |

## Setup & Verification

```bash
# Verify ExtremeRouter via Kong default primary route
curl -s http://nami:8090/v1/models -H "apikey: $KONG_KEY_HERMES" | jq '.data|length>0'

# Verify OmniRoute via explicit route
curl -s http://nami:8090/omni/v1/models -H "apikey: $KONG_KEY_HERMES" | jq '.data|length>0'

# Verify unauthenticated request returns 401
curl -s http://nami:8090/v1/models # 401 Unauthenticated
```

## Routing Tiers

| Route | Upstream | Use Case |
|-------|----------|----------|
| `/v1/*` | ExtremeRouter (`z0r0:20128`) | Primary default — 154+ providers, RTK savings |
| `/er/v1/*` | ExtremeRouter (`z0r0:20128`) | Explicit ExtremeRouter access |
| `/omni/v1/*` | OmniRoute (`127.0.0.1:20129`) | Explicit OmniRoute access |
| `/llm/v1/*` | FreeLLMAPI | Legacy pool split |
| `/llm/frontier/v1/*` | Manifest | Frontier reasoning models |
| `/llm/free/v1/*` | freellmpool | Pure free-tier pool |

## Ports

| Port | Service | Host |
|------|---------|------|
| 8090 | Kong proxy (API traffic) | nami |
| 8091 | Kong Admin API | nami |
| 20128 | ExtremeRouter | z0r0 |
| 20129 | OmniRoute | nami |
| 3003 | FreeLLMAPI | nami |
| 8083 | freellmpool | nami |
