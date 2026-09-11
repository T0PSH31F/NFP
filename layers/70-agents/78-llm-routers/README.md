# Tier 78 — LLM Routers (`78-llm-routers`)

## Tier Purpose

The `78-llm-routers` tier is responsible for unified API gateways, LLM load balancers, rate limiters, fallback proxies, and multi-provider request routers. It contains Kong Gateway, ExtremeRouter, LiteLLM, OmniRoute, FreeLLMAPI, FreeLLMPool, and Manifest. Low-level inference engines (74-ai-infra), agent harnesses (71-harness), and memory DBs (73-memory) do NOT belong here.

## Module Registry

| Module | Description | Option Path | Default Port(s) | Service Type | Enabling Tag(s) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `extreme-router.nix` | ExtremeRouter OCI container proxy — 154+ LLM providers with web UI & `/v1/*` endpoint. | `layers.layer-78.llm-routers.extreme-router` | 20128 | Always-on OCI container service | `ai-router`, `ai-agent`, `workstation` |
| `freellmapi.nix` | FreeLLMAPI aggregated pool proxy for zero-cost free-tier provider models. | `services.ai-services.freellmapi` | 3003 | Always-on systemd service | `ai-router`, `homelab` |
| `freellmpool.nix` | FreeLLMPool connection pool manager maintaining healthy provider sockets. | `services.ai-services.freellmpool` | 3004 | Always-on systemd service | `ai-router`, `homelab` |
| `kong-gateway.nix` | Kong API Gateway — central authenticated LLM proxy, plugin engine, & consumer secret gateway. | `services.ai-services.kong-gateway` | 8090 (Proxy), 8091 (Admin) | Always-on OCI container service | `ai-router`, `homelab`, `server` |
| `litellm.nix` | LiteLLM proxy server — unified OpenAI-compatible format with cost tracking & load balancing. | `services.litellm-proxy` | 4000 | Always-on systemd service | `ai-router`, `homelab` |
| `manifest.nix` | Manifest frontier router selecting dynamic model fallbacks based on query complexity. | `services.ai-services.manifest` | 3002 | Always-on systemd service | `ai-router`, `homelab` |
| `omniroute.nix` | OmniRoute Next.js OCI container LLM routing and visual management app. | `services.ai-services.omniroute` | 20128 (Configurable) | Always-on OCI container service | `ai-router`, `homelab` |

> [!WARNING]
> **ExtremeRouter & OmniRoute Port 20128 Conflict**: Both `extreme-router.nix` and `omniroute.nix` declare port 20128 as their default container host port. When deployed on the same machine (e.g. z0r0 or sanji), set `services.ai-services.omniroute.port = 20129;` or disable one of the two to prevent socket binding collisions.

## Tier Relationships

- **Sits In Front Of**: Backends in `74-ai-infra` (Ollama `:11434`, llama.cpp `:8080`, vLLM `:8000`) and external cloud APIs (OpenAI, Anthropic, Gemini, OpenRouter).
- **Sits Behind**: Client harnesses in `71-harness` (OpenCode, Hermes, Antigravity), orchestrators in `76-orchestrators` (Polyfloor, LangGraph), and desktop UIs in `77-dash-desk-ui`.

> [!NOTE]
> **Polyfloor model discovery**: Polyfloor (`76-orchestrators/polyfloor.nix`) points `services.polyfloor.routerEndpoint` at one of these routers and enumerates models via `GET {base}/v1/models`. Kong exposes this on the `v1-models` route (forwarded to the coding router); LiteLLM (`/v1/models`) and ExtremeRouter (`/v1/*`) expose it natively.
