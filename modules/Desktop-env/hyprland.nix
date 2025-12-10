{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktop.hyprland;
in {
  options.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Desktop Environment";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      # Package is usually from nixpkgs, but can be overridden if needed
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    # UWSM Configuration for Session Management
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

    # Essential Hyprland dependencies that might not be in the minimal package
    environment.systemPackages = with pkgs; [
      xdg-desktop-portal-hyprland
      waybar
      rofi
      dunst
      libnotify
      swww # Wallpaper
      kitty # Terminal (default)
    ];

    # Enable XDG Desktop Portal
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };
  };
}
