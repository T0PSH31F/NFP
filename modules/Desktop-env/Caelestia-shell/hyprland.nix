{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.desktop.caelestia;
in {
  config = lib.mkIf (cfg.enable && (cfg.backend == "hyprland" || cfg.backend == "both")) {
    environment.systemPackages = [
      inputs.caelestia-shell.packages.${pkgs.system}.default
    ];

    home-manager.users.t0psh31f = {
      imports = [inputs.caelestia-shell.homeManagerModules.default];
      programs.caelestia.enable = true;
    };
  };
}
