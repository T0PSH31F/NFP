# /nupdate — Package Updates, Binary Cache Pre-Flight & Fleet Deployment

Safe, cache-verified package and flake input update engine for the NFP fleet (`z0r0`, `luffy`, `sanji`). Enforces pre-flight RAM safety thresholds, verifies upstream binary cache hits via `nix-weather` to prevent accidental source compilations, clears evaluation errors, and performs orderly machine deployments.

Usage: `/nupdate [machine-name|all|input-name]` (e.g. `/nupdate`, `/nupdate z0r0`, `/nupdate --input nixpkgs`)

---

## Phase 1: Pre-Flight Safety Checks (Mandatory)
Adhere strictly to `nix-build-safety.md`:
1. **Active / Hanging Nix Process Check**:
   ```bash
   ps aux | grep -E 'nix-build|nix-daemon|nix-env|nix-store|nix-instantiate|nix eval|nix build|nixos-rebuild|clan machines update' | grep -v grep
   ```
   - If an active build process is already running, abort and report PID/runtime.
2. **RAM Threshold Check (75% Cap)**:
   ```bash
   free -m
   ```
   - Calculate usage: `((Total - Available) / Total) * 100`.
   - If baseline RAM already exceeds 75% before build start, ABORT and warn user.

---

## Phase 2: Flake Input & Package Updates
1. **Targeted or Full Lock Bump**:
   - If user specified an input:
     ```bash
     nix flake lock --update-input <input>
     ```
   - If full update requested:
     ```bash
     nix flake update
     ```
2. **Review Flake Diff**:
   - Inspect `git diff flake.lock` to verify package version bumps and check for unexpected major revisions.

---

## Phase 3: Binary Cache Pre-Flight Check (`nix-weather`)
Before initiating builds, verify binary cache availability:
```bash
nix-weather .#nixosConfigurations.<machine>.config.system.build.toplevel
```
- **Constraint**: If `nix-weather` reports cache misses for heavy packages (Linux Kernel, Hyprland, LLVM/GCC, WebKit, Rust compiler, CUDA/PyTorch):
  - **DO NOT proceed silently to compile heavy packages from source.**
  - **WARN USER IMMEDIATELY**: List exact missing heavy packages.
  - Await user confirmation before proceeding with local source compilation.

---

## Phase 4: Evaluation & Deprecation Clearance
1. **Flake Syntax & Type Check**:
   ```bash
   nix flake check --no-build
   ```
2. **Holy Rule of `mcp-nixos` Verification**:
   - If evaluation emits deprecation warnings or renamed options, query `mcp-nixos` (`nix search` / `nix_versions`) to verify the exact replacement option.
   - Patch deprecations before building.

---

## Phase 5: Build & Fleet Deployment
1. **Build / Dry Run**:
   ```bash
   clan machines update --dry-run <machine>
   ```
2. **Deploy to Target**:
   - For local machine (`z0r0`):
     ```bash
     clan machines update z0r0
     ```
   - For remote machines (`sanji`, `luffy`):
     ```bash
     clan machines update <machine>
     ```
3. **Post-Deployment Verification**:
   - Verify active bootloader generation.
   - Verify critical services status (`systemctl is-active`).
   - If failure occurs, execute immediate generation rollback.
