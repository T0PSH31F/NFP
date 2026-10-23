# NFP — Agent Operating Instructions

> This file defines rules, conventions, and mandatory workflows for working in the NFP flake.

---

## Startup Workflow (required every session)

1. Run `./init.sh`. If it fails, fix the baseline before any feature work.
2. Read `agent-progress.md` (last verified status) and `session-handoff.md`.
3. Open `feature_list.json`; select exactly ONE feature not in state `passing`. Work only that feature.
4. Implement. Follow the scoped rules in `.agents/rules/` (they carry trigger frontmatter).
5. Run every command in the feature's `verification` list. Record outputs as evidence in `feature_list.json`.
6. Score the work against `evaluator-rubric.md` (≥ 8, no zeros).
7. Update `feature_list.json` (state + evidence), append to `agent-progress.md`, overwrite `session-handoff.md`.
8. After context loss or crash, NEVER re-mark prior work passing from memory — re-run the verification commands or reopen the feature.
9. **`feature_list.json` Size Cap**: Keep `feature_list.json` under 300 lines to preserve context window. Archive older passing features to `feature_list_archive.json` whenever it exceeds 300 lines (enforced by CI).

Never mark work complete without recorded evidence. Never expand scope mid-session; record new ideas as `untried` features.

---

## 1. Documentation — Read, Refer, Update

The `layers/00-cyberia/01-docs/` directory is the canonical knowledge base.
- **Key Docs**: `AGENT_ONBOARDING.md` (system overview & boot flow), `harness.md` (harness spec & workflow), `ports.md` (port allocation registry), `services.md` (service ports & URLs), `deployment.md` (deployment commands).
- **Rules**: Read before changing; update when modifying features/services; check `.agents/rules/` for triggered rules (`clan-architecture.md`, `mcp-nixos-bible.md`, `nix-build-safety.md`, `organization.md`, `recovery.md`).

---

## 2. Build & Deploy Commands

**ALWAYS use Clan machine updates — never raw nixos-rebuild**
```bash
clan machines update          # update all machines
clan machines update z0r0     # update specific machine (e.g. z0r0, luffy)
```
*Why*: Clan manages remote deployment, sops secret distribution, and machine inventory.

---

## 3. Determinism — All Config Through the Flake

- **Golden Rule**: Every configuration change must be made through the NFP flake (`layers/`).
- **Dotfiles**: Symlinks to Nix store managed by Home-Manager. Never edit generated dotfiles directly.
- **Secrets**: NEVER hardcode secrets. ALWAYS use `clan.core.vars` / `sops-nix`.

---

## 4. System Architecture Summary

- **z0r0**: Workstation / AI server (`root@127.0.0.1`)
- **luffy**: Homelab server / AI control plane (`root@100.80.146.120`)
- **Dendritic Layers**: `10-system`, `20-services`, `30-theming`, `40-desktop`, `50-cli-tui`, `60-gui`, `70-agents`, `80-lib`, `90-profiles/tags`.
- See `layers/00-cyberia/01-docs/AGENT_ONBOARDING.md` for full architecture.

---

## 5. Critical Constraints & Known Issues

- **Never run `nix-store --gc`**: Use `nix-safe-gc` or `nix-collect-garbage --delete-older-than 14d`.
- **Atomic Commits & Pushes**: All changes must be committed with proper layer/module reference and cross-machine impact.

---

## 6. AI Infrastructure Overview

- **70-agents Subsystem**: Structured across `71-harness` (agents/IDEs), `72-voice` (speech engines), `73-memory` (RAG/PKB), `74-ai-infra` (inference), `75-mcp` (tool catalog), `76-orchestrators` (swarms), `77-dash-desk-ui` (chat UIs), `78-llm-routers` (gateways), `79-skills` (packages/skills).
- **OpenCode**: `layers/70-agents/71-harness/opencode.nix` (skills: `./opencode/skills`, agents: `./opencode/agents`).
- **Hermes-Agent**: `layers/70-agents/71-harness/hermes/hermes.nix` (gateway `:8085`, browser `:9377`, dashboard `:9119`).

---

## 7. Git Identity & Conventions

- **Git Identity**: Ensure git commits use proper user email/name (`t0psh31f <wrighterik77@gmail.com>`) instead of placeholder defaults (`t0psh31f@example.com`).
- **Cross-Machine Impact**: Note cross-machine impact in commit footers (shared layers affect both z0r0 and luffy).

---

## 8. Multi-Agent Communication & Mandatory Voice Notifications

- **Mandatory Voice Notifications (ALL AGENTS)**:
  - Every AI agent (`Antigravity/Gemini`, `Hermes`, `Pi`, `OpenCode`, `Claude Code`, `Codex`) MUST vocalize task completions, major updates, alerts, and notifications in GLaDOS voice using:
    ```bash
    /home/t0psh31f/.local/bin/glados-tts-cli "<concise 1-2 sentence update in GLaDOS voice>" >/dev/null 2>&1 &
    ```
