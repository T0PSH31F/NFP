# Tier 71 — Harness (`71-harness`)

## Tier Purpose

The `71-harness` tier is responsible for agent execution harnesses, Interactive Development Environments (IDEs), command-line agent interfaces (CLIs), and autonomous agent daemons (such as Hermes and OpenCode). It acts as the primary user-facing and agentic execution layer where human developers and autonomous coding/research agents interact with the workspace and codebase. Low-level LLM inference engines (74-ai-infra), shared memory/RAG databases (73-memory), MCP tool servers (75-mcp), and LLM routers (78-llm-routers) do NOT belong here.

## Module Registry

| Module | Description | Option Path | Default Port(s) | Service Type | Enabling Tag(s) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `antigravity.nix` | Google Antigravity Agentic IDE & CLI suite integration. | `layers.layer-70.agent.antigravity` | None | On-demand CLI / GUI | `ai-agent`, `workstation`, `desktop` |
| `claude-code.nix` | Anthropic Claude Code terminal agent harness wrapper. | `layers.layer-70.agent.claude-code` | None | On-demand CLI | `ai-agent`, `development` |
| `codegraph.nix` | CodeGraph code indexing and graph intelligence tool. | `layers.layer-70.agent.codegraph` | None | On-demand CLI | `ai-agent`, `development` |
| `codex.nix` | OpenAI Codex CLI terminal harness tool. | `layers.layer-70.agent.codex` | None | On-demand CLI | `ai-agent`, `development` |
| `dsh.nix` | Dendritic Shell (DSH) AI terminal shell environment. | `layers.layer-71.harness.dsh` | None | On-demand TUI | `ai-agent`, `desktop`, `workstation` |
| `gemini-cli.nix` | Google Gemini CLI harness for command line generation. | `layers.layer-70.agent.gemini-cli` | None | On-demand CLI | `ai-agent`, `development` |
| `kilocode.nix` | Kilo Code AI terminal agent & IDE extension harness. | `layers.layer-71.harness.kilocode` | None | On-demand CLI | `ai-agent`, `development` |
| `kiro-cli.nix` | Kiro autonomous agent CLI tool. | `layers.layer-70.agent.kiro-cli` | None | On-demand CLI | `ai-agent`, `development` |
| `omp.nix` | Oh-My-Pi (OMP) terminal AI coding agent harness. | `layers.layer-71.harness.omp` | None | On-demand CLI | `ai-agent`, `development` |
| `opencode.nix` | OpenCode terminal agent harness with custom skills & configs. | `layers.layer-70.agent.opencode` | None | On-demand TUI | `ai-agent`, `development`, `workstation` |
| `supergraph.nix` | Supergraph autonomous codebase navigation harness. | `layers.layer-70.agent.supergraph` | None | On-demand CLI | `ai-agent`, `development` |
| `hermes/hermes.nix` | Nous Research Hermes autonomous agent daemon & browser runner. | `layers.layer-76.hermes` / `services.hermes` | 8085 (Gateway), 9377 (Browser), 9119 (REST API), 7998 (Daemon) | Always-on systemd service | `ai-agent`, `agent-orchestrator`, `homelab` |

## Tier Relationships

- **Behind / Consuming**: `71-harness` tools issue LLM queries through `78-llm-routers` (e.g. Kong `:8090`, ExtremeRouter `:20128`) or directly to backends in `74-ai-infra` (e.g. Ollama `:11434`).
- **MCP & Memory Integration**: `71-harness` agents consume PKB memory and RAG context from `73-memory` (Brain-service `:8010`, EverOS `:8092`) via MCP tool protocols configured in `75-mcp`.
- **Orchestration**: `76-orchestrators` (e.g., Polyfloor, LangGraph) trigger or orchestrate workflows executed within `71-harness` agent instances.
