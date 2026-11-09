# AI Agent Configuration Reference

> **Canonical doc** — keep this in sync with actual layer modules.
> Last updated: 2026-08-07. Source: `layers/70-agents/**/*.nix`

---

## 1. Quick-reference matrix

| Agent / framework | Layer option | Status | Primary MCP server | Notes |
|---|---|---|---|---|
| **OpenCode** | `layers.layer-70.agent.opencode` | **enabled by default** | yes (stdio + SSE) | OmOS multiplexer; Zellij-aware |
| **Hermes Agent** | `layers.layer-76.hermes` | opt-in | yes (stdio) | Self-improving gateway; optional Electron desktop |
| **Herm TUI** | `layers.layer-77.herm` | opt-in | consumes Hermes MCP | Operator dashboard for Hermes |
| **Open Skills** | `layers.layer-77.open-skills` | opt-in | skill library | Used by Herm; git-cloned at deploy time |
| **Claude Code** | `layers.layer-70.agent.claude-code` | opt-in | yes (stdio) | Anthropic coding agent |
| **Codex** | `layers.layer-70.agent.codex` | opt-in | yes (stdio) | OpenAI coding agent |
| **Antigravity IDE** | `layers.layer-70.agent.antigravity` | opt-in | yes (stdio) | `google-antigravity-cli` + IDE |
| **Supergraph** | `layers.layer-70.agent.supergraph` | opt-in (z0r0 only) | none | Monorepo intelligence, AST index |
| **Fabric AI** | `layers.layer-70.agent.fabric-ai` | opt-in | framework | Pattern-based prompt framework |
| **AI Agent Stack** | `layers.layer-70.agent.ai-agent-stack` | opt-in | brain-service, vector DB | Full stack: postgres, PKB, voice, langfuse |
| **ASR/TTS** | `layers.layer-70.agent.asr-tts` | opt-in | voice agent | Local speech services |
| **Hermes WebUI** | `layers.layer-78.hermes-webui` | opt-in | Hermes backend | nesquena/hermes-webui on :8787 |
| **Hermes Dashboard** | `layers.layer-76.hermes-dashboard` | opt-in | Hermes backend | Alternative admin panel |
| **MCP Gateway** | `layers.layer-75.mcp` | opt-in | aggregator | Single HTTP endpoint for all MCP servers |
| **MCP (legacy)** | `layers.layer-70.agent.mcp` | **DEPRECATED** | — | Migrate to `layers.layer-75.mcp.*` |

---

## 2. Agent details

### 2.1 OpenCode
- **Path:** `layers/70-agents/71-coding/opencode.nix`
- **Home config:** `programs.opencode` (home-manager module)
- **TUI settings:** `programs.opencode.tui.{theme, keybinds}` → written to `tui.json` (OpenCode ≥ 1.2.15)
- **Provider settings:** `programs.opencode.settings.provider.<vendor>.models.*`
- **Plugins loaded:**
  - `opencode-antigravity-auth@latest`
  - `@pantheon-ai/opencode-warcraft-notifications`
  - `octto`
  - `file:~/.config/opencode/plugins/context-capture`
  - himalaya (local MCP: `node ~/Projects/himalaya-mcp/dist/index.js`)
- **Plugins disabled:** `browser-use` (100% error rate), `ha-mcp`, `mcp-registry`, `file-manager`
- **Keybinds:** `tui.keybinds.command_list = "ctrl+shift+p"`

### 2.2 Hermes Agent
- **Path:** `layers/70-agents/76-hermes-agent/hermes.nix`
- **Option:** `layers.layer-76.hermes.enable` + optional `enableDesktop`
- **Desktop app:** builds `hermesDesktopPkg` (Electron); provides `hermes-desktop` binary
- **System packages on enable:** `hermesDesktopPkg`, `uni-pet`, `agentburn`
- **Channels:** Matrix bot (`enableMatrix`), STT (`stt.enabled`)
- **Notes:** Hermes Gateway on `:8085`; desktop wrapper intercepts `hermes desktop`/`gui` subcommands (Nix path fix)

