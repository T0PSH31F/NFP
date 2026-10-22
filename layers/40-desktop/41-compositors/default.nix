# Compositor aggregator — pure mkDendriticTree pass-through so subdirectory
# compositor modules (e.g. umbriel/) are auto-imported. Without this file,
# mkDendriticTree skips 41-compositors entirely (directory needs default.nix).
{ mkDendriticModule, mkDendriticTree, ... }:
{
  imports = mkDendriticTree mkDendriticModule ./.;
}
