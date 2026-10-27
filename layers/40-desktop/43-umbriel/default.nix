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
    # ── Environment configuration ──────────────────────────────────────
    environment.etc."xdg/umbriel/config.toml".text = ''
      # ==============================================================================
      # General
      # ==============================================================================
      [general]
      autostart = ["noctalia"]
      xwayland = true

      # ==============================================================================
      # Input
      # ==============================================================================
      [input.keyboard]
      numlock_toggle = true

      [input.focus]
      follows_mouse = true

      # ==============================================================================
      # Keybinds
      # ==============================================================================
      [keybinds]
      "Mod+Return" = { action = "spawn:ghostty", repeat = false }
      "Mod" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+Space" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+A" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+X" = "spawn:noctalia msg panel-toggle control-center"
      "Mod+Comma" = "spawn:noctalia msg settings-toggle"
      "Mod+Tab" = "spawn:noctalia msg window-switcher"
      "Mod+Q" = { action = "window-close", repeat = false }
      "Mod+Escape" = "session-quit"
      "Mod+Shift+Escape" = { action = "shortcuts-inhibit-toggle", allow_when_inhibited = true, repeat = false }
      "Ctrl+Alt+Delete" = "spawn:noctalia msg panel-toggle session"

      # Window navigation & management
      "Mod+Left" = "window-focus-left"
      "Mod+Down" = "window-focus-down"
      "Mod+Up" = "window-focus-up"
      "Mod+Right" = "window-focus-right"
      "Mod+Shift+Left" = "column-move-left"
      "Mod+Shift+Down" = "window-move-down"
      "Mod+Shift+Up" = "window-move-up"
      "Mod+Shift+Right" = "column-move-right"

      "Mod+T" = { action = "window-toggle-floating", repeat = false }
      "Mod+F" = { action = "window-toggle-fullscreen", repeat = false }
      "Mod+M" = { action = "window-toggle-maximize-to-edges", repeat = false }
      "Mod+O" = { action = "overview-toggle", repeat = false }

      # ── 7 Functional Domain Workspaces ──
      # 1: Agents, 2: Browser, 3: IDE, 4: Media/Games, 5: File-Manager, 6: E-mail, 7: Overviews
      "Mod+1" = "workspace-switch:1"
      "Mod+2" = "workspace-switch:2"
      "Mod+3" = "workspace-switch:3"
      "Mod+4" = "workspace-switch:4"
      "Mod+5" = "workspace-switch:5"
      "Mod+6" = "workspace-switch:6"
      "Mod+7" = "workspace-switch:7"

      "Mod+Shift+1" = "window-move-to-workspace:1"
      "Mod+Shift+2" = "window-move-to-workspace:2"
      "Mod+Shift+3" = "window-move-to-workspace:3"
      "Mod+Shift+4" = "window-move-to-workspace:4"
      "Mod+Shift+5" = "window-move-to-workspace:5"
      "Mod+Shift+6" = "window-move-to-workspace:6"
      "Mod+Shift+7" = "window-move-to-workspace:7"

      # Media & hardware keys
      "XF86AudioRaiseVolume" = { action = "spawn:noctalia msg volume-up", allow_when_locked = true }
      "XF86AudioLowerVolume" = { action = "spawn:noctalia msg volume-down", allow_when_locked = true }
      "XF86AudioMute" = { action = "spawn:noctalia msg volume-mute", allow_when_locked = true, repeat = false }
      "XF86AudioPlay" = { action = "spawn:noctalia msg media toggle", allow_when_locked = true, repeat = false }
      "XF86AudioNext" = { action = "spawn:noctalia msg media next", allow_when_locked = true }
      "XF86AudioPrev" = { action = "spawn:noctalia msg media previous", allow_when_locked = true }
      "XF86MonBrightnessUp" = { action = "spawn:noctalia msg brightness-up", allow_when_locked = true }
      "XF86MonBrightnessDown" = { action = "spawn:noctalia msg brightness-down", allow_when_locked = true }

      # ==============================================================================
      # Layout
      # ==============================================================================
      [layout]
      extent_presets = [0.333, 0.5, 0.667]

      [layout.scrolling]
      default_extent_fraction = 0.5

      # ==============================================================================
      # Window Rules
      # ==============================================================================
      [[window_rule]]
      blur = true

      [[window_rule]]
      match.app_id = "^dev.noctalia.Noctalia$"
      default_floating = true
      default_floating_size_px = { width = 1020, height = 900 }

      [[window_rule]]
      match.app_id = "^(opencode|oh-my-opencode|hermes|agy)$"
      default_workspace = "1"

      [[window_rule]]
      match.app_id = "^(zen.*|brave-browser|firefox|chromium|google-chrome)$"
      default_workspace = "2"

      [[window_rule]]
      match.app_id = "^(code|cursor|dev\\.zed\\.Zed|neovim)$"
      default_workspace = "3"

      [[window_rule]]
      match.app_id = "^(spotify|steam|mpv)$"
      default_workspace = "4"

      [[window_rule]]
      match.app_id = "^(thunar|org\\.gnome\\.Nautilus|dolphin|yazi)$"
      default_workspace = "5"

      [[window_rule]]
      match.app_id = "^(thunderbird|discord|vesktop|slack|signal)$"
      default_workspace = "6"

      [[window_rule]]
      match.app_id = "^(btop|bottom|tmog|grafana)$"
      default_workspace = "7"

      # ==============================================================================
      # Layer Rules
      # ==============================================================================
      [[layer_rule]]
      match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$"
      blur = true
      blur_ignore_alpha = 0.5
      blur_popups = true

      [[layer_rule]]
      match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$"
      blur_optimized = false

      ${cfg.extraConfig}
    '';

    # ── System packages ────────────────────────────────────────────────
    environment.systemPackages = [
      cfg.package
    ];

    # ── XDG portal ─────────────────────────────────────────────────────
    xdg.portal = {
      enable = true;
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
