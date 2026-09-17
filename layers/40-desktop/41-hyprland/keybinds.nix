{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "dolphin";
      "$browser" = "brave";
      "$ipc" = "noctalia msg";

      bind = [
        # ── Core App Launchers ─────────────────────────────────────────
        "$mod, Return, exec, uwsm app -- ghostty"
        "$mod SHIFT, Return, exec, uwsm app -- warp-terminal"
        "$mod, T, exec, uwsm app -- ghostty"
        "$mod, E, exec, uwsm app -- dolphin"
        "$mod, Y, exec, uwsm app -- ghostty -e yazi"
        "$mod SHIFT, Y, exec, ghostty -e nu ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu launch"
        "$mod, M, exec, uwsm app -- spotify"

        "$mod CTRL, E, exec, uwsm app -- ghostty -e sf"
        "$mod SHIFT, E, exec, pypr toggle nwglook"

        "$mod, B, exec, uwsm app -- brave"
        "$mod CTRL, B, exec, uwsm app -- librewolf"
        "$mod SHIFT, B, exec, uwsm app -- mullvad-browser"
        "$mod ALT, B, exec, uwsm app -- dillo"
        "$mod SHIFT, T, exec, uwsm app -- kitty"
        "$mod SHIFT, A, exec, wlr-which-key agents"

        "$mod, Space, exec, vicinae toggle"
        "$mod, slash, exec, cheatsheet"
        "$mod, Return, exec, wlr-which-key"

        # ── Dropdown Scratchpads (Pyprland) ───────────────────────────
        "ALT, T, exec, pypr toggle term"
        "ALT, N, exec, pypr toggle gedit"
        "ALT, G, exec, pypr toggle gemini"

        # ── Screenshots (save to ~/Pictures/Screenshots + clipboard) ────
        ", Print, exec, hypr-screenshot region"
        "SHIFT, Print, exec, hypr-screenshot full"
        "$mod CTRL, S, exec, hypr-screenshot edit"
        ", XF86AudioEject, exec, hypr-screenshot region"
        "SHIFT, XF86AudioEject, exec, hypr-screenshot full"
        "CTRL SHIFT, S, exec, hypr-screenshot edit"

        # ── System / Session ───────────────────────────────────────────
        "$mod, Q, killactive"
        "$mod CTRL SHIFT, M, exec, hypr-sfx-toggle"
        "$mod, F, fullscreen, 1"
        "$mod ALT, F, fullscreen, 1"

        # ── Scrolling Layout Resizing ──
        "$mod, Equal, resizeactive, 40 0"
        "$mod, Minus, resizeactive, -40 0"
        "$mod SHIFT, R, exec, hypr-scrolling-resize"

        # ── Dynamic Workspace Navigation (Per-Monitor cycle) ───────────
        # This acts like Niri by staying on the focused monitor
        "$mod, bracketright, workspace, m+1"
        "$mod, bracketleft, workspace, m-1"
        "$mod SHIFT, bracketright, movetoworkspace, m+1"
        "$mod SHIFT, bracketleft, movetoworkspace, m-1"

        # ── Absolute Workspace Navigation (Fallback / Direct jumping) ──
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        #"$mod SHIFT, left, movewindow, l"
        #"$mod SHIFT, right, movewindow, r"
        #"$mod SHIFT, up, movewindow, u"
        #"$mod SHIFT, down, movewindow, d"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, j, movefocus, u"
        "$mod, k, movefocus, d"

        "$mod CTRL, right, workspace, +1"
        "$mod CTRL, left, workspace, -1"
        "$mod CTRL, BracketLeft, workspace, -1"
        "$mod CTRL, BracketRight, workspace, +1"
        "$mod CTRL, up, workspace, -5"
        "$mod CTRL, down, workspace, +5"
        "$mod, Page_Down, workspace, +1"
        "$mod, Page_Up, workspace, -1"
        "$mod CTRL, Page_Down, workspace, +1"
        "$mod CTRL, Page_Up, workspace, -1"
        "$mod SHIFT, Page_Down, movetoworkspace, +1"
        "$mod SHIFT, Page_Up, movetoworkspace, -1"
        "$mod CTRL SHIFT, Right, movetoworkspace, +1"
        "$mod CTRL SHIFT, Left, movetoworkspace, -1"
        "$mod SHIFT, mouse_down, movetoworkspace, -1"
        "$mod SHIFT, mouse_up, movetoworkspace, +1"

        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"

        "$mod SHIFT, S, togglespecialworkspace"
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop,"

        "$mod ALT, 1, movetoworkspacesilent, 1"
        "$mod ALT, 2, movetoworkspacesilent, 2"
        "$mod ALT, 3, movetoworkspacesilent, 3"
        "$mod ALT, 4, movetoworkspacesilent, 4"
        "$mod ALT, 5, movetoworkspacesilent, 5"
        "$mod ALT, 6, movetoworkspacesilent, 6"
        "$mod ALT, 7, movetoworkspacesilent, 7"
        "$mod ALT, 8, movetoworkspacesilent, 8"
        "$mod ALT, 9, movetoworkspacesilent, 9"
        "$mod ALT, 0, movetoworkspacesilent, 10"
        "$mod CTRL SHIFT, Up, movetoworkspacesilent, special"
        "$mod ALT, S, movetoworkspacesilent, special"

        #"$mod, mouse_up, workspace, +1"
        #"$mod, mouse_down, workspace, -1"
        ##"$mod CTRL, mouse_up, workspace, +1"
        #"$mod CTRL, mouse_down, workspace, -1"
        "$mod CTRL, Backslash, resizeactive, exact 640 480"

        # "$mod CTRL, left, workspace, e-1"
        # "$mod CTRL, right, workspace, e+1"
        # "$mod CTRL SHIFT, left, movetoworkspace, r-1"
        # "$mod CTRL SHIFT, right, movetoworkspace, r+1"

        # ── External Monitor Quick Send ──
        "$mod ALT, H, movewindow, mon:HDMI-A-1"
        "$mod ALT, J, movewindow, mon:eDP-1"
        "$mod ALT, K, movewindow, mon:eDP-1"
        "$mod ALT, L, movewindow, mon:DP-2"
        #"$mod CTRL SHIFT, Left, movewindow, mon:l"
        #"$mod CTRL SHIFT, Right, movewindow, mon:r"

        # ── Media Keys (Non-repeating fallback) ────────────────────────
        ", XF86AudioPlay, exec, $ipc media toggle"
        ", XF86AudioNext, exec, $ipc media next"
        ", XF86AudioPrev, exec, $ipc media previous"
        "ALT, 4, exec, $ipc media previous"
        "ALT, 5, exec, $ipc media toggle"
        "ALT, 6, exec, $ipc media next"
        "ALT, 7, exec, $ipc volume-down"
        "ALT, 9, exec, $ipc volume-up"
      ];

      binde = [
        "ALT, 1, exec, playerctl position 2-"
        "ALT, 3, exec, playerctl position 2+"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod, mouse:274, movewindow"
      ];

      # Repeating Media Keys (Volume/Brightness)
      bindel = [
        ", XF86AudioRaiseVolume, exec, $ipc volume-up"
        ", XF86AudioLowerVolume, exec, $ipc volume-down"
        ", XF86AudioMute, exec, $ipc volume-mute"
        ", XF86MonBrightnessUp, exec, $ipc brightness-up"
        ", XF86MonBrightnessDown, exec, $ipc brightness-down"
      ];
    };
  };
}
