{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop.illogical-impulse;
in {
  options.desktop.illogical-impulse = {
    enable = lib.mkEnableOption "End-4 Illogical Impulse (Hyprland)";
  };

  config = lib.mkIf cfg.enable {
    # It requires Hyprland
    desktop.hyprland.enable = true;

    services.geoclue2.enable = true;
    networking.networkmanager.enable = true;

    home-manager.users.t0psh31f = {
      imports = [inputs.illogical-flake.homeManagerModules.default];
      programs.illogical-impulse.enable = true;
    };
  };
}