- **How Agents Communicate (A2A & Shared Blackboard)**:
  1. **Hermes <-> Pi 24/7 Durable A2A Bridge (`hermes-a2a` / `pi-durable-daemon :8089`)**:
     - Hermes (`:8085` gateway / `:8880` voice) acts as the 24/7 front door and delegates coding, shell, and file-modification work to the durable Pi daemon (`127.0.0.1:8089`) via the `pi_worker_delegate` MCP tool (`layers/70-agents/75-mcp/pi-a2a-mcp.py`).
     - Pi preserves durable session context in `/persist/var/lib/pi-agent/sessions` across delegations and reboots.
  2. **Shared Multi-Agent Todo Blackboard (`nfp-todo` MCP + `~/Notes/EverOS/todo.md`)**:
     - All agents share a single canonical Markdown file (`~/Notes/EverOS/todo.md`, symlinked to `~/Notes/todo.md`) with `fcntl.flock` locking and section-scoped write guards (`## Erik`, `## Hermes`, `## Pi`, `## OpenCode`, `## Claude`, `## Gemini`, `## Ideas`).
     - Agents read the full board via `todo_list`, update only their own fenced section via `todo_add` / `todo_complete`, and claim tasks tagged `@<agent>` from `## Erik` via `todo_claim`.
  3. **Shared Semantic Memory (`OpenViking :20120` & `ContextForge :8000`)**:
     - Long-term architectural facts, session transcripts, and cross-agent artifacts are indexed in OpenViking (`http://127.0.0.1:20120`) and ContextForge (`http://127.0.0.1:8000`).


---

## 8. Multi-Agent Communication & Mandatory Voice Notifications

- **Mandatory Voice Notifications (ALL AGENTS)**:
  - Every AI agent (`Antigravity/Gemini`, `Hermes`, `Pi`, `OpenCode`, `Claude Code`, `Codex`) MUST vocalize task completions, major updates, alerts, and notifications in GLaDOS voice using:
    ```bash
    /home/t0psh31f/.local/bin/glados-tts-cli "<concise 1-2 sentence update in GLaDOS voice>" >/dev/null 2>&1 &
    ```
- **How Agents Communicate (A2A & Shared Blackboard)**:
  1. **Hermes <-> Pi 24/7 Durable A2A Bridge (`hermes-a2a` / `pi-durable-daemon :8089`)**:
     - Hermes (`:8085` gateway / `:8880` voice) acts as the 24/7 front door and delegates coding, shell, and file-modification work to the durable Pi daemon (`127.0.0.1:8089`) via the `pi_worker_delegate` MCP tool (`layers/70-agents/75-mcp/pi-a2a-mcp.py`).
     - Pi preserves durable session context in `/persist/var/lib/pi-agent/sessions` across delegations and reboots.
  2. **Shared Multi-Agent Todo Blackboard (`nfp-todo` MCP + `~/Notes/EverOS/todo.md`)**:
     - All agents share a single canonical Markdown file (`~/Notes/EverOS/todo.md`, symlinked to `~/Notes/todo.md`) with `fcntl.flock` locking and section-scoped write guards (`## Erik`, `## Hermes`, `## Pi`, `## OpenCode`, `## Claude`, `## Gemini`, `## Ideas`).
     - Agents read the full board via `todo_list`, update only their own fenced section via `todo_add` / `todo_complete`, and claim tasks tagged `@<agent>` from `## Erik` via `todo_claim`.
  3. **Shared Semantic Memory (`OpenViking :20120` & `ContextForge :8000`)**:
     - Long-term architectural facts, session transcripts, and cross-agent artifacts are indexed in OpenViking (`http://127.0.0.1:20120`) and ContextForge (`http://127.0.0.1:8000`).


---

## 8. Multi-Agent Communication & Mandatory Voice Notifications

- **Mandatory Voice Notifications (ALL AGENTS)**:
  - Every AI agent (`Antigravity/Gemini`, `Hermes`, `Pi`, `OpenCode`, `Claude Code`, `Codex`) MUST vocalize task completions, major updates, alerts, and notifications in GLaDOS voice using:
    ```bash
    /home/t0psh31f/.local/bin/glados-tts-cli "<concise 1-2 sentence update in GLaDOS voice>" >/dev/null 2>&1 &
    ```
- **How Agents Communicate (A2A & Shared Blackboard)**:
  1. **Hermes <-> Pi 24/7 Durable A2A Bridge (`hermes-a2a` / `pi-durable-daemon :8089`)**:
     - Hermes (`:8085` gateway / `:8880` voice) acts as the 24/7 front door and delegates coding, shell, and file-modification work to the durable Pi daemon (`127.0.0.1:8089`) via the `pi_worker_delegate` MCP tool (`layers/70-agents/75-mcp/pi-a2a-mcp.py`).
     - Pi preserves durable session context in `/persist/var/lib/pi-agent/sessions` across delegations and reboots.
  2. **Shared Multi-Agent Todo Blackboard (`nfp-todo` MCP + `~/Notes/EverOS/todo.md`)**:
     - All agents share a single canonical Markdown file (`~/Notes/EverOS/todo.md`, symlinked to `~/Notes/todo.md`) with `fcntl.flock` locking and section-scoped write guards (`## Erik`, `## Hermes`, `## Pi`, `## OpenCode`, `## Claude`, `## Gemini`, `## Ideas`).
     - Agents read the full board via `todo_list`, update only their own fenced section via `todo_add` / `todo_complete`, and claim tasks tagged `@<agent>` from `## Erik` via `todo_claim`.
  3. **Shared Semantic Memory (`OpenViking :20120` & `ContextForge :8000`)**:
     - Long-term architectural facts, session transcripts, and cross-agent artifacts are indexed in OpenViking (`http://127.0.0.1:20120`) and ContextForge (`http://127.0.0.1:8000`).
