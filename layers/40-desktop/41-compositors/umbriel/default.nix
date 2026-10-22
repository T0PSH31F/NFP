# Umbriel Compositor Module
# Provides: layers.desktop.compositors.umbriel.enable
#
# Umbriel is an independent Wayland compositor with:
#   scrolling, dwindle + master layouts, blur, shadows, fluid animations.
#
# Source: github:noctalia-dev/umbriel
# Cache:  noctalia.cachix.org (already in nixConfig)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.desktop.compositors.umbriel;
  umbrielPkgs = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system} or { };
  umbrielPkg =
    umbrielPkgs.default or (throw "umbriel: no default package for ${pkgs.stdenv.hostPlatform.system}");
in
{
  options.layers.desktop.compositors.umbriel = {
    enable = lib.mkEnableOption "Umbriel Wayland compositor";

    package = lib.mkOption {
      type = lib.types.package;
      default = umbrielPkg;
      description = "Umbriel compositor package";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Umbriel configuration (appended to ~/.config/umbriel/umbriel.conf)";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── System packages ────────────────────────────────────────────────
    environment.systemPackages = [
      cfg.package
      pkgs.xdg-desktop-portal-wlr # XDG portal backend (wlr-compatible)
    ];

    # ── XDG portal ─────────────────────────────────────────────────────
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-umbriel
        pkgs.xdg-desktop-portal-gtk
      ];
      config.umbriel = {
        default = [
          "umbriel"
          "gtk"
        ];
      };
    };

    # ── Session registration ───────────────────────────────────────────
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "umbriel-wayland-session";
          destination = "/share/wayland-sessions/umbriel.desktop";
          passthru.providedSessions = [ "umbriel" ];
          text = ''
            [Desktop Entry]
            Name=Umbriel
            Comment=Umbriel Wayland Compositor
            Exec=umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "umbriel" ];
        }
      )
    ];

    # ── UWSM integration (same pattern as Hyprland) ───────────────────
    programs.uwsm = {
      enable = lib.mkDefault true;
      waylandCompositors.umbriel = {
        prettyName = "Umbriel";
        comment = "Umbriel Wayland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/umbriel";
      };
    };

    # ── Security (polkit, pam) ─────────────────────────────────────────
    security.polkit.enable = true;
    security.pam.services.umbriel.enableGnomeKeyring = lib.mkDefault true;
  };
}
