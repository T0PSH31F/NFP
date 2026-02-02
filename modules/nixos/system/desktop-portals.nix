{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.desktop-portals;
in
{
  options.desktop-portals = {
    enable = mkEnableOption "Desktop portals for Wayland compositors";

    extraPortals = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional XDG desktop portals to enable";
    };
  };

  config = mkIf cfg.enable {
    # Enable polkit for authentication dialogs
    security.polkit = {
      enable = true;
      # package = pkgs.hyprpolkitagent;
    };

    # XDG Desktop Portal configuration
    xdg.portal = {
      enable = true;
      wlr.enable = false; # Disable wlr portal (conflicts with hyprland)

      # Don't add xdg-desktop-portal-hyprland here - programs.hyprland adds it automatically
      extraPortals =
        with pkgs;
        [
          xdg-desktop-portal-gtk
        ]
        ++ cfg.extraPortals;

      config = {
        common = {
          default = [ "gtk" ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
        niri = {
          default = [
            "gnome"
            "gtk"
          ];
        };
      };
    };

    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      polkit_gnome
      xdg-utils
    ];

    # Start polkit authentication agent
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
