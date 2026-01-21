{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.niri;
in
{
  options.desktop.niri = {
    enable = mkEnableOption "Niri Desktop Environment";
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      # package = pkgs.niri; # Default from nixpkgs
    };

    nix.settings = {
      extra-substituters = [ "https://niri.cachix.org" ];
      extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
    };

    # UWSM Configuration for Session Management
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        niri = {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      xdg-desktop-portal-gnome # Niri often uses GNOME or GTK portal
      fuzzel # Launcher
      mako # Notifications
      swaybg # Wallpaper
      waybar # Status bar
      kitty # Terminal
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
