# Yazelix Integration Issue

**Date**: 2026-02-06  
**Status**: BLOCKED - Upstream Issue  
**Priority**: High (user requirement)

## Problem

The yazelix flake input fails to build with error:
```
error: path '«github:luccahuguet/yazelix/284eff105ba7269f1474a5ba223116698da775e7»/flake.nix' does not exist
```

## Root Cause

Investigation reveals that the yazelix repository (**github:luccahuguet/yazelix**) does not contain a `flake.nix` file. The repository only has:
- `devenv.nix`
- `dev env.yaml`
- `devenv.lock`

This is a devenv-based project, not a Nix flake.

## Current Usage

In `modules-old/nixos/yazelix.nix`, yazelix is imported as:
```nix
imports = [
  inputs.yazelix.homeManagerModules.default
];
```

This expects yazelix to provide a Home Manager module via flake outputs, which requires a `flake.nix` file.

## Investigation Results

- ❌ No `flake.nix` in main branch
- ❌ No `flake.nix` in tags v12.5, v12.4, v11.9
- ❌ Lock file has invalid commit reference
- ✅ Repository exists and is active (updated 2026-02-06T17:42:45Z)
- ✅ The module works when lock references a valid commit (per refactor2 history)

## Possible Solutions

### Option 1: Use an Older Working Commit (Recommended Short-term)
Find a historical commit that had a flake.nix and pin to it:
```nix
yazelix = {
  url = "github:luccahuguet/yazelix/<working-commit-hash>";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

### Option 2: Contact Maintainer (Recommended Long-term)
- Open an issue on yazelix repository
- Ask if flake support was intentionally removed
- Request flake.nix addition or flake compatibility layer

### Option 3: Convert to Devenv Integration
Since yazelix uses devenv, integrate it differently:
- Use yazelix as a devenv template
- Import configs directly rather than as flake
- This requires significant refactoring of yazelix.nix module

### Option 4: Fork and Add Flake  
- Fork yazelix repository
- Add appropriate flake.nix wrapper
- Use fork as input
- Submit PR upstream

## Temporary Workaround

For refactor3 validation, yazelix references are commented out in:
- `flake.nix` (input and outputs)
- `machines/z0r0/default.nix`
- `machines/nami/default.nix`

This allows testing the core refactor structure. Yazelix integration should be restored before merging to main.

## Action Items

- [ ] Find working yazelix commit with flake.nix (check git history)
- [ ] OR contact yazelix maintainer about flake support
- [ ] Update integration once resolution found
- [ ] Test yazelix functionality after fix
- [ ] Document final solution

## Related Files

- `/home/t0psh31f/Clan/Grandlix-Gang/modules-old/nixos/yazelix.nix`
- `/home/t0psh31f/Clan/Grandlix-Gang/flake.nix` (lines 69-73)
- `/home/t0psh31f/Clan/Grandlix-Gang/machines/z0r0/default.nix`
- `/home/t0psh31f/Clan/Grandlix-Gang/machines/nami/default.nix`
