# Session Handoff

> Compact state for the next session. Overwrite entirely at the end of each session.

- **Active feature:** `shared-agent-todo-mcp-and-infomarchy-desktop`
- **Last verified green:**
  - `./init.sh --worktree` -> PASSED (5/5 checks passed across all 3 machines: `luffy`, `z0r0`, `sanji`)
  - `curl -sf http://127.0.0.1:8089/healthz` -> PASSED (`pi-durable-daemon` active with `free-first`, `cascade-balanced`, and `frontier` tiers)
  - `nfp-todo list --rofi` -> PASSED (multi-agent fenced sections, write guards, `@agent` tag routing, `todo_claim`, `todo_write_report`, and MCP JSON-RPC verified)
  - `infomarchy-ctl status` & `infomarchy-ctl refresh` -> PASSED (live Quickshell geometry JSON returned and widgets refreshed)
- **Blockers:** None. Deploying via `clan machines update sanji` per Erik's approval.

## Work Completed This Session

1. **Kong Gateway, Declarative Client Discovery, Jev Tier Router, 24/7 Voice Agent & Router Consolidation (`commit 9c24609`)**:
   - All Phases 0–5 verified green and committed.

2. **Shared Multi-Agent Todo System + `nixfred/infomarchy` Desktop Integration (`commit d40007a`)**:
   - Canonical `~/Notes/EverOS/todo.md` with fenced per-owner sections, `fcntl.flock`, section write guards, `rofi-todo` (`Super+.` and `Super+Shift+.`), and declarative `nixfred/infomarchy` (`Super+D`, `Super+I`, `Super+Shift+I`, `Super+Alt+I`).

3. **Durable 24/7 Pi + Hermes Autonomous Task Decomposition, Reports, Token Optimization & Universal Voice Rule**:
   - Universal GLaDOS voice notification rule (`glados-tts-cli`) embedded in `GEMINI.md`, `AGENTS.md`, `CLAUDE.md`, `pi-coding-agent.nix`, `hermes.nix`, `opencode.nix`, `claude-code.nix`, and `codex.nix`.
   - Created `pi-durable-daemon.py` (`systemd.services.pi-durable-daemon`, `:8089`, `/persist/var/lib/pi-agent/sessions`) and upgraded `nfp-todo-mcp.py` (`todo_write_report`) + `pi-a2a-mcp.py` (`pi_decompose_and_advance`):
     - Breaks tasks in `## Pi` and `## Hermes` down into `[SAFE-AUTO]` vs `[APPROVAL-GATE]` steps.
     - Executes 100% of `[SAFE-AUTO]` preparation, code/config refinement, and non-destructive verification using `jev/free-first` and `jev/cascade-balanced` (free + subscription quota models).
     - Pauses cleanly at `[APPROVAL-GATE]` steps (`[⏳ AWAITING-APPROVAL]`) and writes a detailed Markdown report in `~/Notes/EverOS/reports/<YYYY-MM-DD>-<agent>-<slug>.md` linked directly in `todo.md`.
   - Optimized `hermes.nix` for Kong/Jev free-first routing (`model.default = "jev/free-first"`, `fallback = "kong-er/Coding"`) and tight context/token hygiene (`file_read_max_chars: 32000`, `tool_output.max_bytes: 16384`, `compression.threshold: 0.60`, `protect_last_n: 10`, `hygiene_hard_message_limit: 120`, `hard_stop_enabled: true`).

## Next Workstreams

1. Complete `clan machines update sanji` and verify `nfp-llm-doctor` 7/7 green post-activation.
