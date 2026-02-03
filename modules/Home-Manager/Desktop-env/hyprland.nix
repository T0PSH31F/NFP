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
      # Let programs.hyprland add xdg-desktop-portal-hyprland automatically
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

    home-manager.users.t0psh31f = {
      home.stateVersion = "25.05";
      # Essential Hyprland dependencies that might not be in the minimal package
      home.packages = with pkgs; [
        # xdg-desktop-portal-hyprland is handled by desktop-portals.nix system-wide
        # waybar
        # hyprlandPlugins.borders-plus-plus (Disabled due to rendering issues)
        hyprlandPlugins.hypr-dynamic-cursors
        # hyprlax
        # quickshell - provided by desktop environment modules
        rofi
        dunst
        swayimg
        swaynotificationcenter
        libnotify
        wl-clipboard # Wayland clipboard utilities
        grim # Screenshot tool
        slurp # Screen selection tool
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
        hyprpolkitagent # Hyprland polkit authentication agent
        xdg-utils # xdg-open and related utilities
        xdg-user-dirs # Manage XDG user directories
      ];
      # Don't configure xdg.portal here - it's handled by desktop-portals.nix to avoid duplicate services
      # xdg.portal = {
      #   extraPortals = with pkgs; [
      #     xdg-desktop-portal-gtk
      #   ];
      # };

      wayland.windowManager.hyprland = {
        enable = true;
        # Use flake's Hyprland for consistent ABI with plugins
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        # Don't set portalPackage here - it's handled by desktop-portals.nix to avoid conflicts
        # portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
        # Disable systemd integration since UWSM handles it
        systemd.enable = false;
        plugins = [
          # Version-matched plugins from flake inputs
          inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
          #  inputs.hyprland-plugins.packages.${pkgs.system}.borders-plus-plus
        ];

        settings = {
          # Source matugen-generated colors for dynamic theming
          source = "~/.config/hypr/colors.conf";

          "$mod" = "SUPER";
          "$terminal" = "ghostty";
          "$fileManager" = "nemo-with-extensions";
          "$browser" = "brave";

          # ============================================================================
          # PLUGIN CONFIGURATION
          # ============================================================================
          plugin = {
            # "borders-plus-plus" = {
            #   add_borders = 2; # Two extra borders for the halo effect
            #
            #   # Inner ring: dynamic primary color from matugen (hardcoded for debug)
            #   border_size_1 = 4;
            #   "border_color_1" = "rgb(d0bcff)"; # Solid color for testing
            #
            #   # Outer ring: dynamic tertiary color from matugen (hardcoded for debug)
            #   border_size_2 = 10;
            #   "border_color_2" = "rgb(efb8c8)"; # Solid color for testing
            #   natural_rounding = true;
            # };

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
            # Vicinae App Launcher (Spotlight-style)
            "SUPER, A, exec, vicinae" # App launcher
            "SUPER, Space, exec, vicinae" # Alternative app launcher keybind

            # Overview / App Launcher (Super + Space via Vicinae or direct)
            "SUPER, D, exec, noctalia-shell ipc overview" # Overview mode

            # Control Center (Quick Settings)
            "SUPER, X, exec, noctalia-shell ipc control-center" # Toggle Control Center

            # Lock Screen
            "SUPER, L, exec, noctalia-shell ipc lock" # Lock screen

            # Logout / Session Menu
            "SUPER SHIFT, E, exec, noctalia-shell ipc session-menu" # Session actions

            # Notifications
            "SUPER SHIFT, N, exec, noctalia-shell ipc notification-center" # Notification history

            # Brightness / Audio (IPC via noctalia-shell, overrides your dms if preferred)
            ", XF86MonBrightnessUp, exec, noctalia-shell ipc brightness +5"
            ", XF86MonBrightnessDown, exec, noctalia-shell ipc brightness -5"
            ", XF86AudioRaiseVolume, exec, noctalia-shell ipc volume +5"
            ", XF86AudioLowerVolume, exec, noctalia-shell ipc volume -5"
            ", XF86AudioMute, exec, noctalia-shell ipc volume mute"

            # Media Controls (if Noctalia handles MPRIS)
            ", XF86AudioPlay, exec, noctalia-shell ipc media play-pause"
            ", XF86AudioNext, exec, noctalia-shell ipc media next"
            ", XF86AudioPrev, exec, noctalia-shell ipc media previous"

            # Screenshot (integrate with Noctalia OSD)
            ", Print, exec, noctalia-shell ipc screenshot"

            # Workspace / Overview integration
            "SUPER SHIFT, Tab, exec, noctalia-shell ipc overview" # Alt-Tab like overview

            "SUPER, Q, killactive," # Close/kill active window
            "SUPER, C, exec, uwsm app -- code" # Open VSCode
            "SUPER, T, exec, uwsm app -- ghostty" # Terminal
            "SUPER, Return, exec, uwsm app -- ghostty" # Terminal (alternate)
            "SUPER SHIFT, T, exec, uwsm app -- kitty" # Kitty terminal
            "SUPER SHIFT, Return, exec, uwsm app -- warp-terminal" # Warp terminal
            "SUPER, E, exec, uwsm app -- thunar" # File Manager
            "SUPER CTRL, E, exec, uwsm app -- ghostty -e sf"
            "SUPER SHIFT, E, exec, uwsm app -- kdePackages.dolphin" # File Manager (alternate)
            "SUPER SHIFT, Y, exec, ghostty -e yazi" # TUI File Manager
            "SUPER, M, exec, uwsm app -- spotify" # Music

            # Screenshots (Flameshot)
            "SHIFT, Print, exec, flameshot full --path ~/Pictures/screenshots" # Full screen
            "CTRL, Print, exec, flameshot gui --path ~/Pictures/screenshots" # Interactive GUI (Area/Active)
            ", Print, exec, flameshot gui --path ~/Pictures/screenshots"

            # Browsers (Per-DE keybinds)
            "SUPER, W, exec, uwsm app -- brave" # Brave (default)
            "SUPER CTRL, W, exec, uwsm app -- librewolf" # Librewolf
            "SUPER SHIFT, W, exec, uwsm app -- mullvad-browser" # Mullvad
            "SUPER ALT, W, exec, uwsm app -- dillo" # Dillo+

            # Swap windows
            "SUPER SHIFT, left, movewindow, l"
            "SUPER SHIFT, right, movewindow, r"
            "SUPER SHIFT, up, movewindow, u"
            "SUPER SHIFT, down, movewindow, d"
            # Move focus
            "SUPER, left, movefocus, l"
            "SUPER, right, movefocus, r"
            "SUPER, up, movefocus, u"
            "SUPER, down, movefocus, d"
            "SUPER, BracketLeft, movefocus, l"
            "SUPER, BracketRight, movefocus, r"

            # Workspace, window, tab switch with keyboard
            "SUPER CTRL, right, workspace, +1"
            "SUPER CTRL, left, workspace, -1"
            "SUPER CTRL, BracketLeft, workspace, -1"
            "SUPER CTRL, BracketRight, workspace, +1"
            "SUPER CTRL, up, workspace, -5"
            "SUPER CTRL, down, workspace, +5"
            "SUPER, Page_Down, workspace, +1"
            "SUPER, Page_Up, workspace, -1"
            "SUPER CTRL, Page_Down, workspace, +1"
            "SUPER CTRL, Page_Up, workspace, -1"
            "SUPER SHIFT, Page_Down, movetoworkspace, +1"
            "SUPER SHIFT, Page_Up, movetoworkspace, -1"
            "SUPER CTRL SHIFT, Right, movetoworkspace, +1"
            "SUPER CTRL SHIFT, Left, movetoworkspace, -1"
            "SUPER SHIFT, mouse_down, movetoworkspace, -1"
            "SUPER SHIFT, mouse_up, movetoworkspace, +1"

            # Fullscreen
            "SUPER, F, fullscreen, 0"
            "SUPER SHIFT, F, fullscreen, 1"

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
            "SUPER CTRL SHIFT, Up, movetoworkspacesilent, special"
            "SUPER ALT, S, movetoworkspacesilent, special"

            # Scroll through existing workspaces with (Control) + Super + scroll
            "SUPER, mouse_up, workspace, +1"
            "SUPER, mouse_down, workspace, -1"
            "SUPER CTRL, mouse_up, workspace, +1"
            "SUPER CTRL, mouse_down, workspace, -1"
            "SUPER CTRL, Backslash, resizeactive, exact 640 480"
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
          ];

          # Lid switch binds for clamshell mode and audio mute
          bindl = [
            ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
            ", switch:off:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, 2560x1600@60, 0x0, 1.6\""
          ];

          exec-once = [
            "wl-paste --watch cliphist store & disown" # Clipboard history daemon
            "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent & disown" # Hyprland polkit agent
            "swww-daemon & disown" # Wallpaper daemon
            "hyprctl setcursor Sonic 32" # Set Sonic cursor at size 32
          ];

          env = [
            "QT_QPA_PLATFORM,wayland"
            "ELECTRON_OZONE_PLATFORM_HINT,auto"
            "QT_QPA_PLATFORMTHEME,qt6ct"
            "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
            "SDL_VIDEODRIVER,wayland" # SDL applications
            "MOZ_ENABLE_WAYLAND,1" # Firefox
            "XDG_CURRENT_DESKTOP,Hyprland" # Desktop environment detection
            "XDG_SESSION_TYPE,wayland" # Session type
            "WAYLAND_DISPLAY,wayland-1" # Wayland display
            "_JAVA_AWT_WM_NONREPARENTING,1" # Java applications
            "GTK_USE_PORTAL,1" # GTK portal integration
            "NIXOS_OZONE_WL,1" # NixOS ozone Wayland
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
              size = 3;
              passes = 2;
              vibrancy = 0.1696;
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

          cursor = {
            no_hardware_cursors = true;
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
