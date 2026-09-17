# Tier 76 — Orchestrators (`76-orchestrators`)

## Tier Purpose

The `76-orchestrators` tier is responsible for multi-agent swarm orchestration, workflow graphs, organizational task delegation, autonomous governance, and fleet control panels. It contains platforms like Polyfloor, AionUI, LangGraph, OpenCompany, Paperclip, and Mission Control. Single-agent CLI harnesses (71-harness), raw inference backends (74-ai-infra), and end-user LLM chat GUIs (77-dash-desk-ui) do NOT belong here.

## Module Registry

| Module | Description | Option Path | Default Port(s) | Service Type | Enabling Tag(s) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `aionui.nix` | AionUI AI coworker web interface and agent session manager. | `layers.layer-76.orchestrators.aionui` | 3006 | Always-on systemd service | `agent-orchestrator`, `ai-agent`, `homelab` |
| `langgraph.nix` | LangGraph stateful multi-agent flow runtime and graph execution server. | `services.ai-services.langgraph` | 8123 | Always-on systemd service | `agent-orchestrator`, `homelab` |
| `mission-control.nix` | Mission Control agent fleet status, task dispatch, and telemetry dashboard. | `layers.layer-76.orchestrators.mission-control` | 8099 | Always-on systemd service | `agent-orchestrator`, `homelab` |
| `opencompany.nix` | OpenCompany autonomous organization platform (Python API + Next.js UI). | `services.ai-services.opencompany` | 5680 (UI), 5681 (API) | Always-on systemd service | `agent-orchestrator`, `homelab` |
| `paperclip.nix` | Paperclip multi-agent swarm task queuing and goal tracking engine. | `layers.layer-76.orchestrators.paperclip` | 3100 | Always-on systemd service | `agent-orchestrator`, `homelab` |
| `polyfloor.nix` | Polyfloor AI governance, policy routing, and task allocation control plane. | `services.polyfloor` (upstream `github:T0PSH31F/Polyfloor`) via `services.ai-services.polyfloor` compat shim | 7777 (Backend API-only, `staticDir = null`) | Always-on systemd service `polyfloor.service` on `nami` | `agent-orchestrator` (nami) |

## Tier Relationships

- **Orchestrates Harnesses**: `76-orchestrators` coordinate agent instances in `71-harness` (Hermes, OpenCode) and assign sub-tasks to specialized agent workers.
- **Routes via Routers & Uses Memory**: Orchestrators issue model requests through `78-llm-routers` and read/write collective state via `73-memory` (Brain-service, EverOS, Honcho).
