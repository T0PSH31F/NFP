---
description: Nix concurrency, resource safety, and flock coordination rules
trigger: "always_on"
---

# Nix Resource Safety & Concurrency Protocol

1. **Guarded Commands Only**: Always execute Nix evaluations, flake checks, and builds through `./layers/00-cyberia/06-scripts/nfp-check.sh` (or `nfp-check`).
2. **Single Process Enforcement**: Never launch concurrent or overlapping Nix/Clan build or evaluation processes across subshells or terminal tabs.
3. **Lock & Preflight Check**: Before starting any Nix command, verify lock status:
   `ps -eo pid,ppid,etime,%cpu,%mem,cmd | grep -E '[n]ix (build|eval|flake check)'`
4. **No Unneeded Reruns**: Never rerun a passing verification command if no relevant files have changed.
5. **Clean Process Lifecycle**: Never abandon child processes or background jobs running Nix commands.
6. **Targeted Process Management**: Never run global `pkill nix`, `killall nix`, or kill processes not started by your own subshell.
