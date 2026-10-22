# NFP Layer Numbering Standard & Governance

> Canonical registry of top-level and sub-layer numbered bands within the NFP dendritic flake architecture.
> All new layer directories MUST be registered here prior to creation. CI enforces matching entries.

---

## 1. Top-Level Layer Band Allocation

| Range | Name | Description & Contents | Next Available Sub-number |
|-------|------|------------------------|---------------------------|
| **00–09** | `00-cyberia` | Architecture docs, asset templates, scripts, ISOs, tools | `10` |
| **10–19** | `10-system` | OS foundation, hardware, cpu/gpu drivers, users, impermanence | `20` |
| **20–29** | `20-services` | System services, networking, AI stack, media, monitoring, CI | `30` |
| **30–39** | `30-environments` | Desktop environments, human visual shells, environments & identity | `39` |
| **40–49** | `40-desktop` | Wayland compositors (Hyprland, Niri, Umbriel), DE frameworks, tools | `49` |
| **50–59** | `50-cli-tui-programs` | Shells (zsh, nushell), editors, TUI tools, zellij, prompts | `60` |
| **60–69** | `60-gui-programs` | Browsers, media players, GUI dev tools, communication | `69` |
| **70–79** | `70-agents` | AI agents (Hermes, OpenCode), MCP servers, skills registry | `77` |
| **80–89** | `80-lib` | Shared Nix functions, helpers, overlays, custom derivations | `86` |
| **90–99** | `90-profiles` | System profiles and machine tag assignments | `91` |

---

## 2. Sub-Layer Registry

### 00-cyberia
- `01-docs`: Canonical documentation & ADRs
- `02-assets`: Icons, wallpapers, sound effects, cursors
- `03-treasure`: Secrets & SOPS configuration
- `04-templates`: Machine & module templates
- `05-tests`: System integration test specs
- `06-scripts`: Maintenance & audit helper scripts
- `07-clan`: Clan core integration logic
- `08-iso`: Custom NixOS ISO build specs
- `09-tools`: CLI utility suite (nfpu)

### 10-system
- `11-foundation`: Core NixOS base configuration
- `12-processor`: CPU/GPU hardware profiles
- `13-users`: User account & group definitions
- `14-virtualization`: Podman, Docker, Libvirt, KVM
- `15-filesystem`: ZFS, disk layouts, impermanence
- `16-mobile`: Mobile hardware support
- `17-app-runtimes`: Python, Node.js, Rust runtimes
- `18-peripherals`: Bluetooth, audio, printing
- `19-optimizations`: Kernel tuning, earlyoom, audit

### 20-services
- `21-networking`: Tailscale, Headscale, DNS, proxy
- `22-ai`: Lead triage webhook, ad hook miner, market intelligence pipelines
- `23-media`: Jellyfin, Sonarr, Radarr, Audio
- `24-communication`: Matrix, Signal, Element
- `25-data`: PostgreSQL, Vector DBs (ChromaDB, LokB, Qdrant), Restic backups, Redis
- `26-monitoring`: Prometheus, Grafana, dashboards
- `27-automation`: n8n, Home Assistant, Crawl4AI
- `28-clan-services`: Clan module wrappers
- `29-ci`: Continuous integration runners

### 30-environments
- `30-selector`: Master experience selector (layers.desktop.experience enum)
- `31-noctalia`: Noctalia desktop shell v5 & compositor adapters (Hyprland, Niri, Umbriel)
- `32-nixarchy-rise`: Nixarchy (Omarchy 4.5 + Quickshell Rise)
- `33-end4`: End4 AGS/Hyprland environment
- `34-vibe-lab`: Custom live QML dev environment
- `35-smol-ai`: Ultra-light cage/dwl environment
- `36-cursor`: Mouse cursor themes
- `37-boot`: Plymouth & GRUB boot themes, greeters
- `38-theming`: GTK, Qt & SFX system theme assets

### 40-desktop
- `41-hyprland`: Hyprland Wayland compositor base (headless substrate)
- `42-niri`: Niri scrollable tiling compositor base
- `43-umbriel`: Umbriel Wayland compositor base
- `44-de-frameworks`: Vicinae launcher, desktop portals, action registry
- `45-file-managers`: Nautilus, Thunar GUI file managers
- `46-terminal-emulators`: Ghostty, Kitty, Foot
- `47-display`: Wayland display manager & greetd
- `48-rofi`: Rofi application launcher & cheatsheets

### 50-cli-tui-programs
- `50-entry`: CLI environment entrypoint
- `51-shells`: Zsh, Nushell, Bash configurations
- `52-editors`: Neovim, NixVim, Helix
- `53-tools`: Eza, Bat, Ripgrep, Fzf, Carapace
- `54-multiplexers`: Zellij, Tmux configurations
- `55-prompt`: Starship prompt configuration
- `56-file-managers`: Yazi, LF terminal file managers
- `57-services`: CLI background service tools
- `58-theming`: CLI matugen & color templates
- `59-integrations`: Zoxide, Direnv, Navi

### 60-gui-programs
- `61-browsers`: Brave, Zen, Firefox, CamoFox
- `62-media`: MPV, VLC, Spicetify
- `63-documents`: Obsidian, Zathura, LibreOffice
- `64-development`: VSCode, Zed, Cursor, IDEs
- `65-gaming`: Steam, Heroic, Mangohud
- `66-security`: Wireshark, Burp Suite
- `67-activities`: Activity profiles & pentesting
- `68-communication`: Discord, Telegram, Vesktop

### 70-agents
- `71-harness`: Agent runtime harnesses (OpenCode, Hermes-Agent, Supergraph)
- `72-voice`: Agent voice, ASR, TTS, Wyoming
- `73-memory`: PKB, corpus, knowledge graph, memory vault, EverOS, brain-service, context-forge, GNO
- `74-ai-infra`: Local LLM backends (Ollama, llama-cpp, llama-swap, vllm, localai) & sandbox
- `75-mcp`: Shared Model Context Protocol servers (MCP catalog, Headroom, Mistral MCP)
- `76-orchestrators`: Agent coordination & workflows (AionUI, LangGraph, Mission-Control, OpenCompany, Paperclip, Polyfloor)
- `77-dash-desk-ui`: Web frontends & desktop UIs (Ollama-UI, Open-WebUI, SillyTavern, Cherry-Studio)
- `78-llm-routers`: API routing & gateways (ExtremeRouter, FreeLLMAPI, FreeLLMPool, Kong, LiteLLM, Manifest, OmniRoute)
- `79-skills`: Agent skills, catalog, master switches, productivity stubs (ai-packages, ai-services, Aider, Fabric AI, Jan, LM Studio, llm-agents, todo-system)
- `jev`: Jev System-1 decision engine, router hooks, daemon pipelines, and CLI/TUI suites

### 80-lib
- `81-helpers`: mkDendriticModule & functional lib
- `82-overlays`: Custom package nixpkgs overlays
- `83-packages`: Custom packaged derivations
- `85-tests`: Flake evaluation & module test suite

### 90-profiles
- `tags`: Machine profile tag definitions (workstation, server)

---

## 3. Mandatory Governance Rule

1. Before creating any new directory under `layers/`, search `layers/NUMBERING.md` to select the next available number within the corresponding band.
2. Register the new directory in `layers/NUMBERING.md` in the same commit.
3. CI check (`nix flake check` -> `layer-numbering-check`) will enforce compliance on every push.
