{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-40.desktop.frameworks.portals;
in
{
  config = mkIf cfg.enable {
    ############################################################
    # Core desktop plumbing
    ############################################################
    programs.dconf.enable = true;
    security.polkit.enable = true;

    # Session-wide environment variables for portal/Wayland integration
    environment.sessionVariables = {
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";
    };

    ############################################################
    # PAM: authentication + login-time keyring unlock
    ############################################################
    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    ############################################################
    # XDG Desktop Portal configuration
    ############################################################
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      wlr.enable = false; # Disable wlr portal (conflicts with hyprland)

      # Don't add xdg-desktop-portal-hyprland here - programs.hyprland adds it automatically
      extraPortals =
        with pkgs;
        [
          xdg-desktop-portal-gtk
        ]
        ++ cfg.extraPortals;

      # Mapping: choosing which backend handles which portal API.
      # GTK = boring reliable fallback for file chooser/OpenURI/Print.
      # Compositor-specific backend only for features needing compositor integration.
      config = {
        common = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        };

        # Matches XDG_CURRENT_DESKTOP=Hyprland
        hyprland = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
          "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
        };

        # Matches XDG_CURRENT_DESKTOP=niri
        niri = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
        };
      };
    };

    ############################################################
    # Packages
    ############################################################
    environment.systemPackages = with pkgs; [
      polkit_gnome
      xdg-utils
      desktop-file-utils
      shared-mime-info
      seahorse
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
