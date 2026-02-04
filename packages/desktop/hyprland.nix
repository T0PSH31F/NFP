{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  config = lib.mkIf (config.clan.lib.hasTag "desktop") {
    programs.hyprland = {
      enable = true;
      # Use hyprland from flake for consistent ABI with plugins
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      withUWSM = true;
      xwayland.enable = true;
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };
}
