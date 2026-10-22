# Consolidated Theming Module (GTK, Qt, SFX)
{ mkDendriticModule, mkDendriticTree, ... }:
{
  imports = mkDendriticTree mkDendriticModule ./.;
}
