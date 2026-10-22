# /noctor — Codebase Doctor: Hygiene, Security & Anti-Pattern Remediation

Strict remediator for existing codebase. Formats, lints, prunes dead code, audits comments, patches security vulnerabilities, audits secrets/PII leaks, eliminates bad abstractions, enforces uniform syntax & dendritic nesting patterns, and verifies production quality.

Usage: `/noctor [path/or/subsystem]` (defaults to dirty files and touched layers, or full codebase if requested)

---

## Phase 1: Formatting, Linting & AST Cleanliness
1. **Formatting**:
   - Run `nix fmt` (or `treefmt`) across target scope.
2. **Nix AST & Static Analysis**:
   - Run `statix check` to catch anti-patterns and unused code.
   - Run `deadnix` to locate and prune unused `let ... in` bindings and unused arguments.

---

## Phase 2: Dead Code & Bad Abstraction Pruning
1. **Dead Code Elimination**:
   - Remove commented-out code blocks, orphan files, and unreachable imports.
   - Delete obsolete references to decommissioned hardware (e.g. `nami`).
2. **Bad Abstraction Flattening**:
   - Collapse unnecessary indirection: layers wrapping single options, redundant wrapper scripts, over-complicated `lib.mkMerge` where simple attribute sets suffice.
   - Ensure harness configurations (OpenCode, Antigravity, Hermes) adhere to flat, composable standards.

---

## Phase 3: Comment Context, Relevance & Recency Audit
1. **Drop Noise**: Remove self-evident comments (e.g., `# enable git` above `programs.git.enable = true;`).
2. **Prune Stale Workarounds**: Audit comments containing `TODO`, `FIXME`, `HACK`, `temporary`, or dates. If upstream fix landed or issue resolved, remove both workaround and comment.
3. **Preserve Architectural "Why"**:
   - Keep non-obvious hardware quirks (PCI IDs, kernel modules, power management).
   - Keep inter-agent port contracts and routing topologies.
   - Keep safety constraints (memory thresholds, LUKS/Btrfs subvolume layout).

---

## Phase 4: Security, Secrets & PII Leak Prevention
1. **Secrets & PII Audit**:
   - Scan git tree for unencrypted age keys, private SSH keys, cloud tokens, API keys (`AIza...`, `ghp_...`, `sk-...`), or hardcoded personal credentials.
   - Verify all persistent state and keys target `/persist/...` under impermanence.
   - Ensure SOPS secrets use proper permissions (`0600` / `0400`) and valid user/group IDs.
2. **Vulnerability Scanning**:
   - Run `vulnix` (or `nix audit` / nixpkgs security scanner) on system toplevel closure when applicable to identify known CVEs.

---

## Phase 5: Anti-Pattern & Holy Rule Verification
1. **The Holy Rule of `mcp-nixos`**:
   - Query `mcp-nixos` (`nixos` MCP server: `nix` tool) for EVERY modified, deprecated, or questionable option.
   - Zero guessing of option names, Home Manager paths, or NVF settings.
2. **Tags-as-Data**:
   - Layers MUST gate functionality on tags (`builtins.elem "<tag>" config.machine.tags`), NEVER on machine hostnames.
3. **Overridable Profile Defaults**:
   - Every option default in `layers/90-profiles/` MUST use `lib.mkDefault`.

---

## Phase 6: Uniform Syntax, Attribute Nesting & Dendritic Patterns
1. **Clean Attribute Set Nesting**:
   - Group related nested attributes into coherent blocks rather than fragmented dotted keys:
     ```nix
     # GOOD: Coherent nested block
     layers.layer-71.harness = {
       antigravity = {
         enable = lib.mkDefault true;
         enableIde = lib.mkDefault true;
       };
       opencode.enable = lib.mkDefault true;
     };

     # BAD: Mixed dotted fragments scattered randomly
     layers.layer-71.harness.antigravity.enable = true;
     layers.layer-71.harness.antigravity.enableIde = true;
     layers.layer-71.harness.opencode.enable = true;
     ```
   - Never mix dotted syntax and block syntax for the same parent within a single file.
2. **`attrsOf` Option Safety**:
   - NEVER populate `default = { ... }` on an `attrsOf submodule` option definition. User definitions of individual sub-keys override the entire set. Always declare default catalog entries inside `config = mkIf cfg.enable { <path>.servers = { ... }; }` so attribute sets merge cleanly.
3. **Variable & Scope Uniformity**:
   - Standard let-binding convention: `let cfg = config.layers.layer-<XX>.<domain>.<feature>; in { ... }`.
   - Primary user parameterization: Reference `config.layers.meta.primaryUser or "t0psh31f"` instead of hardcoding raw strings.
   - Casing conventions: camelCase for Nix options/variables, kebab-case for package names, files, and machine tags.
4. **Dendritic Layer Alignment**:
   - Ensure every module aligns strictly with its tier (`10-system`, `20-services`, `30-theming`, `40-desktop`, `50-cli`, `60-gui`, `70-agents`, `80-lib`, `90-profiles`).

---

## Phase 7: Production Verification & Report
1. Verify evaluation sanity:
   ```bash
   nix flake check --no-build
   ```
2. Output concise Caveman summary:
   - Formatted files & pruned lines.
   - Dead code & bad abstractions removed.
   - Comments pruned / updated.
   - Security & secrets scan status.
   - Attribute nesting & dendritic pattern fixes.
   - Flake evaluation status.
