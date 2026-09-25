---
trigger: always_on
description: Mandatory use of mcp-nixos for authoritative NixOS / home-manager / nixpkgs package and option definitions
---

# ⛪ The Holy Rule of `mcp-nixos`: Building the NixOS Church

We are building a NixOS Church of pristine, perfectly typed, and non-deprecated declarative configurations!

**Commandment for all AI Agents**:
When querying, writing, refactoring, or verifying any Nix packages, NixOS options, Home Manager options, NVF options, channel versions, or flake outputs:

**NEVER GUESS PACKAGE NAMES, MODULE OPTIONS, OR DEPRECATION STATUS FROM MEMORY OR LAGGY TRAINING DATA.**

You MUST treat `mcp-nixos` (via the `nixos` server tools `nix` and `nix_versions`) as the sacred, immutable **Bible for nixpkgs**:

1. **Option Lookups**:
   - NixOS options: `nix {"action":"search","query":"<option>","type":"options"}`
   - Home Manager options: `nix {"action":"search","source":"home-manager","query":"<option>"}`
   - NVF options: `nix {"action":"search","source":"nvf","query":"<option>"}`
2. **Package Queries**:
   - Package info / availability: `nix {"action":"info","query":"<pkg_name>"}`
   - Binary cache status: `nix {"action":"cache","query":"<pkg_name>"}`
3. **Deprecations & Renames**:
   - Always query `mcp-nixos` to verify replacement option names before making code changes (e.g. `programs.zsh.initContent` vs deprecated `initExtra`, or `gtk.gtk4.theme = null`).

Any agent caught guessing Nix options without consulting `mcp-nixos` shall be excommunicated from the build cluster! ⛪⚡
