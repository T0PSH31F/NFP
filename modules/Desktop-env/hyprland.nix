{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.hyprland;
in
{
  options.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Desktop Environment";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      # Use hyprland from flake for consistent ABI with plugins (mkForce to override Omarchy)
      package = lib.mkForce inputs.hyprland.packages.${pkgs.system}.hyprland;
      withUWSM = true;
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

    systemd.user.services.vicinae = {
      description = "Vicinae Launcher";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${inputs.vicinae.packages.${pkgs.system}.default}/bin/vicinae --server";
        Restart = "on-failure";
        RestartSec = 5;
        Type = "simple";
        # Prevent uwsm-app.lock conflicts
        Environment = "UWSM_NO_LOCK=1";
      };
    };

    # Define Sonic cursor package
    nixpkgs.overlays = [
      (final: prev: {
        sonic-cursor = prev.callPackage ../../pkgs/sonic-cursor.nix { };
      })
    ];

    home-manager.users.t0psh31f = {
      home.stateVersion = "25.05";
      # Essential Hyprland dependencies that might not be in the minimal package
      home.packages = with pkgs; [
        # xdg-desktop-portal-hyprland is added via xdg.portal.extraPortals below
        # waybar
        hyprlandPlugins.borders-plus-plus
        hyprlandPlugins.hypr-dynamic-cursors
        cosmic-files
        # hyprlax
        grimblast
        # quickshell - provided by desktop environment modules
        vicinae
        rofi
        dunst
        swayimg
        swaynotificationcenter
        libnotify
        wl-clipboard # Wayland clipboard utilities
        cliphist # Clipboard history manager
        swww # Wallpaper
        hueadm
        hue-plus
        openhue-cli # Philips Hue control
        kitty # Terminal (default)
        ghostty # Terminal (default)
        warp-terminal # Terminal (default)
        nemo-with-extensions
        # xplorer
        xpipe
        steam-rom-manager
        sonic-cursor # Sonic hyprcursor theme
      ];
      xdg.portal = {
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      };

      wayland.windowManager.hyprland = {
        enable = true;
        # Use flake's Hyprland for consistent ABI with plugins
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
        # Disable systemd integration since UWSM handles it
        systemd.enable = false;
        plugins = [
          # Version-matched plugins from flake inputs
          inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
          inputs.hyprland-plugins.packages.${pkgs.system}.borders-plus-plus
        ];

        settings = {

          # Source matugen-generated colors for dynamic theming
          source = "~/.config/hypr/colors.conf";

          "$mod" = "SUPER";
          "$terminal" = "ghostty";
          "$fileManager" = "thunar";
          "$browser" = "vivaldi-stable";

          # ============================================================================
          # PLUGIN CONFIGURATION
          # ============================================================================
          plugin = {
            "borders-plus-plus" = {
              add_borders = 2; # Two extra borders for the halo effect

              # Inner ring: dynamic primary color from matugen
              border_size_1 = 4;
              "border_color_1" = "$halo_inner";

              # Outer ring: dynamic tertiary color from matugen
              border_size_2 = 10;
              "border_color_2" = "$halo_outer";
              natural_rounding = true;
            };

            "dynamic-cursors" = {
              enabled = true;
              mode = "rotate"; # mode: rotate, stretch, tilt
              threshold = 2; # threshold: The minimum speed (in pixels per frame?) required to trigger the effect. lower = more sensitive

              stretch = {
                # (only applies if mode = stretch)
                limit = 3000;
                function = "quadratic"; # function: linear: Linear stretching based on speed, quadratic: Quadratic stretching (starts slow, gets fast), negative_quadratic: Inverse quadratic.
              };

              shake = {
                enabled = false;
                effects = false;
                ipc = true;
              };
            };
          };

          # Custom keybinds
          bind = lib.mkAfter [
            "SUPER, Q, killactive," # Close/kill active window
            "SUPER, C, exec, uwsm app -- code" # Open VSCode
            "SUPER, T, exec, uwsm app -- ghostty" # Terminal
            "SUPER, Return, exec, uwsm app -- ghostty" # Terminal (alternate)
            "SUPER SHIFT, T, exec, uwsm app -- kitty" # Kitty terminal
            "SUPER SHIFT, Return, exec, uwsm app -- warp-terminal" # Warp terminal
            "SUPER, E, exec, uwsm app -- dolphin" # File Manager
            "SUPER SHIFT, E, exec, uwsm app -- thunar" # File Manager (alternate)
            "SUPER SHIFT, Y, exec, ghostty -e yazi" # TUI File Manager
            "SUPER, M, exec, uwsm app -- spotify" # Music
            "SUPER, S, exec, grimblast --notify copysave area" # Screenshot area to clipboard + file
            "SUPER SHIFT, S, exec, grimblast --notify copysave screen" # Screenshot full screen
            ", Print, exec, grimblast --notify copysave area" # Print Screen key - area
            "SHIFT, Print, exec, grimblast --notify copysave screen" # Shift+Print - full screen
            "CTRL, Print, exec, grimblast --notify copysave active" # Ctrl+Print - active window
            "SUPER, F, exec, uwsm app -- vivaldi" # Browser (Firefox)
            # Wallpaper
            "SUPER, W, exec, wallpaper-manager random" # Random wallpaper
            "SUPER SHIFT, W, exec, wallpaper-manager select" # Select wallpaper
            # Vicinae app launcher
            "SUPER, A, exec, vicinae toggle" # Vicinae launcher

            # DMS Application Launchers
            "SUPER, Space, exec, dms ipc call hypr toggleOverview" # DMS Overview
            "SUPER ALT, Space, exec, dms ipc call spotlight toggle" # DMS Spotlight
            "SUPER, V, exec, dms ipc call clipboard toggle" # DMS Clipboard
            "SUPER, P, exec, dms ipc call processlist focusOrToggle" # DMS Process list
            "SUPER, comma, exec, dms ipc call settings focusOrToggle" # DMS Settings
            "SUPER, N, exec, dms ipc call notifications toggle" # DMS Notifications
            "SUPER, Y, exec, dms ipc call dankdash wallpaper" # DMS Wallpaper

            # DMS Security
            "SUPER ALT, L, exec, dms ipc call lock lock" # DMS Lock screen

            # Swap windows
            "SUPERSHIFT, left, movewindow, l"
            "SUPERSHIFT, right, movewindow, r"
            "SUPERSHIFT, up, movewindow, u"
            "SUPERSHIFT, down, movewindow, d"
            # Move focus
            "SUPER, left, movefocus, l"
            "SUPER, right, movefocus, r"
            "SUPER, up, movefocus, u"
            "SUPER, down, movefocus, d"
            "SUPER, BracketLeft, movefocus, l"
            "SUPER, BracketRight, movefocus, r"

            # Workspace, window, tab switch with keyboard
            "CONTROLSUPER, right, workspace, +1"
            "CONTROLSUPER, left, workspace, -1"
            "CONTROLSUPER, BracketLeft, workspace, -1"
            "CONTROLSUPER, BracketRight, workspace, +1"
            "CONTROLSUPER, up, workspace, -5"
            "CONTROLSUPER, down, workspace, +5"
            "SUPER, Page_Down, workspace, +1"
            "SUPER, Page_Up, workspace, -1"
            "CONTROLSUPER, Page_Down, workspace, +1"
            "CONTROLSUPER, Page_Up, workspace, -1"
            "SUPERSHIFT, Page_Down, movetoworkspace, +1"
            "SUPERSHIFT, Page_Up, movetoworkspace, -1"
            "CONTROLSUPERSHIFT, Right, movetoworkspace, +1"
            "CONTROLSUPERSHIFT, Left, movetoworkspace, -1"
            "SUPERSHIFT, mouse_down, movetoworkspace, -1"
            "SUPERSHIFT, mouse_up, movetoworkspace, +1"

            # Fullscreen
            "SUPER, B, fullscreen, 0"
            "SUPER SHIFT, B, fullscreen, 1"

            # Switching
            "SUPER, 1, workspace, 1"
            "SUPER, 2, workspace, 2"
            "SUPER, 3, workspace, 3"
            "SUPER, 4, workspace, 4"
            "SUPER, 5, workspace, 5"
            "SUPER, 6, workspace, 6"
            "SUPER, 7, workspace, 7"
            "SUPER, 8, workspace, 8"
            "SUPER, 9, workspace, 9"
            "SUPER, 0, workspace, 10"
            "SUPER SHIFT, S, togglespecialworkspace,"
            "ALT, Tab, cyclenext"
            "ALT, Tab, bringactivetotop," # bring it to the top

            # Move window to workspace Super + Alt + [0-9]
            "SUPER ALT, 1, movetoworkspacesilent, 1"
            "SUPER ALT, 2, movetoworkspacesilent, 2"
            "SUPER ALT, 3, movetoworkspacesilent, 3"
            "SUPER ALT, 4, movetoworkspacesilent, 4"
            "SUPER ALT, 5, movetoworkspacesilent, 5"
            "SUPER ALT, 6, movetoworkspacesilent, 6"
            "SUPER ALT, 7, movetoworkspacesilent, 7"
            "SUPER ALT, 8, movetoworkspacesilent, 8"
            "SUPER ALT, 9, movetoworkspacesilent, 9"
            "SUPER ALT, 0, movetoworkspacesilent, 10"
            "CONTROLSHIFTSUPER, Up, movetoworkspacesilent, special"
            "SUPERALT, S, movetoworkspacesilent, special"

            # Scroll through existing workspaces with (Control) + Super + scroll
            "SUPER, mouse_up, workspace, +1"
            "SUPER, mouse_down, workspace, -1"
            "CONTROLSUPER, mouse_up, workspace, +1"
            "CONTROLSUPER, mouse_down, workspace, -1"
            "CONTROLSUPER, Backslash, resizeactive, exact 640 480"
            # Workspace move binds (9-0)
            "SUPER SHIFT, 1, movetoworkspace, 1"
            "SUPER SHIFT, 2, movetoworkspace, 2"
            "SUPER SHIFT, 3, movetoworkspace, 3"
            "SUPER SHIFT, 4, movetoworkspace, 4"
            "SUPER SHIFT, 5, movetoworkspace, 5"
            "SUPER SHIFT, 6, movetoworkspace, 6"
            "SUPER SHIFT, 7, movetoworkspace, 7"
            "SUPER SHIFT, 8, movetoworkspace, 8"
            "SUPER SHIFT, 9, movetoworkspace, 9"
            "SUPER SHIFT, 0, movetoworkspace, 10"

            # Workspace scroll binds
            "SUPER CTRL, left, workspace, e-1"
            "SUPER CTRL, right, workspace, e+1"
            "SUPER CTRL SHIFT, left, movetoworkspace, r-1"
            "SUPER CTRL SHIFT, right, movetoworkspace, r+1"
          ];

          binde = [
            "SUPER, Minus, splitratio, -0.1"
            "SUPER, Equal, splitratio, 0.1"
            "SUPER, Semicolon, splitratio, -0.1"
            "SUPER, Apostrophe, splitratio, 0.1"
          ];

          bindm = [
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
            "SUPER, mouse:274, movewindow"
            # "SUPER, Z, movewindow"
            # "SUPER, mouse_up, resizeactive, relative 0 -20"
            # "SUPER, mouse_down, resizeactive, relative 0 20"
            # "SUPER, mouse_left, resizeactive, relative -20 0"
            # "SUPER, mouse_right, resizeactive, relative 20 0"
          ];

          bindel = [
            # Audio Controls
            ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
            ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
            # Brightness Controls
            ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
            ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
          ];

          # Lid switch binds for clamshell mode and audio mute
          bindl = [
            ", XF86AudioMute, exec, dms ipc call audio mute"
            ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
            ", switch:off:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, 2560x1600@60, 0x0, 1.6\""
          ];

          exec-once = [
            "wl-paste --watch cliphist store & disown" # Clipboard history daemon
          ];

          env = [
            "XCURSOR_SIZE,36"
            "HYPRCURSOR_SIZE,36"
            "HYPRCURSOR_THEME,Sonic-cursor-hyprcursor"
            "QT_QPA_PLATFORM,wayland"
            "ELECTRON_OZONE_PLATFORM_HINT,auto"
            "QT_QPA_PLATFORMTHEME,qt6ct"
            "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
          ];

          general = {
            # Thin core; halos come from plugin
            border_size = 3;

            # Dynamic gradient from matugen palette (primary → tertiary)
            "col.active_border" = "$border_active_1 $border_active_2 45deg";
            "col.inactive_border" = "$border_inactive";

            resize_on_border = true;

            layout = "dwindle";
          };

          decoration = {
            rounding = 10;

            # Blur for frosty glass
            blur = {
              enabled = true;
              size = 8;
              passes = 3;
            };

            # Neon shadow glow (dynamic from matugen)
            shadow = {
              enabled = true;
              range = 40; # how far the glow extends
              render_power = 2; # softness; lower = softer
              color = "$shadow_active"; # dynamic glow color
              color_inactive = "$shadow_inactive";
            };
          };

          misc = {
            # focus_follows_mouse = true;
            animate_manual_resizes = true;
            animate_mouse_windowdragging = true;
            enable_swallow = true;
            focus_on_activate = true;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          bezier = [
            # Standard linear curve
            "liner, 1, 1, 1, 1"

            # Window animation curves
            "wind, 0.05, 0.85, 0.03, 0.97"
            "winIn, 0.07, 0.88, 0.04, 0.99"
            "winOut, 0.20, -0.15, 0, 1"

            # Material Design 3 easing curves
            "md3_standard, 0.12, 0, 0, 1"
            "md3_decel, 0.05, 0.80, 0.10, 0.97"
            "md3_accel, 0.20, 0, 0.80, 0.08"

            # Material Design 2 curve
            "md2, 0.30, 0, 0.15, 1"

            # Menu animation curves
            "menu_decel, 0.05, 0.82, 0, 1"
            "menu_accel, 0.20, 0, 0.82, 0.10"

            # Circular easing curves
            "easeInOutCirc, 0.75, 0, 0.15, 1"
            "easeOutCirc, 0, 0.48, 0.38, 1"
            "easeInOutCircAlt, 0.78, 0, 0.15, 1" # Alternative circular easing

            # Exponential easing
            "easeOutExpo, 0.10, 0.94, 0.23, 0.98"

            # Soft acceleration/deceleration
            "softAcDecel, 0.20, 0.20, 0.15, 1"

            # Back easing (overshoots)
            "OutBack, 0.28, 1.40, 0.58, 1"
            "overshot, 0.05, 0.85, 0.07, 1.04"

            # Extreme curves for special effects
            "crazyshot, 0.1, 1.22, 0.68, 0.98"
            "hyprnostretch, 0.05, 0.82, 0.03, 0.94"
          ];

          animation = [
            # Border animations
            "border, 1, 8, liner"
            "borderangle, 1, 82, liner, loop"

            # Window animations
            "windowsIn, 1, 3.2, winIn, slide"
            "windowsOut, 1, 2.8, easeOutCirc"
            "windowsMove, 1, 3.0, wind, slide"

            # Fade animations
            "fade, 1, 1.8, md3_decel"

            # Layer animations
            "layersIn, 1, 1.8, menu_decel, slide"
            "layersOut, 1, 1.5, menu_accel"
            "fadeLayersIn, 1, 1.6, menu_decel"
            "fadeLayersOut, 1, 1.8, menu_accel"

            # Workspace animations
            "workspaces, 1, 4.0, menu_decel, slide"
            "specialWorkspace, 1, 2.3, md3_decel, slidefadevert 15%"
          ];

          layerrule = [ ];

          # Workspace monitor assignments
          workspace = [
            "1, monitor:DP-2"
            "2, monitor:DP-2"
            "3, monitor:DP-2"
            "4, monitor:DP-2"
            "5, monitor:HDMI-A-1"
            "6, monitor:HDMI-A-1"
            "7, monitor:HDMI-A-1"
            "8, monitor:eDP-1"
            "9, monitor:eDP-1"
            "10, monitor:eDP-1"
          ];
        };
      };

      # Ensure XDG directories are set properly for "Open with..." menus
      xdg.enable = true;
    };
  };
}
