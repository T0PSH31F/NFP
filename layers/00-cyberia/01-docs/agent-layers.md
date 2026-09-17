# Agent Layers Architecture Map (`70-agents`)

## Overview

The `70-agents` layer structure divides AI capabilities across 9 focused sub-tiers (71–79). This architecture establishes strict boundaries between user-facing agent harnesses, voice engines, memory/RAG databases, inference hardware infrastructure, Model Context Protocol (MCP) tool catalogs, multi-agent orchestrators, web/desktop UIs, LLM routing proxies, and skill packages.

```
                  +-----------------------------------+
                  |  77-dash-desk-ui / 71-harness     |
                  | (Open WebUI, OpenCode, Hermes)    |
                  +-----------------+-----------------+
                                    |
          +-------------------------+-------------------------+
          |                         |                         |
          v                         v                         v
+-------------------+     +-------------------+     +-------------------+
|  78-llm-routers   |     |    75-mcp         |     |    72-voice       |
| (Kong, Extreme)   |     | (MCP Catalog,     |     | (Whisper, Piper,  |
+---------+---------+     |  Headroom)        |     |  Wyoming)         |
          |               +---------+---------+     +-------------------+
          |                         |
          v                         v
+-------------------+     +-------------------+
|   74-ai-infra     |     |    73-memory      |
| (Ollama, vLLM,    |     | (Brain, EverOS,   |
|  llama.cpp)       |     |  ContextForge)    |
+-------------------+     +-------------------+
```

---

## 1. End-to-End Request Flows

### Flow 1: LLM Inference & Routing
1. **Client Tool / Agent Harness** (`71-harness`, `77-dash-desk-ui`): OpenCode, Antigravity, or Open WebUI formats an OpenAI-compatible completion or chat request.
2. **LLM Router** (`78-llm-routers`): Request hits **Kong Gateway** (`:8090`) or **ExtremeRouter** (`:20128`).
3. **Upstream Target**:
   - If local model: Routed to **Ollama** (`:11434`), **llama.cpp** (`:8080`), or **vLLM** (`:8000`) in `74-ai-infra`.
   - If cloud provider: Transformed with API keys from SOPS secrets and proxied securely to OpenAI, Anthropic, Gemini, or OpenRouter.

### Flow 2: Long-Term Memory & RAG Retrieval
1. **Agent Execution** (`71-harness`, `76-orchestrators`): Hermes or OpenCode executes a user task.
2. **MCP Tool Invocation** (`75-mcp`): Harness calls an MCP server defined in `server-catalog.nix` or Headroom context compressor (`:8095`).
3. **Memory Store Query** (`73-memory`): Request routes to **Brain-service** (`:8010`) or **EverOS** (`:8092`) to query indexed vector embeddings and Markdown notes stored in `25-data` (PostgreSQL / Qdrant).

### Flow 3: Multi-Agent Swarm Orchestration
1. **Fleet Dispatcher** (`76-orchestrators`): Polyfloor (`:7777` API-only on `nami`) or LangGraph (`:8123`) decomposes a goal into sub-tasks.
2. **Task Delegation**: Orchestrator invokes background worker daemons in `71-harness` (Hermes background workers, OpenCode runners).
3. **Execution & Feedback**: Sub-agents evaluate code in `74-ai-infra` sandboxes, update shared state in `73-memory` (Honcho/EverOS), and report completion status back to Polyfloor.

---

## 2. Host Target Assignments (Machine × Tier Mapping)

Based on machine tags and hardware specs:

| Tier | Host Placement | Primary Machine | Enabling Tag Rationale |
| :--- | :--- | :--- | :--- |
| `71-harness` | Thin-Client & Workstation | `z0r0`, `luffy` | `ai-agent`, `workstation`, `development` |
| `72-voice` | Local Workstation & Homelab | `z0r0`, `luffy` | `ai-agent`, `desktop`, `homelab` |
| `73-memory` | Central PKB Node & Server | `luffy` | `pkb-node`, `ai-server`, `homelab` |
| `74-ai-infra` | High-RAM & GPU Nodes | `luffy` | `gpu-compute`, `ai-server` |
| `75-mcp` | All Client & Agent Hosts | `z0r0`, `luffy` | `ai-agent`, `workstation` |
| `76-orchestrators` | Control Plane & Homelab | `nami`, `luffy` | `agent-orchestrator`, `ai-router`, `homelab` |
| `77-dash-desk-ui` | Desktop Workstation & Homelab | `z0r0`, `luffy` | `desktop`, `workstation`, `homelab` |
| `78-llm-routers` | Edge Network & Control Routers | `nami`, `z0r0` | `ai-router`, `network-router`, `homelab` |
| `79-skills` | Flake-wide Base Layer | All hosts | Implemented everywhere as declarative defaults |

---

## 3. Network Port Allocation Table

Below is the canonical port allocation registry for all `70-agents` services across hosts:

