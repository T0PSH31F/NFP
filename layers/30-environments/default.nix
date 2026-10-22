# Theming Tier Entry Point — Auto-imported via mkDendriticTree
{ mkDendriticModule, mkDendriticTree, ... }:
{
  imports = mkDendriticTree mkDendriticModule ./.;
}
