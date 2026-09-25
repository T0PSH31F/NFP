---
trigger: always_on
description: Guard against hanging Nix builds, duplicate updates, RAM exhaustion, and un-cached heavy builds
---

# 🛡️ Nix Build Safety & Binary Cache Pre-Flight Rule

Before initiating any heavy Nix evaluation, build, or deployment command (such as `nix build`, `nixos-rebuild`, `clan machines update`, `nix eval`, `nix flake update`), **all agents MUST execute a pre-flight system check**:

## 1. Active / Hanging Nix Process Check
Agents must check for existing Nix evaluation or build processes:
```bash
ps aux | grep -E 'nix-build|nix-daemon|nix-env|nix-store|nix-instantiate|nix eval|nix build|nixos-rebuild|clan machines update' | grep -v grep
```
- **Constraint**: If any background build/eval process is currently running or hanging from a prior attempt:
  - DO NOT launch a concurrent build/eval.
  - Report the active PID, command, and runtime duration to the user.
  - Ask the user whether to kill the existing process or wait for completion.

## 2. RAM Usage Threshold Pre-Flight Safety Check (75% Cap)
Before launching a **new** build, agents must check baseline RAM usage:
```bash
free -m
```
- Calculate memory usage percentage: `((Total - Available) / Total) * 100`.
- **Note**: RAM usage *will* naturally exceed 75-80% *during* an active build process.
- **Constraint**: If baseline system memory usage is **already exceeding 75% BEFORE initiating a new build**:
  - **ABORT / DO NOT START** any new Nix builds or evaluations.
  - **WARN THE USER**: Provide exact baseline RAM metrics (e.g. `RAM already at 82% - 12.3 GB / 15 GB used before build start`) and top memory-consuming processes (`ps aux --sort=-%mem | head -10`).
  - Request user confirmation or memory cleanup before proceeding with a new build.

## 3. Binary Cache Pre-Flight Check (`nix-weather`)
Before running system builds or flake updates, agents must verify binary cache availability:
```bash
nix-weather .#nixosConfigurations.<machine>.config.system.build.toplevel
```
- **Constraint**: If `nix-weather` reports cache misses for **heavy packages** (e.g. Hyprland, Linux Kernel, LLVM/GCC toolchains, WebKit, Rust compiler):
  - **DO NOT proced silently** to compile heavy packages from source.
  - **WARN THE USER IMMEDIATELY**: List the exact missing heavy packages (e.g. `Cache Miss: hyprland-0.56.2, cachyos-kernel-6.12.5`).
  - Ask the user if they want to proceed with a local source build or postpone until binary caches complete upstream.
