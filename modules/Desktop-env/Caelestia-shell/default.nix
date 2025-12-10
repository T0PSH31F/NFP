{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktop.caelestia;
in {
  options.desktop.caelestia = {
    enable = mkEnableOption "Caelestia Dotfiles Environment";
    backend = mkOption {
      type = types.enum ["hyprland" "niri" "both"];
      default = "both";
      description = "Which backend to use for Caelestia";
    };
  };

  imports = [
    ./hyprland.nix
    ./niri.nix
  ];

  config = mkIf cfg.enable {
    desktop.hyprland.enable = mkIf (cfg.backend == "hyprland" || cfg.backend == "both") true;
    desktop.niri.enable = mkIf (cfg.backend == "niri" || cfg.backend == "both") true;
  };
}
