# NFP Autonomous Agent Playbook & Operational Memory
> Canonical distilled operational playbook generated and updated by the Jarvis Nightly Dream Cycle (`dream_miner.py`).
> Grounded in deterministic verification gates, weakness mining, and root-cause analysis.

---

## 1. Core Architectural Laws & Hard Guardrails

1. **Deterministic Verification Gate**:
   - Every self-improvement mutation, skill generation, or configuration change MUST execute `./init.sh` before merging.
   - If `./init.sh` exits with non-zero code, the candidate edit MUST be discarded immediately. Never bypass or force an invalid state.
2. **Dendritic Layer Purity**:
   - Services live under `layers/20-services/`. Agent harnesses live under `layers/70-agents/71-harness/`. Skills live under `layers/70-agents/79-skills/`.
   - Never place raw machine services at flake root or mix concerns.
3. **Impermanence & State Retention**:
   - All stateful databases (`state.sqlite`, `sessions`, `models.json`) must reside in persistent storage (`/persist/var/lib/...` or `~/.local/share/...`).
4. **Mandatory Vocalization**:
   - All task transitions, dream cycle conclusions, and alerts must vocalize through GLaDOS TTS (`glados-tts-cli`).

---

## 2. Weakness Mining & Anti-Pattern Categories

### 2.1 Failed Tool Calls
- **Symptom**: Agent invocations return JSON parsing errors, missing argument exceptions, or command execution non-zero codes.
- **Root Causes**:
  - Unescaped special characters in shell invocations.
  - Outdated tool argument schemas.
  - Concurrency lock contention on shared resources (e.g. `nfp-todo.lock`).
- **Countermeasures**:
  - Always validate input schemas before execution.
  - Use `flock` with explicit timeouts.
  - Handle tool failure returns gracefully with structured fallback actions.

### 2.2 Jev Classification Drops
- **Symptom**: Legitimate incoming events or urgent notifications are incorrectly dropped by Stage 1 zero-token heuristics.
- **Root Causes**:
  - Overly broad regex matching in `ROUTINE_PING_PATTERNS`.
  - Lack of explicit critical patterns for new failure modes.
- **Countermeasures**:
  - Anchor routine patterns to exact string boundaries (`^...$`).
  - Regularly mine dropped events in `jev_drops` table. If false drops are detected, mutate Jev heuristic rules.

### 2.3 Barge-In Voice Interrupts
- **Symptom**: User speaks during audio playback, triggering Silero VAD termination.
- **Root Causes**:
  - Overly verbose AI responses (monologuing beyond 1-2 sentences).
  - Slow time-to-first-audio leading to conversational collisions.
  - Inappropriate persona tone or irrelevant context dump.
- **Countermeasures**:
  - Strictly enforce 1-2 sentence maximum limit on all spoken output.
  - Deliver key information in the first 5 words.
  - Avoid conversational filler ("Certainly!", "I would be happy to help with that...").

### 2.4 Linter & Nix Evaluation Rejections
- **Symptom**: Pre-commit or `./init.sh` fails with `statix`, `deadnix`, or `nixfmt` errors.
- **Root Causes**:
  - Repeated keys in Nix attribute sets (statix warning [20]).
  - Unused `let` bindings or function arguments (deadnix).
  - Deprecated stdenv properties (`stdenv.isLinux` instead of `stdenv.hostPlatform.isLinux`).
- **Countermeasures**:
  - Format with `nix fmt` before committing.
  - Audit attribute set nesting; avoid duplicate dotted keys.
  - Query options with `mcp-nixos` before declaring new settings.

---

## 3. Dynamic Incident Log & Learned Mutations

| Date | Incident Type | Context / Root Cause | Applied Countermeasure / Mutation | Gatekeeper Status |
| :--- | :--- | :--- | :--- | :--- |
| 2026-10-28 | Initial Calibration | Baseline playbook synthesis | Established 4-tier weakness taxonomy and SQLite schemas | PASSED (`./init.sh`) |