### 2.3 Herm TUI
- **Path:** `layers/70-agents/77-herm/herm.nix`
- **Option:** `layers.layer-77.herm.enable`
- **Source:** built from GitHub `liftaris/herm` via `buildNpmPackage`
- **Integrations:** Open Skills (cloned at deploy), Hermes MCP
- **Main binary:** `herm`

### 2.4 Open Skills
- **Path:** `layers/70-agents/77-herm/open-skills.nix`
- **Option:** `layers.layer-77.open-skills.enable`
- **Behavior:** `home.activation` clones `https://github.com/liftaris/open-skills` into `~/.hermes/repo-name`
- **Used by:** Herm TUI; also referenced by Hermes skill authoring workflow

### 2.5 Claude Code
- **Path:** `layers/70-agents/71-coding/claude-code.nix`
- **Option:** `layers.layer-70.agent.claude-code.enable`
- **Home config:** `programs.claude-code` with MCP integration
- **Claude Code plugin:** installed in OpenCode plugin list (`claude-code-mcp.json`)

### 2.6 Codex
- **Path:** `layers/70-agents/71-coding/codex.nix`
- **Option:** `layers.layer-70.agent.codex.enable`
- **Home config:** `programs.codex` with MCP integration

### 2.7 Antigravity
- **Path:** `layers/70-agents/71-coding/antigravity.nix`
- **Option:** `layers.layer-70.agent.antigravity.enable`
- **Packages:** `google-antigravity-cli` (FHS env) + `google-antigravity-ide` (Noctalia-themed)
- **Home config:** `programs.antigravity-cli` in home-manager

### 2.8 Supergraph
- **Path:** `layers/70-agents/71-coding/supergraph.nix`
- **Option:** `layers.layer-70.agent.supergraph.enable`
- **Enabled only on:** z0r0 (`machines/z0r0/default.nix`)
- **Package:** prebuilt binary from GitHub releases (`v1.1.33`)
- **No MCP server** — CLI tool used by agents for codebase indexing

### 2.9 Fabric AI
- **Path:** `layers/70-agents/73-tooling/fabric-ai.nix`
- **Option:** `layers.layer-70.agent.fabric-ai.enable`
- **Sub-options:** `enableZshIntegration`, `enableBashIntegration`, `enableYtAlias`, `enablePatternsAliases`
- **Framework type:** prompt patterns, not an MCP server

### 2.10 AI Agent Stack (full infra)
- **Path:** `layers/70-agents/74-ai-infra/default.nix`
- **Option:** `layers.layer-70.agent.ai-agent-stack.enable`
- **Enables:** postgres, brain-service, voice
- **Side effect:** `services.infrastructure.langfuse.enable = true`
- **Consumers:** zeroclaw, openclaw, hermes, vectorcode

### 2.11 ASR/TTS
- **Path:** `layers/70-agents/72-voice/asr-tts/agent-audio.nix`
- **Option:** `layers.layer-70.agent.asr-tts.enable`
- **Scope:** local speech packages only (not services)

### 2.12 Hermes WebUI
- **Path:** `layers/70-agents/78-hermes-webui/hermes-webui.nix`
- **Option:** `layers.layer-78.hermes-webui.enable`
- **Port:** `8787`
- **Backend:** talks to Hermes Agent gateway

### 2.13 Hermes Dashboard
- **Path:** `layers/70-agents/76-hermes-agent/dashboard.nix`
- **Option:** `layers.layer-76.hermes-dashboard.enable`
- **Role:** alternative admin panel to WebUI

### 2.14 MCP Gateway
- **Path:** `layers/70-agents/75-mcp/server-catalog.nix`
- **Option:** `layers.layer-75.mcp.enable`
- **Sub-option:** `gateway.enable` — aggregates all MCP servers behind single HTTP
- **Replaces:** `layers.layer-70.agent.mcp` (DEPRECATED)

---

## 3. Shared LSP / editor config (affects agents)