| Port | Service Name | Module Location | Service Description | Machine(s) |
| :--- | :--- | :--- | :--- | :--- |
| **3000** | Langfuse UI | `73-memory/langfuse.nix` | Observability UI (Langfuse) | `luffy` |
| **3002** | Manifest | `78-llm-routers/manifest.nix` | Frontier LLM fallback router | `nami` |
| **3003** | FreeLLMAPI | `78-llm-routers/freellmapi.nix` | Aggregated free-tier LLM API pool | `nami` |
| **3004** | FreeLLMPool | `78-llm-routers/freellmpool.nix` | Connection pool for free providers | `nami` |
| **3006** | AionUI | `76-orchestrators/aionui.nix` | AI Coworker Web Interface | `nami`, `luffy` |
| **3100** | Paperclip | `76-orchestrators/paperclip.nix` | Multi-agent task queue engine | `nami` |
| **3456** | GNO | `73-memory/gno.nix` | Gnosis Knowledge Node graph API | `luffy` |
| **4000** | LiteLLM | `78-llm-routers/litellm.nix` | Unified OpenAI-compatible proxy | `nami` |
| **5680** | OpenCompany UI | `76-orchestrators/opencompany.nix` | AI Organization frontend canvas | `nami`, `luffy` |
| **5681** | OpenCompany Backend | `76-orchestrators/opencompany.nix` | AI Organization Python API | `nami`, `luffy` |
| **7998** | Hermes Daemon | `71-harness/hermes/hermes.nix` | Hermes background agent runner | `luffy` |
| **7777** | Polyfloor API | `76-orchestrators/polyfloor.nix` | Polyfloor FastAPI (API-only, `staticDir = null`, no UI) | `nami` |
| **8000** | vLLM | `74-ai-infra/vllm.nix` | vLLM inference server | `luffy` |
| **8010** | Brain-service | `73-memory/brain-service.nix` | PKB RAG ingestion & query API | `luffy` |
| **8080** | llama.cpp / LocalAI | `74-ai-infra/llama-cpp.nix`, `74-ai-infra/localai.nix` | GGUF / multi-modal local inference | `luffy` |
| **8082** | llama-swap | `74-ai-infra/llama-swap.nix` | Dynamic model loading proxy | `luffy` |
| **8085** | Hermes Gateway | `71-harness/hermes/hermes.nix` | Hermes API gateway endpoint | `luffy` |
| **8087** | Ollama-UI | `77-dash-desk-ui/ollama-ui.nix` | Minimal web UI for Ollama | `z0r0` |
| **8088** | Open WebUI | `77-dash-desk-ui/open-webui.nix` | Multi-user LLM chat & RAG interface | `z0r0`, `luffy` |
| **8090** | Kong Gateway Proxy | `78-llm-routers/kong-gateway.nix` | Central LLM authentication proxy | `nami` |
| **8091** | Kong Admin API | `78-llm-routers/kong-gateway.nix` | Kong admin loopback endpoint | `nami` |
| **8092** | EverOS | `73-memory/everos.nix` | Memory consolidation engine | `luffy` |
| **8093** | Memory Vault | `73-memory/memory-vault.nix` | Encrypted memory storage daemon | `luffy` |
| **8094** | ContextForge | `73-memory/context-forge.nix` | Dynamic context assembly API | `luffy` |
| **8095** | Headroom | `75-mcp/headroom.nix` | Context compression MCP proxy | `nami` |
| **8096** | Mistral MCP | `75-mcp/mistral-mcp.nix` | Mistral model surface MCP daemon | `luffy` |
| **8097** | Voice STT | `72-voice/voice.nix` | Local whisper.cpp STT server | `z0r0`, `luffy` |
| **8098** | Voice TTS | `72-voice/voice.nix` | Local Piper / XTTSv2 server | `z0r0`, `luffy` |
| **8099** | Mission Control | `76-orchestrators/mission-control.nix` | Fleet management dashboard | `nami` |
| **9119** | Hermes Dashboard | `71-harness/hermes/dashboard.nix` | Hermes status REST API | `luffy` |
| **9377** | Hermes Browser | `71-harness/hermes/hermes.nix` | Camoufox headless browser server | `luffy` |
| **10200** | Wyoming Piper | `72-voice/wyoming.nix` | Wyoming TTS endpoint | `luffy` |
| **10300** | Wyoming Whisper | `72-voice/wyoming.nix` | Wyoming STT endpoint | `luffy` |
| **10400** | Wyoming OpenWakeWord | `72-voice/wyoming.nix` | Wyoming wake word endpoint | `luffy` |
| **11434** | Ollama | `74-ai-infra/ollama.nix` | GGUF model manager endpoint | `luffy` |
| **20128** | ExtremeRouter / OmniRoute | `78-llm-routers/extreme-router.nix` | 154+ provider LLM router / OmniRoute | `z0r0`, `nami` |

---

## 4. The ExtremeRouter / OmniRoute Port 20128 Situation

> [!CAUTION]
> Both `extreme-router.nix` (`layers.layer-78.llm-routers.extreme-router`) and `omniroute.nix` (`services.ai-services.omniroute`) declare default host port bindings on **port 20128**.

### Root Cause
- `extreme-router.nix` runs as a Podman OCI container with `-p 127.0.0.1:${toString port}:20128`.
- `omniroute.nix` runs as a Next.js OCI container with `-p 127.0.0.1:${toString port}:20128`.

### Mitigation Strategy
1. **Machine Isolation**: `extreme-router` is assigned to workstation environments (`z0r0`) while `omniroute` runs on homelab router control nodes (`nami`).
2. **Explicit Port Offset**: When co-locating both services on a single node, explicitly configure:
   ```nix
   services.ai-services.omniroute.port = 20129;
   ```
