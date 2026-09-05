# Kong AI Gateway Stack

Unified LLM/API gateway for all agents and services. All LLM traffic flows through Kong → upstream routers → providers.

## Architecture

```
Agents (Hermes, OpenCode, Claude-Code, Codex, Cursor, Deerflow)
  │  1 Kong endpoint + 1 API key
  ▼
Kong AI Gateway (:8000 proxy, :8001 admin)
  ├── /llm/v1/chat/completions  → FreeLLMAPI (free+paid pool)
  ├── /llm/frontier/v1/...      → Manifest (frontier models)
  ├── /llm/coding/v1/...        → OmniRoute (coding combos)
  ├── /llm/free/v1/...          → freellmpool (pure free tier)
  └── /mcp                      → MCP gateway
  ▼
Upstream Routers (localhost)
  ├── Manifest :2099    (frontier: GPT-5, Claude, Gemini, DeepSeek)
  ├── FreeLLMAPI :3001  (28 providers, 339 models, free+paid)
  ├── freellmpool :8080  (pure free tier)
  └── OmniRoute :20128   (coding with RTK compression)
  ▼
Providers (OpenRouter, Anthropic, Gemini, Groq, Cerebras, etc.)
```

## Files

| File | Purpose |
|------|---------|
| `layers/20-services/22-ai/kong-gateway.nix` | Kong container, declarative kong.base.yml, routes, plugins |
| `layers/20-services/22-ai/kong-secrets.nix` | Sops secrets → env files + consumers.yml for all services |
| `layers/20-services/22-ai/omniroute.nix` | OmniRoute OCI container (Next.js app, ghcr.io image) |
| `layers/20-services/22-ai/freellmpool.nix` | freellmpool native package (Python, single httpx dep) |
| `layers/20-services/22-ai/langgraph.nix` | LangGraph orchestration layer |
| `layers/20-services/22-ai/manifest.nix` | Manifest service (frontier router) |
| `layers/20-services/22-ai/freellmapi.nix` | FreeLLMAPI service (aggregated pool) |
| `layers/20-services/26-monitoring/dashboards/kong-ai-gateway.json` | Grafana dashboard |

## Setup

### 1. Add Kong consumer API keys to sops

Edit `layers/00-cyberia/03-treasure/secrets/external_services.yaml`:

```bash
sops layers/00-cyberia/03-treasure/secrets/external_services.yaml
```

Add these keys (already generated for this deployment):

```yaml
kong_key_hermes: 55951190683a649bc03bbaddbd6e3f08f9e49bfcf181ca877585a6a642126dc4
kong_key_opencode: cbf3d1ace446679597c64dbf2925d59f1d8ad3cec6404dfd871a4919afd0e577
kong_key_claude_code: d55447907d24624903a2714771681e635654db61c5b2184b21051ad021437aaa
kong_key_codex: e55e169aa1711638e72a56bb6dee0aae2cbedcb164697fdd75db9ad4379da9d5
kong_key_cursor: 5f0d93ec00687544dce217a191df8cf8ad296dcd8ea912ef284060edccc546c9
kong_key_deerflow: 52ab61156e58f8bdd35dadb01942055addac3e02146bd0381006d956a17b9f23
```

> **Note**: `claude-code` uses underscore (`kong_key_claude_code`) in the sops file;
> the module maps dashes to underscores automatically.

### 2. Build

```bash
clan machines update z0r0
```

### 3. Verify

```bash
# Kong status
kong-ctl status

# Admin API
kong-admin services
kong-admin routes
kong-admin consumers
kong-admin plugins

# OmniRoute (container)
omniroute-ctl status
omniroute-ctl logs

# Test LLM call through Kong
curl http://127.0.0.1:8000/llm/v1/chat/completions \
  -H "apikey: 55951190683a649bc03bbaddbd6e3f08f9e49bfcf181ca877585a6a642126dc4" \
  -H "Content-Type: application/json" \
  -d '{"model": "auto", "messages": [{"role": "user", "content": "hello"}]}'
```

## Client Configuration

### Hermes-Agent

In `~/.hermes/config.yaml`:

```yaml
model:
  provider: custom
  default: auto
  api_mode: chat_completions

providers:
  custom:
    base_url: "http://127.0.0.1:8000/llm/v1"
    api_key: "<kong_key_hermes>"
```

### OpenCode

In `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "custom": {
      "base_url": "http://127.0.0.1:8000/llm/v1",
      "api_key": "<kong_key_opencode>"
    }
  }
}
```

### Claude-Code / Cursor / Codex

Point their custom LLM endpoint at `http://127.0.0.1:8000/llm/v1` with their respective Kong API key.

## Routing Tiers

| Route | Upstream | Use Case |
|-------|----------|----------|
| `/llm/v1/*` | FreeLLMAPI | Default — free-first with paid fallback |
| `/llm/frontier/v1/*` | Manifest | Complex reasoning, frontier models |
| `/llm/coding/v1/*` | OmniRoute | Code generation, RTK compression |
| `/llm/free/v1/*` | freellmpool | Budget-constrained, free tier only |
| `/mcp` | FreeLLMAPI | MCP tool traffic |

## Budgets (LangGraph)

Budget config at `/etc/langgraph/budgets.json`. Agents check budget status before selecting a route tier:

- `frontier` → Manifest (expensive, high quality)
- `coding` → OmniRoute (compressed, code-optimized)
- `cheap` → FreeLLMAPI (free+paid mix)
- `free` → freellmpool (free only)

## Metrics

- Kong Prometheus metrics: `http://127.0.0.1:8000/metrics`
- Grafana dashboard: "Kong AI Gateway" at `http://localhost:3008`
- LangGraph metrics: `http://127.0.0.1:8100/metrics`

## Ports

| Port | Service |
|------|---------|
| 8000 | Kong proxy (API traffic) |
| 8001 | Kong Admin API |
| 8002 | Kong Manager GUI |
| 8443 | Kong proxy SSL |
| 8444 | Kong Admin SSL |
| 2099 | Manifest |
| 3001 | FreeLLMAPI |
| 8080 | freellmpool |
| 20128 | OmniRoute |
| 8100 | LangGraph |