### Helix language servers
- **Path:** `layers/50-cli-tui-programs/52-editors/helix.nix`
- Python LSP: `python3Packages.python-lsp-server` (tracks nixpkgs' default interpreter; no pin to 3.12)
- Also configures: `nixd`, `clangd`, `ocaml-lsp`, `rust-analyzer`, `hyprls`, `bash-language-server`
- **Conflict note:** pinning `python312Packages.python-lsp-server` forces an entire uncached Python 3.12 tree (scipy build + 39-minute test suite that fails on a `2e-09` floating-point tolerance). Fixed 2026-08-07.

### OpenCode plugin list (shared)
- `opencode-antigravity-auth@latest` — Antigravity provider auth
- `@pantheon-ai/opencode-warcraft-notifications` — desktop notifications
- `octto` — ?
- `file:~/.config/opencode/plugins/context-capture` — local plugin (JS)
- `claude-code` — Hermes MCP adapter for Claude Code
- himalaya — local MCP for email

---

## 4. Conflict matrix

### ⚠️ Conflicts

| A | B | Type | Explanation |
|---|---|---|---|
| `layers.layer-75.mcp` | `layers.layer-70.agent.mcp` | **DEPRECATED migration** | Legacy MCP module still exists; do NOT enable both. Migrate to `layer-75`. |
| `layers.layer-76.hermes.enableDesktop` | low RAM | **Resource** | Electron app (~200MB+ idle). Disable on z0r0 if RAM constrained. |
| `layers.layer-77.herm` | `layers.layer-77.open-skills` | **Soft dependency** | Herm TUI expects open-skills repo at `~/.hermes/repo-name`; enable both or neither. |
| `layers.layer-70.agent.ai-agent-stack` | `layers.layer-70.agent.asr-tts` | **Soft overlap** | Stack enables voice internally; enabling both ASR/TTS may duplicate packages. |
| Helix `python-lsp.command` | `pkgs.python312Packages.*` | **Build killer** | Pinning py312 forces scipy/pint/uncertainties source builds (39min, test failure). Use `python3Packages`. |
| `browser-use` (OpenCode plugin) | stable builds | **100% error rate** | Disabled by default in opencode.nix; never enable. |
| `mcp-registry` (OpenCode plugin) | stable builds | **never worked** | Disabled by default; dead code. |

### ✅ No conflicts (safe to co-enable)

| Combination | Notes |
|---|---|
| OpenCode + Claude Code + Codex + Antigravity | All use separate home-manager programs; MCP servers are isolated |
| Hermes + Herm TUI + Open Skills | Hermes is the backend; Herm is the TUI; open-skills is the skill library |
| Hermes WebUI + Hermes Dashboard | Different ports/services; WebUI is preferred |
| Supergraph + any coding agent | Supergraph is a CLI indexer, no runtime server |
| Fabric AI + any coding agent | Pattern library; zero runtime overlap |
| AI Agent Stack + Hermes | Stack provides infra (postgres/brain); Hermes is the agent runtime |

### 🔀 MCP server ownership

| Server | Provided by | Consumed by |
|---|---|---|
| himalaya | OpenCode local MCP | OpenCode only |
| claude-code-mcp | Hermes adapter | Hermes → Claude Code |
| brain-service MCP | AI Agent Stack | Hermes, OpenCode, any agent |
| MCP Gateway | layer-75 | aggregator for all |

---

## 5. Machine overrides

- **z0r0:** supergraph enabled (`machines/z0r0/default.nix:112`)
- **luffy:** no layer-70 overrides in `machines/luffy/default.nix`; uses shared defaults

---

## 6. How to enable

```nix
# In machines/<host>/default.nix or a tag profile:
layers.layer-70.agent.opencode.enable = true;        # already default on desktop
layers.layer-70.agent.antigravity.enable = true;
layers.layer-76.hermes.enable = true;
layers.layer-76.hermes.enableDesktop = true;         # Electron app
layers.layer-77.herm.enable = true;
layers.layer-77.open-skills.enable = true;
layers.layer-75.mcp.enable = true;
layers.layer-75.mcp.gateway.enable = true;
```

Never enable both `layer-70.agent.mcp` (legacy) and `layer-75.mcp` — they collide.
