---
name: harness-session-protocol
description: Mandatory session lifecycle for work in the NFP repo — init, one-feature focus, verification, clean closeout.
---

# Harness Session Protocol

Use this skill at the start of any task in the NFP repository.

1. Run `./init.sh`. A red baseline means your only job is making it green.
2. Read `agent-progress.md`, `session-handoff.md`, and `feature_list.json`.
3. Claim exactly one feature. If the task from the user maps to no feature, add it to `feature_list.json` as `untried` first.
4. Work only that feature. Discoveries become new `untried` features, not scope creep.
5. Verify with the feature's own command list. Paste real output as evidence into `feature_list.json`.
6. Close out: update states, append progress log, overwrite handoff, run the clean-state checklist.

Anti-patterns: marking passing without evidence; batching multiple features; leaving working tree uncommitted or untracked.
