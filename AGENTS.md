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
clan machines update sanji     # update local machine (Dell Precision 7680)
clan machines update z0r0      # update remote workstation / builder
clan machines update luffy     # update homelab server
```
*Why*: Clan manages remote deployment, sops secret distribution, and machine inventory.

---

## 3. Determinism — All Config Through the Flake

- **Golden Rule**: Every configuration change must be made through the NFP flake (`layers/`).
- **Dotfiles**: Symlinks to Nix store managed by Home-Manager. Never edit generated dotfiles directly.
- **Secrets**: NEVER hardcode secrets. ALWAYS use `clan.core.vars` / `sops-nix`.

---

## 4. System Architecture Summary

- **sanji**: Dell Precision 7680 Workstation (`root@100.64.0.6` / `192.168.1.68`)
- **z0r0**: Remote Workstation / AI Builder (`root@100.64.0.1`)
- **luffy**: Homelab server / AI control plane (`root@100.64.0.3` / `192.168.1.54`)
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

<!-- RTK_TOKEN_SAVER_START -->
# RTK Token Saver Rule (agents)

## RTK (Rust Token Killer) Optimization Rule
Prefix every shell/terminal execution command with `rtk`:
- `rtk git status`, `rtk git diff`, `rtk git log -n 5`
- `rtk npm test`, `rtk npm run build`, `rtk pnpm test`, `rtk yarn test`
- `rtk cargo check`, `rtk cargo test`, `rtk cargo build`
- `rtk pytest`, `rtk vitest`
- `rtk ls src/`, `rtk tree -L 2`, `rtk rg "pattern"`

Keep the prefix inside chains: `rtk git add . && rtk git commit -m "msg"`.
Commands RTK has no filter for run as-is, so the prefix is always safe.

### Output & Token Optimization
Command output is condensed to save 60-90% LLM context window tokens while preserving every critical signal, error, and exit code.
- `rtk gain` / `rtk gain --history` - View token savings scoreboard.
- `rtk proxy <cmd>` - Run a command unfiltered if raw output is strictly needed.
- `RTK_DISABLED=1 <cmd>` - Skip RTK for one command.

## 3-Tier Hybrid Web Research & Scraping Policy (Upstream: fastcrw/crw & lightpanda-io/browser)
When your IDE agent receives a task requiring web research or extraction, it follows this strict 3-tier routing logic:

1. **Discovery (Tier 1 - Default Search)**:
   - The agent uses its built-in search tool (`search_web` / native search) to find target URLs or documentation links.
2. **Fast Extraction (Tier 2 - fastCRW)**:
   - The agent attempts to fetch the URL using fastCRW (`crw scrape <url>`, `crw_scrape`, or `http://127.0.0.1:3000`).
   - If the page is server-rendered (like a blog, GitHub README, or docs site), fastCRW instantly grabs clean Markdown/text, saving 70-90% context tokens without JS engine overhead.
3. **Deep Dynamic Rendering (Tier 3 - Lightpanda Local via MCP)**:
   - If fastCRW returns empty content, a rendering error, or hits a client-side JavaScript wall (e.g., a React/Vue SPA app or login-gated dashboard), the agent automatically falls back to Lightpanda Local via MCP (`lightpanda mcp`).
   - Lightpanda executes the JS via V8 and feeds a clean Accessibility Tree or Markdown back into the IDE context window using ~10x less memory than headless Chrome.


## Mandatory Semantic Knowledge Graph First Policy (Token Saver Enforcement)
Autonomous AI agents in ANY IDE MUST ALWAYS query the pre-indexed semantic knowledge graphs to provide answers BEFORE falling back to raw file reads that waste prompt tokens:

### 1. Code-Based Files -> CodeGraphContext (Upstream: CodeGraphContext/CodeGraphContext)
- **Code Query Engine:** For all code architecture, symbol definitions, function signatures, call hierarchies (callers/callees), class inheritance, and module dependencies, AI agents MUST query the CodeGraphContext index (/codegraph-query, `cgc query`, `cgc find`, or CodeGraphContext MCP tools) FIRST.
- **Zero-Waste Fallback:** NEVER dump or read entire source code files or directory trees into LLM prompt context when answering code questions. Only fall back to localized file reads (and then only targeted slices) if the knowledge graph query does not provide sufficient detail.
- **Live Synchronization:** The project code graph is continuously kept updated via background incremental sync / `cgc watch` / on-save triggers.

