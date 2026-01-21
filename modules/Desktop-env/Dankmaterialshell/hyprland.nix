{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # DankMaterialShell Hyprland-specific config
  # Source: https://github.com/AvengeMedia/DankMaterialShell

  config = lib.mkIf (config.desktop.dankmaterialshell.enable && (config.desktop.dankmaterialshell.backend == "hyprland" || config.desktop.dankmaterialshell.backend == "both")) {
    # Hyprland-specific DankMaterialShell settings go here
    # Currently no hyprland-specific settings needed
  };
}
