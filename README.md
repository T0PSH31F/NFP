# Nix Flake Pirates (NFP)

> **☠️ Nix Flake Pirates (NFP) Configuration**

![One Piece Theme](assets/character.gif)

[![NixOS](https://img.shields.io/badge/NixOS-Unstable-blue.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Clan-Core](https://img.shields.io/badge/Clan-Core-orange.svg?style=for-the-badge&logo=rust&logoColor=white)](https://docs.clan.lol)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-9cf.svg?style=for-the-badge&logo=hyprland&logoColor=white)](https://github.com/hyprwm/Hyprland)
[![Sops-Nix](https://img.shields.io/badge/Sops-Encrypted-green.svg?style=for-the-badge&logo=lock&logoColor=white)](https://github.com/Mic92/sops-nix)

> **"Wealth, fame, power. Gold Roger, the King of the Pirates, attained this and everything else the world had to offer."**

Welcome to the **Nix Flake Pirates (NFP)** NixOS configuration repository. This system is a highly modular, declarative, and reproducible infrastructure built on **Clan-Core** and `flake-parts`, featuring a 10-layer dendritic module architecture, self-hosted AI agent swarm control plane, and zero-trust impermanence persistence.

---

## 🏴‍☠️ The Grand Line Fleet

| Character | Machine | Role | Specs & Tags | State |
| :---: | :---: | :---: | :---: | :---: |
| ![Zoro](assets/machines/zoro.png) | **z0r0** | Workstation & AI Hub | **Workstation**: LG Gram 17, **CPU**: i7-1260P, **RAM**: 16GB, **Tags**: `desktop`, `workstation`, `ai-server` | 🟢 Active |
| ![Luffy](assets/machines/luffy.png) | **luffy** | Homelab & Control Plane | **Server**: Custom Desktop, **CPU**: i7-9700F, **RAM**: 24GB, **Tags**: `server`, `homelab`, `ai-control` | 🟢 Active |

---

## 🏛️ Dendritic Layer Architecture (v2)

Configuration logic is strictly compartmentalized across 10 numbered layers. See [layers/NUMBERING.md](layers/NUMBERING.md) for full governance specs and sub-layer numbering registries.

| Layer Band | Name | Description & Contents |
|:---|:---|:---|
| **00–09** | `00-cyberia` | System documentation, asset templates, ISO specs, audit scripts |
| **10–19** | `10-system` | Core OS foundation, CPU/GPU drivers, users, ZFS impermanence |
| **20–29** | `20-services` | System services, networking, database storage, monitoring, dashboards |
| **30–39** | `30-theming` | System-wide theme engines, Matugen colors, cursor & sound themes |
| **40–49** | `40-desktop` | Compositors (Hyprland, Niri), Noctalia shell, launchers (Rofi, Vicinae) |
| **50–59** | `50-cli-tui-programs` | Shells (Zsh, Nushell), editors (NixVim), multiplexers (Zellij, Tmux) |
| **60–69** | `60-gui-programs` | Desktop apps (Brave, CamoFox), media, development IDEs, gaming |
| **70–79** | `70-agents` | 9-tier Agent Subsystem: 71-harness, 72-voice, 73-memory, 74-ai-infra, 75-mcp, 76-orchestrators, 77-dash-desk-ui, 78-llm-routers, 79-skills |
| **80–89** | `80-lib` | Functional Nix library (`mkDendriticModule`), overlays, custom derivations |
| **90–99** | `90-profiles` | Machine profile tag aggregators (`tags/`) |

---

## 🤖 AI Swarm Control Plane & Agent Ecosystem

NFP includes a production-grade multi-agent autonomous framework structured across tiers 71–79:

* **Agent Harnesses** (`71-harness`): Hermes Agent Gateway (`:8085`), OpenCode, Antigravity IDE, DSH.
* **LLM Routing** (`78-llm-routers`): Kong Gateway (`:8090`), ExtremeRouter (`:20128`), LiteLLM, FreeLLMAPI.
* **Memory & PKB** (`73-memory`): Brain-service (`:8010`), EverOS (`:8092`), ContextForge (`:8094`), Honcho, GNO.
* **Inference Runtimes** (`74-ai-infra`): Ollama (`:11434`), llama.cpp (`:8080`), vLLM (`:8000`), LocalAI.
* **Orchestration & UIs** (`76-orchestrators`, `77-dash-desk-ui`): Polyfloor (`:7777` API-only on `nami`), Open WebUI (`:8088`), AionUI, Mission Control.

---

## 🚀 Quickstart & Session Workflow

### 1. Initialize Workspace

Clone the repository and run the session initialization harness:

```bash
git clone https://github.com/T0PSH31F/NFP.git
cd NFP
./init.sh
```

`./init.sh` automatically verifies dependencies, linter compliance (`nixfmt`, `deadnix`, `statix`), schema validity of `feature_list.json`, and machine top-level evaluation.

### 2. Fleet Deployment

NFP uses **Clan-Core** for declarative machine updates:

```bash
# Update all machines in the fleet
clan machines update

# Target a specific host
clan machines update z0r0
clan machines update luffy
```

---

## 📚 Core System Documentation

Detailed technical references are maintained under `layers/00-cyberia/01-docs/`:

* **[AGENT_ONBOARDING.md](layers/00-cyberia/01-docs/AGENT_ONBOARDING.md)** — Architectural blueprint & system boot sequence
* **[agent-layers.md](layers/00-cyberia/01-docs/agent-layers.md)** — 70-agents tier request flows, host mapping, and port table
* **[tag-matrix.md](layers/00-cyberia/01-docs/tag-matrix.md)** — Machine × Tag profile matrix and rationale
* **[harness.md](layers/00-cyberia/01-docs/harness.md)** — Harness specification & session verification workflow
* **[ai-stack.md](layers/00-cyberia/01-docs/ai-stack.md)** — Complete AI infrastructure & MCP server map
* **[ports.md](layers/00-cyberia/01-docs/ports.md)** — Fleet port allocation registry
* **[services.md](layers/00-cyberia/01-docs/services.md)** — Active service URLs & endpoints
* **[deployment.md](layers/00-cyberia/01-docs/deployment.md)** — Deployment commands & CI/CD workflows
* **[NUMBERING.md](layers/NUMBERING.md)** — Canonical layer numbering standard & CI governance

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for details.