### 2. Non-Code Files -> JevGraph (Upstream: chenmingtang830/jevgraph)
- **Document Query Engine ONLY:** JevGraph is strictly designated for non-code files (documentation, Markdown specs, PRDs, PDFs, Word docs `.docx`, slides `.pptx`, text `.txt`).
- **Bounded Evidence:** When ingesting large specs, PRDs, PDFs, or architectural documentation, build or query bounded evidence-backed knowledge graphs (/jevgraph-build, /jevgraph-query) with character-level page maps instead of loading raw long documents into prompt context.
- **Strict Separation:** NEVER use JevGraph for source code AST indexing; code files are strictly handled by CodeGraphContext.


## Headroom Context Compression (Upstream: headroomlabs-ai/headroom)
- Utilize Headroom context compression and Compress-Cache-Retrieve (CCR) for heavy JSON structures, file reads, and tool payloads to minimize prompt tokens.


## Anti-Slop Filter & Quality Rules (Upstream: miqdadbadjuber/anti-slop)
Follow Anti-Slop rules to prevent generic AI slop in generated UI, copy, and code comments (Mode: DURING):
- **Filter, Not Style Guide:** Run purpose tests before aesthetic choices (reject ungrounded neon glows, fake metrics, generic sparkle badges).
- **Liveliness & Grounding:** Rely on `DESIGN.md` or explicit brief for design soul; enforce WCAG AA human accessibility.
- **Dedicated Skills:** Read `skills/antislop/SKILL.md` (core), `skills/antislop-ui/SKILL.md`, `skills/antislop-copywriting/SKILL.md`, `skills/antislop-human/SKILL.md`, `skills/antislop-layoutmobile/SKILL.md`, `skills/antislop-code/SKILL.md` when performing relevant tasks.


## Output & Generation Token Saver Rule (Ponytail Mode: FULL)
- **YAGNI & Shortest Diff:** Only write code that must exist. Reach for standard library before custom code or new dependencies. Shortest working diff wins.
- **Terse Responses:** Code first. At most 3 short lines of explanation: what was skipped, when to add it. No essays, no unsolicited design tours, no feature walkthroughs.

## Terse Agent Directives
- Eliminate pleasantries, greetings, and conversational filler. Provide direct answers and actionable code.
- Avoid reprinting unchanged code blocks. Use targeted search/replace blocks or concise snippets.

## Context Optimization (Compact Diffs & Outlines)
- Inspect git changes using compact single-line diffs: `rtk git diff -U1` instead of wide multi-line context.
- When exploring codebases, inspect function signatures / AST outlines (/rtk-outline) before reading entire files into context.

## ECC Context Management & Compaction Protocol (Upstream: affaan-m/ECC)
Autonomous AI agents MUST actively manage conversation context window load to prevent token bloat and degraded reasoning:
1. **Strategic Compaction at Milestones:** At major phase completions or after 50+ tool calls, invoke strategic compaction (/strategic-compact) to summarize completed steps, pruned raw outputs, and focus active memory strictly on pending requirements.
2. **Context Keeper (`ck`) Snapshots:** Before major context purges, architectural refactors, or switching tasks, persist durable checkpoint files (`.agents/ck/context.json` and `.agents/ck/CONTEXT.md` or invoke /ck:save) so state is never lost across conversation boundaries.
3. **Anti-Loop Council & Agent Evaluation:** If stuck in repeated failed edits, build verification errors, or circular debug loops (>3 failed attempts), invoke /council or /agent-evaluator to obtain root-cause guidance and stop wasting tokens on trial-and-error repetition.

## Upstream Engine Integration & Latency Guardrails Standards
Whenever a new upstream engine or external tool (e.g. `fastcrw/crw`, `CodeGraphContext`, `JevGraph`) is introduced or updated:
1. **Holistic Dashboard Integration (8 Surfaces Required)**:
   - Header action toggle button (`Turn <Tool> ON / OFF`)
   - Setup alert banner (missing chips + AI install prompt generator)
   - Dedicated dashboard section & Quick Action triggers
   - Multi-channel savings breakdown navigation tabs & distribution weights
   - System Health diagnostics row with status, AI install prompt, sync, and uninstall actions
   - Upstream versions dropdown listing
   - Upstream Sync Picker (`showSyncPicker`) and Uninstall Picker (`showUninstallPicker`)
   - Footer upstream reference links
2. **Zero-Noise Latency Benchmarks**: "Test Upstream Latencies" must selectively ping and display only **installed** upstream components, silently omitting/ignoring uninstalled tools so users never see failed pings or clutter for optional tools.
3. **Footer Version Number Invariant**: The current plugin release version must always be presented beside "Token Saver" in front of "• GitHub".

<!-- RTK_TOKEN_SAVER_END -->
