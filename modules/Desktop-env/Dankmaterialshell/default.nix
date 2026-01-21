{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.dankmaterialshell;
in
{
  options.desktop.dankmaterialshell = {
    enable = mkEnableOption "Dankmaterialshell (Awesome-style config)";
    backend = mkOption {
      type = types.enum [
        "hyprland"
        "niri"
        "both"
      ];
      default = "both";
      description = "Which backend to use for Dankmaterialshell";
    };
  };

  imports = [
    inputs.dms.nixosModules.dank-material-shell
    ./hyprland.nix
    ./niri.nix
  ];

  config = mkIf cfg.enable {
    users.users.t0psh31f = {
      group = "t0psh31f";
      isNormalUser = true;
    };
    users.groups.t0psh31f = { };
    # Enable DankMaterialShell NixOS module
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      # Core features
      enableSystemMonitoring = false;
      #  enableClipboard = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
    };

    # Common home-manager config (import default module once)
    home-manager.users.t0psh31f = {
      imports = [
        inputs.dms.homeModules.dank-material-shell
        inputs.dms-plugin-registry.modules.default
        ./dms-settings.nix
      ];

      programs.dank-material-shell = {
        enable = true;
        systemd = {
          enable = true;
        };
        enableSystemMonitoring = true;
        dgop.package = inputs.dgop.packages.${pkgs.system}.default;
      };
    };

    # If using Hyprland
    desktop.hyprland.enable = mkIf (cfg.backend == "hyprland" || cfg.backend == "both") true;

    # If using Niri
    desktop.niri.enable = mkIf (cfg.backend == "niri" || cfg.backend == "both") true;
  };
}
