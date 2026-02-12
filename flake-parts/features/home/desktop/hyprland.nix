{
  config,
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.hyprland;

  hypr-keybind-cheatsheet = pkgs.writeShellScriptBin "hypr-keybind-cheatsheet" ''
      #!/usr/bin/env bash
      CHEATSHEET="
    📱 LAUNCHERS & SHELL
    ─────────────────────────────────────────
    Super + A                  Noctalia Launcher
    Super + Space              Vicinae Launcher (Fast)
    Super                      Hyprspace Overview (Workspaces)
    Super + X                  Control Center
    Super + Comma              Settings
    Super + L                  Lock Screen
    Ctrl + Alt + Del           Session Menu
    Super + Shift + N          Notification Center
    Super + /                  This Cheatsheet

    🪟 WINDOW MANAGEMENT
    ─────────────────────────────────────────
    Super + Q                  Kill Active Window
    Super + F                  Fullscreen
    Super + Shift + F          Maximize
    Super + Arrows             Move Focus
    Super + Shift + Arrows     Move Window
    Super + Mouse (Left)       Move Window
    Super + Mouse (Right)      Resize Window
    Super + -/=                Split Ratio
    Alt + Tab                  Cycle Windows

    🖥️ WORKSPACES
    ─────────────────────────────────────────
    Super + 1-9/0              Switch to Workspace
    Super + Shift + 1-9/0      Move to Workspace
    Super + Alt + 1-9/0        Move Silently
    Super + Ctrl + Left/Right  Previous/Next Workspace
    Super + Mouse Wheel        Scroll Workspaces
    Super + Shift + S          Toggle Special Workspace

    🎮 SCRATCHPADS
    ─────────────────────────────────────────
    Alt + T or Alt + Enter     Ghostty Dropdown Terminal
    Super + H                  Gedit Scratchpad
    Super + Shift + E          nwg-look GTK Themes

    🚀 APPLICATIONS
    ─────────────────────────────────────────
    Super + T or Return        Ghostty Terminal
    Super + Shift + T          Kitty Terminal
    Super + Shift + Return     Warp Terminal
    Super + W                  Brave Browser
    Super + Ctrl + W           LibreWolf Browser
    Super + Shift + W          Mullvad Browser
    Super + E                  Thunar File Manager
    Super + Ctrl + E           SuperFile (Terminal)
    Super + Y                  Yazelix Editor
    Super + Shift + Y          Yazi File Browser
    Super + M                  Spotify

    🎨 YAZELIX EDITOR
    ─────────────────────────────────────────
    Within Yazelix:
    Space                      Command Palette
    Space + f                  Find Files
    Space + /                  Search in Files
    Space + b                  Buffer List
    Space + w                  Save File
    Space + q                  Quit
    Ctrl + h/j/k/l             Navigate Splits
    g + d                      Go to Definition
    g + r                      Find References
    Space + e                  File Explorer Toggle
    Space + g                  Git Status

    📸 SCREENSHOTS
    ─────────────────────────────────────────
    Print                      Noctalia Screenshot
    Shift + Print              Flameshot Full Screen
    Ctrl + Print               Flameshot GUI

    🎵 MEDIA CONTROLS
    ─────────────────────────────────────────
    Alt + 4                    Previous Track
    Alt + 5                    Play/Pause
    Alt + 6                    Next Track
    Alt + 1                    Rewind 2s
    Alt + 3                    Forward 2s
    Alt + 7                    Volume Down
    Alt + 9                    Volume Up
    XF86 Media Keys            Also Supported

    💡 HINTS
    ─────────────────────────────────────────
    • Hyprspace (Super) shows all workspaces
    • Vicinae is faster for app launching
    • Noctalia provides system integration
    • Use scratchpads for quick access
    • Yazelix is Helix-based modal editor
    "
      echo "$CHEATSHEET" | ${pkgs.rofi}/bin/rofi -dmenu \
        -p "Hyprland Keybinds" \
        -theme-str 'window {width: 55%; height: 90%;}' \
        -theme-str 'listview {columns: 1;}' \
        -theme-str 'element-text {font: "monospace 9";}'
  '';
in
{
  options.desktop.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = builtins.elem "desktop" (osConfig.clan.core.tags or [ ]);
      description = "Enable Hyprland Desktop Environment";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      adw-gtk3
      cliphist
      dunst
      gedit
      ghostty
      grim
      hue-plus
      hueadm
      hypr-keybind-cheatsheet
      hyprpolkitagent
      inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
      inputs.hyprspace.packages.${pkgs.system}.Hyprspace
      kitty
      libnotify
      nemo-with-extensions
      nwg-look
      openhue-cli
      playerctl
      pyprland
      pywalfox-native
      qt6Packages.qt6ct
      rofi
      rose-pine-hyprcursor
      slurp
      steam-rom-manager
      swayimg
      swaynotificationcenter
      swww
      warp-terminal
      wl-clipboard
      xdg-user-dirs
      xdg-utils
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      systemd.enable = false;
      plugins = [
        inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
        inputs.hyprspace.packages.${pkgs.system}.Hyprspace
      ];

      settings = {
        source = "~/.config/hypr/colors.conf";

        "$mod" = "SUPER";
        "$terminal" = "ghostty";
        "$fileManager" = "nemo-with-extensions";
        "$browser" = "brave";
        "$ipc" = "noctalia-shell ipc call";

        plugin = {
          "dynamic-cursors" = {
            enabled = true;
            mode = "rotate";
            threshold = 2;
            rotate = {
              length = "$cursorSize";
            };

            tilt = {
              limit = 3000;
            };

            stretch = {
              limit = 3000;
              function = "quadratic";
            };

            shake = {
              enabled = false;
              effects = false;
              ipc = true;
            };

            shaperule = "default, rotate, rotate:offset: $cursorRot";
          };

          overview = {
            centerAligned = true;
            hideBackgroundLayers = true;
            hideTopLayers = true;
            hideOverlayLayers = false;
            showNewWorkspace = true;
            showEmptyWorkspace = false;
            showSpecialWorkspace = true;
            exitOnClick = true;
            switchOnDrop = true;
            exitOnSwitch = false;
            drawActiveWorkspace = true;
            reverseSwipe = true;
            workspaceMargin = 15;
            reservedArea = 96;
            panelColor = "rgba(0, 0, 0, 0.7)";
            panelBorderColor = "rgba(255, 255, 255, 0.5)";
            activeWorkspaceColor = "rgba(242, 143, 173, 0.3)";
            inactiveWorkspaceColor = "rgba(87, 82, 104, 0.3)";
            dragAlpha = 0.3;
            workspaceActiveBackground = "rgba(49, 50, 68, 1)";
            workspaceInactiveBackground = "rgba(31, 32, 46, 1)";
            workspaceActiveBorder = "rgba(242, 143, 173, 1)";
            workspaceInactiveBorder = "rgba(87, 82, 104, 1)";
          };
        };

        windowrule = [
        ];

        bind = lib.mkAfter [
          "SUPER, A, exec, $ipc launcher toggle"
          "SUPER, Space, exec, vicinae"
          "SUPER, SUPER_L, overview:toggle"
          "SUPER, slash, exec, hypr-keybind-cheatsheet"

          "SUPER, X, exec, noctalia-shell ipc control-center"
          "SUPER, L, exec, noctalia-shell ipc lock"
          "CTRL ALT, Delete, exec, noctalia-shell ipc session-menu"
          "SUPER SHIFT, N, exec, noctalia-shell ipc notification-center"

          # Media keys handled by bindel/bindl below
          ", XF86AudioPlay, exec, noctalia-shell ipc media play-pause"
          ", XF86AudioNext, exec, noctalia-shell ipc media next"
          ", XF86AudioPrev, exec, noctalia-shell ipc media previous"

          # Custom Media Controls (ALT + Numbers)
          "ALT, 4, exec, noctalia-shell ipc media previous"
          "ALT, 5, exec, noctalia-shell ipc media play-pause"
          "ALT, 6, exec, noctalia-shell ipc media next"
          "ALT, 7, exec, noctalia-shell ipc volume -3"
          "ALT, 9, exec, noctalia-shell ipc volume +3"

          "SUPER SHIFT, Tab, exec, noctalia-shell ipc overview"

          "SUPER, Q, killactive,"
          "SUPER, C, exec, $ipc controlCenter toggle"
          "SUPER, comma, exec, $ipc settings toggle"
          "SUPER, T, exec, uwsm app -- ghostty"
          "SUPER, Return, exec, uwsm app -- ghostty"
          "SUPER SHIFT, T, exec, uwsm app -- kitty"
          "SUPER SHIFT, Return, exec, uwsm app -- warp-terminal"
          "SUPER, E, exec, uwsm app -- thunar"
          "SUPER CTRL, E, exec, uwsm app -- ghostty -e sf"
          "SUPER SHIFT, E, exec, pypr toggle nwglook"
          "SUPER, Y, exec, ghostty -e nu ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu launch"
          "SUPER SHIFT, Y, exec, ghostty -e yazi"
          "SUPER, M, exec, uwsm app -- spotify"

          # Scratchpads (Pyprland)
          # Ghostty Dropdown (Alt+T or Alt+Enter)
          "ALT, T, exec, pypr toggle term"
          "ALT, Return, exec, pypr toggle term"

          # Gedit Scratchpad (Super+H)
          "SUPER, H, exec, pypr toggle gedit"

          "SHIFT, Print, exec, flameshot full --path ~/Pictures/screenshots"
          "CTRL, Print, exec, flameshot gui --path ~/Pictures/screenshots"
          ", Print, exec, flameshot gui --path ~/Pictures/screenshots"

          "SUPER, W, exec, uwsm app -- brave"
          "SUPER CTRL, W, exec, uwsm app -- librewolf"
          "SUPER SHIFT, W, exec, uwsm app -- mullvad-browser"
          "SUPER ALT, W, exec, uwsm app -- dillo"

          "SUPER SHIFT, left, movewindow, l"
          "SUPER SHIFT, right, movewindow, r"
          "SUPER SHIFT, up, movewindow, u"
          "SUPER SHIFT, down, movewindow, d"

          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"
          "SUPER, BracketLeft, movefocus, l"
          "SUPER, BracketRight, movefocus, r"

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

          "SUPER, F, fullscreen, 0"
          "SUPER SHIFT, F, fullscreen, 1"

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
          "ALT, Tab, bringactivetotop,"

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

          "SUPER, mouse_up, workspace, +1"
          "SUPER, mouse_down, workspace, -1"
          "SUPER CTRL, mouse_up, workspace, +1"
          "SUPER CTRL, mouse_down, workspace, -1"
          "SUPER CTRL, Backslash, resizeactive, exact 640 480"

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

          "ALT, 1, exec, playerctl position 2-"
          "ALT, 3, exec, playerctl position 2+"
        ];

        bindm = [
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
          "SUPER, mouse:274, movewindow"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, $ipc volume increase"
          ", XF86AudioLowerVolume, exec, $ipc volume decrease"
          ", XF86MonBrightnessUp, exec, $ipc brightness increase"
          ", XF86MonBrightnessDown, exec, $ipc brightness decrease"
        ];

        bindl = [
          ", XF86AudioMute, exec, $ipc volume muteOutput"
          # ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
          # ", switch:off:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, 2560x1600@60, 0x0, 1.6\""
        ];

        exec-once = [
          "noctalia-shell & disown"
          "wl-paste --watch cliphist store & disown"
          "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent & disown"
          "pypr & disown"
        ];

        env = [
          "QT_QPA_PLATFORM,wayland"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "QT_QPA_PLATFORMTHEME,qt6ct"
          "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
          "SDL_VIDEODRIVER,wayland"
          "MOZ_ENABLE_WAYLAND,1"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "WAYLAND_DISPLAY,wayland-1"
          "_JAVA_AWT_WM_NONREPARENTING,1"
          "GTK_USE_PORTAL,1"
          "NIXOS_OZONE_WL,1"
          "HYPRCURSOR_THEME,rose-pine-hyprcursor"
          "HYPRCURSOR_SIZE,32"
        ];

        general = {
          border_size = 3;
          "col.active_border" = "$border_active_1 $border_active_2 45deg";
          "col.inactive_border" = "$border_inactive";
          resize_on_border = true;
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            vibrancy = 0.1696;
          };
          shadow = {
            enabled = true;
            range = 40;
            render_power = 2;
            color = "$shadow_active";
            color_inactive = "$shadow_inactive";
          };
          screen_shader = "${../../../../assets/hypr-shaders/vibrance.glsl.mustache}";
        };

        misc = {
          animate_manual_resizes = true;
          animate_mouse_windowdragging = true;
          enable_swallow = true;
          focus_on_activate = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        cursor = {
          # no_hardware_cursors = true;
        };

        bezier = [
          "liner, 1, 1, 1, 1"
          "wind, 0.05, 0.85, 0.03, 0.97"
          "winIn, 0.07, 0.88, 0.04, 0.99"
          "winOut, 0.20, -0.15, 0, 1"
          "md3_standard, 0.12, 0, 0, 1"
          "md3_decel, 0.05, 0.80, 0.10, 0.97"
          "md3_accel, 0.20, 0, 0.80, 0.08"
          "md2, 0.30, 0, 0.15, 1"
          "menu_decel, 0.05, 0.82, 0, 1"
          "menu_accel, 0.20, 0, 0.82, 0.10"
          "easeInOutCirc, 0.75, 0, 0.15, 1"
          "easeOutCirc, 0, 0.48, 0.38, 1"
          "easeInOutCircAlt, 0.78, 0, 0.15, 1"
          "easeOutExpo, 0.10, 0.94, 0.23, 0.98"
          "softAcDecel, 0.20, 0.20, 0.15, 1"
          "OutBack, 0.28, 1.40, 0.58, 1"
          "overshot, 0.05, 0.85, 0.07, 1.04"
          "crazyshot, 0.1, 1.22, 0.68, 0.98"
          "hyprnostretch, 0.05, 0.82, 0.03, 0.94"
        ];

        animation = [
          "border, 1, 8, liner"
          "borderangle, 1, 82, liner, loop"
          "windowsIn, 1, 3.2, winIn, slide"
          "windowsOut, 1, 2.8, easeOutCirc"
          "windowsMove, 1, 3.0, wind, slide"
          "fade, 1, 1.8, md3_decel"
          "layersIn, 1, 1.8, menu_decel, slide"
          "layersOut, 1, 1.5, menu_accel"
          "fadeLayersIn, 1, 1.6, menu_decel"
          "fadeLayersOut, 1, 1.8, menu_accel"
          "workspaces, 1, 4.0, menu_decel, slide"
          "specialWorkspace, 1, 2.3, md3_decel, slidefadevert 15%"
        ];

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

    xdg.configFile."hypr/hyprland.conf".force = true;

    xdg.configFile."hypr/pyprland.toml".text = ''
      [pyprland]
      plugins = ["scratchpads"]

      [scratchpads.term]
      animation = "fromTop"
      command = "ghostty --class=ghostty-dropdown"
      class = "ghostty-dropdown"
      size = "100% 50%"
      lazy = true

      [scratchpads.gedit]
      animation = "fromRight"
      command = "gedit"
      class = "gedit"
      size = "75% 60%"
      position = "center"
      lazy = true

      [scratchpads.nwglook]
      animation = "fromBottom"
      command = "nwg-look"
      class = "nwg-look"
      size = "60% 60%"
      position = "center"
      lazy = true
    '';

    xdg.enable = true;
  };
}
