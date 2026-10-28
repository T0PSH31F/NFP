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
      # Includes — Shaders & Effect Presets
      # ==============================================================================
      # Includes all 189+ curated GLSL shader effect presets from:
      # • Community Shaders: https://github.com/noctalia-dev/community-umbriel-shaders
      # • Prometheaus Shaders: https://github.com/prometheaus/umbriel-shaders
      [include]
      files = [
        "shaders/all-shaders.toml"
      ]

      # ==============================================================================
      # Active Shaders — Psychedelic Collection (Community Shaders)
      # ==============================================================================
      [effects]
      border = "psychedelic.fractal-flow"
      window = "psychedelic.fractal-veil"
      cursor = "cursor.comet"
      screen = "vignette"
      max_fps = 120

      # ==============================================================================
      # Appearance & Frosted Glass Blur (macOS Vibrancy & Brilliance)
      # ==============================================================================
      [appearance]
      border_width = 5
      corner_radius = 14
      drag_opacity = 0.85

      [appearance.blur]
      enabled = true
      radius = 8
      passes = 4
      brightness = 1.05
      contrast = 0.98
      saturation = 1.25
      noise = 0.015

      [animation]
      enabled = true

      [animation.workspaces]
      enabled = true
      style = "reveal"
      effect = "psychedelic.fractal-iris"
      duration_ms = 1100
      curve = "linear"

      [animation.windows_in]
      enabled = true
      effect = "psychedelic.fractal-bloom"
      duration_ms = 700
      curve = "linear"

      [animation.windows_out]
      enabled = true
      effect = "psychedelic.fractal-bloom"
      duration_ms = 450
      curve = "linear"

      [animation.windows_move]
      enabled = true
      effect = "wobbly-move"
      curve = "easeout"
      duration_ms = 650

      [animation.windows_drag]
      physics = true

      [animation.dim_unfocused]
      enabled = true
      dim = 0.12
      duration_ms = 250
      curve = "ease-out"

      # ==============================================================================
      # Input
      # ==============================================================================
      [input.keyboard]
      numlock_toggle = true

      [input.focus]
      follows_mouse = true

      [input.cursor]
      size = 24
      hardware_cursor = false

      # ==============================================================================
      # Keybinds
      # ==============================================================================
      [keybinds]
      "Mod+Return" = { action = "spawn:ghostty", repeat = false }
      "Mod" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+Space" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+A" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+X" = "spawn:noctalia msg panel-toggle control-center"
      "Mod+N" = { action = "spawn:noctalia msg panel-toggle noctalia/notes:panel", repeat = false }
      "Mod+Shift+N" = { action = "spawn:noctalia msg panel-toggle noctalia/notes:panel", repeat = false }
      "Mod+Comma" = "spawn:noctalia msg settings-toggle"
      "Mod+Shift+Comma" = { action = "spawn:umbriel-config gui", repeat = false }
      "Mod+Tab" = "spawn:noctalia msg window-switcher"
      "Mod+Q" = { action = "window-close", repeat = false }
      "Mod+Escape" = "session-quit"
      "Mod+Shift+Escape" = { action = "shortcuts-inhibit-toggle", allow_when_inhibited = true, repeat = false }
      "Ctrl+Alt+Delete" = "spawn:noctalia msg panel-toggle session"

      # Window navigation & focus (Hyprland arrows + Vim keys)
      "Mod+Left" = "window-focus-left"
      "Mod+Down" = "window-focus-down"
      "Mod+Up" = "window-focus-up"
      "Mod+Right" = "window-focus-right"
      "Mod+H" = "window-focus-left"
      "Mod+J" = "window-focus-down"
      "Mod+K" = "window-focus-up"
      "Mod+L" = "window-focus-right"
      "Alt+Tab" = "window-focus-next"
      "Alt+Shift+Tab" = "window-focus-previous"

      # Window movement & swapping (Hyprland Shift + arrows / Vim keys)
      "Mod+Shift+Left" = "window-move-left"
      "Mod+Shift+Down" = "window-move-down"
      "Mod+Shift+Up" = "window-move-up"
      "Mod+Shift+Right" = "window-move-right"
      "Mod+Shift+H" = "window-move-left"
      "Mod+Shift+J" = "window-move-down"
      "Mod+Shift+K" = "window-move-up"
      "Mod+Shift+L" = "window-move-right"

      # Window states
      "Mod+V" = { action = "window-toggle-floating", repeat = false }
      "Mod+T" = { action = "scratchpad-toggle:terminal", repeat = false }
      "Mod+F" = { action = "window-toggle-fullscreen", repeat = false }
      "Mod+M" = { action = "window-toggle-maximize-to-edges", repeat = false }
      "Mod+O" = { action = "overview-toggle", repeat = false }
      "Mod+Ctrl+L" = "workspace-set-layout:toggle:scrolling,dwindle,master"

      # Extent resizing & tab groups
      "Mod+equal" = "window-modify-primary-extent:0.05"
      "Mod+minus" = "window-modify-primary-extent:-0.05"
      "Mod+Shift+equal" = "window-cycle-primary-extent"
      "Mod+Shift+minus" = "window-cycle-primary-extent-back"
      "Mod+Ctrl+equal" = "window-modify-secondary-extent:0.05"
      "Mod+Ctrl+minus" = "window-modify-secondary-extent:-0.05"
      "Mod+R" = "window-cycle-primary-extent"
      "Mod+Shift+R" = "window-cycle-primary-extent-back"
      "Mod+W" = "column-toggle-tabbed"

      # Scratchpad / Special Workspace
      "Mod+Shift+S" = "scratchpad-toggle:terminal"
      "Mod+Alt+S" = "window-move-to-scratchpad:terminal"

      # Workspaces 1-9
      "Mod+1" = "workspace-switch:1"
      "Mod+2" = "workspace-switch:2"
      "Mod+3" = "workspace-switch:3"
      "Mod+4" = "workspace-switch:4"
      "Mod+5" = "workspace-switch:5"
      "Mod+6" = "workspace-switch:6"
      "Mod+7" = "workspace-switch:7"
      "Mod+8" = "workspace-switch:8"
      "Mod+9" = "workspace-switch:9"

      # Move window to workspace
      "Mod+Shift+1" = "window-move-to-workspace:1"
      "Mod+Shift+2" = "window-move-to-workspace:2"
      "Mod+Shift+3" = "window-move-to-workspace:3"
      "Mod+Shift+4" = "window-move-to-workspace:4"
      "Mod+Shift+5" = "window-move-to-workspace:5"
      "Mod+Shift+6" = "window-move-to-workspace:6"
      "Mod+Shift+7" = "window-move-to-workspace:7"
      "Mod+Shift+8" = "window-move-to-workspace:8"
      "Mod+Shift+9" = "window-move-to-workspace:9"

      # Move window to workspace (silent)
      "Mod+Alt+1" = "window-move-to-workspace-silent:1"
      "Mod+Alt+2" = "window-move-to-workspace-silent:2"
      "Mod+Alt+3" = "window-move-to-workspace-silent:3"
      "Mod+Alt+4" = "window-move-to-workspace-silent:4"
      "Mod+Alt+5" = "window-move-to-workspace-silent:5"
      "Mod+Alt+6" = "window-move-to-workspace-silent:6"
      "Mod+Alt+7" = "window-move-to-workspace-silent:7"
      "Mod+Alt+8" = "window-move-to-workspace-silent:8"
      "Mod+Alt+9" = "window-move-to-workspace-silent:9"

      # Relative workspace navigation (bracket, page up/down, ctrl+arrows)
      "Mod+BracketRight" = "workspace-next"
      "Mod+BracketLeft" = "workspace-previous"
      "Mod+Ctrl+Right" = "workspace-next"
      "Mod+Ctrl+Left" = "workspace-previous"
      "Mod+Page_Down" = "workspace-next"
      "Mod+Page_Up" = "workspace-previous"

      "Mod+Shift+BracketRight" = "window-move-to-workspace-next"
      "Mod+Shift+BracketLeft" = "window-move-to-workspace-previous"
      "Mod+Shift+Page_Down" = "window-move-to-workspace-next"
      "Mod+Shift+Page_Up" = "window-move-to-workspace-previous"
      "Mod+Ctrl+Shift+Right" = "window-move-to-workspace-next"
      "Mod+Ctrl+Shift+Left" = "window-move-to-workspace-previous"

      # Mouse wheel workspace switching
      "Mod+WheelDown" = "workspace-next"
      "Mod+WheelUp" = "workspace-previous"
      "Mod+Shift+WheelDown" = "window-move-to-workspace-next"
      "Mod+Shift+WheelUp" = "window-move-to-workspace-previous"

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
      # Overview
      # ==============================================================================
      [overview]
      zoom = 0.5
      scroll_factor_horizontal = 1.0
      scroll_factor_vertical = 1.0
      background_blur = true
      workspace_wallpaper = true
      shortcuts = true
      shortcut_keys = "1234567890"

      # ==============================================================================
      # Layout
      # ==============================================================================
      [layout]
      extent_presets = [0.333, 0.5, 0.667, 1.0]

      [layout.scrolling]
      default_extent_fraction = 1.0

      # ==============================================================================
      # Scratchpads (Drop-Down Quake Terminal)
      # ==============================================================================
      [[scratchpad]]
      name = "terminal"
      spawn_when_empty = "ghostty --title='Dropdown Terminal'"

      # ==============================================================================
      # Window Rules
      # ==============================================================================
      [[window_rule]]
      blur = true
      opacity = 0.94
      border_width = 5

      [[window_rule]]
      match.title = "^Dropdown Terminal$"
      default_scratchpad = "terminal"
      default_floating = true
      default_floating_size_px = { width = 1600, height = 550 }
      default_position = { anchor = "top", x = 0, y = 54 }

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

      # ==============================================================================
      # Outputs
      # ==============================================================================
      [output.HDMI-A-2]
      enabled = true
      scale = 1.0
      position = [0, 0]

      [output.eDP-1]
      enabled = true
      scale = 1.0
      position = [1920, 0]

      # ==============================================================================
      # EXTENSIONS & SHADERS REFERENCE (https://github.com/noctalia-dev/community-umbriel-shaders)
      # GUI Configurator: umbriel-config gui (Mod+Shift+,)
      # Portals: xdg-desktop-portal-umbriel (ScreenCast, Screenshot, InputCapture)
      # ==============================================================================

      ${cfg.extraConfig}
    '';

    # ── System packages ────────────────────────────────────────────────
    environment.systemPackages = [
      cfg.package
      (pkgs.writeTextFile {
        name = "umbriel-uwsm-wayland-session";
        destination = "/share/wayland-sessions/umbriel-uwsm.desktop";
        text = ''
          [Desktop Entry]
          Name=Umbriel (UWSM)
          Comment=Umbriel Wayland compositor managed by UWSM
          Exec=${pkgs.uwsm}/bin/uwsm start -F -N "Umbriel" -D Umbriel -C "Umbriel Wayland compositor managed by UWSM" -- /run/current-system/sw/bin/umbriel
          Type=Application
          DesktopNames=Umbriel
        '';
      })
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
          name = "umbriel-uwsm-wayland-session";
          destination = "/share/wayland-sessions/umbriel-uwsm.desktop";
          passthru.providedSessions = [ "umbriel-uwsm" ];
          text = ''
            [Desktop Entry]
            Name=Umbriel (UWSM)
            Comment=Umbriel Wayland compositor managed by UWSM
            Exec=${pkgs.uwsm}/bin/uwsm start -F -N "Umbriel" -D Umbriel -C "Umbriel Wayland compositor managed by UWSM" -- /run/current-system/sw/bin/umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "umbriel-uwsm" ];
        }
      )
      (
        (pkgs.writeTextFile {
          name = "umbriel-wayland-session";
          destination = "/share/wayland-sessions/umbriel.desktop";
          passthru.providedSessions = [ "umbriel" ];
          text = ''
            [Desktop Entry]
            Name=Umbriel
            Comment=Umbriel Wayland Compositor (Native systemd)
            Exec=${cfg.package}/bin/start-umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "umbriel" ];
        }
      )
    ];

    # ── UWSM integration ───────────────────────────────────────────────
    programs.uwsm.enable = lib.mkDefault true;

    # ── System-wide UWSM environment overrides for Umbriel ────────────
    environment.etc."xdg/uwsm/env-umbriel".text = ''
      export XDG_CURRENT_DESKTOP=Umbriel
      export XDG_SESSION_TYPE=wayland
      export XDG_SESSION_DESKTOP=Umbriel
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
    '';

    # ── Systemd service environment overrides (wlroots hybrid GPU fix) ───
    systemd.user.services.umbriel = {
      environment = {
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      };
    };

    # ── Security (polkit, pam) ─────────────────────────────────────────
    security.polkit.enable = true;
    security.pam.services.umbriel.enableGnomeKeyring = lib.mkDefault true;
  };
}
