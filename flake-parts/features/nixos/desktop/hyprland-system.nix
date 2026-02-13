# flake-parts/desktop/hyprland.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);
in
{
  config = lib.mkIf (hasTag "desktop") {
    programs.hyprland = {
      enable = true;
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

    # Re-enable portal configuration from portals.nix
    xdg.portal = {
      enable = true;
      extraPortals = [];
      # config.common.default = "*";
    };
  };
}
