{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktop.omarchy;
in {
  options.desktop.omarchy = {
    enable = mkEnableOption "Omarchy Desktop Environment";
    backend = mkOption {
      type = types.enum ["hyprland" "niri" "both"];
      default = "both";
      description = "Which backend to use for Omarchy";
    };
  };

  imports = [
    ./hyprland.nix
    ./niri.nix
  ];

  config = mkIf cfg.enable {
    # If using Hyprland
    desktop.hyprland.enable = mkIf (cfg.backend == "hyprland" || cfg.backend == "both") true;

    # If using Niri
    desktop.niri.enable = mkIf (cfg.backend == "niri" || cfg.backend == "both") true;
  };
}
