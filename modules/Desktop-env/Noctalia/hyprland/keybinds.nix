{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  # Noctalia-specific Hyprland keybindings
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "nemo-with-extensions";
    "$browser" = "brave";

    bind = mkAfter [
      # Window Management
      "SUPER, Q, killactive," # Close/kill active window
      "SUPER, B, fullscreen, 0" # Fullscreen
      "SUPER SHIFT, B, fullscreen, 1" # Maximize

      # Applications
      "SUPER, C, exec, uwsm app -- code" # VSCode
      "SUPER, T, exec, uwsm app -- ghostty" # Terminal
      "SUPER, Return, exec, uwsm app -- ghostty" # Terminal (alternate)
      "SUPER SHIFT, T, exec, uwsm app -- kitty" # Kitty terminal
      "SUPER SHIFT, Return, exec, uwsm app -- warp-terminal" # Warp terminal
      "SUPER, E, exec, uwsm app -- cosmic-files" # File Manager
      "SUPER SHIFT, E, exec, uwsm app -- thunar" # File Manager (alternate)
      "SUPER SHIFT, Y, exec, ghostty -e yazi" # TUI File Manager
      "SUPER, M, exec, uwsm app -- spotify" # Music

      # Browsers (Per-DE keybinds)
      "SUPER, W, exec, uwsm app -- brave" # Brave (default)
      "SUPER CTRL, W, exec, uwsm app -- librewolf" # Librewolf
      "SUPER SHIFT, W, exec, uwsm app -- mullvad-browser" # Mullvad
      "SUPER ALT, W, exec, uwsm app -- dillo" # Dillo+
      "SUPER, F, exec, uwsm app -- brave" # Browser shortcut

      # Screenshots (Flameshot)
      "SHIFT, Print, exec, flameshot full --path ~/Pictures/screenshots" # Full screen
      "CTRL, Print, exec, flameshot gui --path ~/Pictures/screenshots" # Interactive GUI
      ", Print, exec, flameshot gui --path ~/Pictures/screenshots" # Interactive GUI

      # DMS/Noctalia Application Launchers
      "SUPER, Space, exec, dms ipc call hypr toggleOverview" # Overview
      "SUPER ALT, Space, exec, dms ipc call spotlight toggle" # Spotlight
      "SUPER, V, exec, dms ipc call clipboard toggle" # Clipboard
      "SUPER, P, exec, dms ipc call processlist focusOrToggle" # Process list
      "SUPER, comma, exec, dms ipc call settings focusOrToggle" # Settings
      "SUPER, N, exec, dms ipc call notifications toggle" # Notifications
      "SUPER, Y, exec, dms ipc call dankdash wallpaper" # Wallpaper
      "SUPER, A, exec, dms ipc call spotlight toggle" # Spotlight
      "SUPER ALT, L, exec, dms ipc call lock lock" # Lock screen

      # Window Movement
      "SUPER SHIFT, left, movewindow, l"
      "SUPER SHIFT, right, movewindow, r"
      "SUPER SHIFT, up, movewindow, u"
      "SUPER SHIFT, down, movewindow, d"

      # Focus Movement
      "SUPER, left, movefocus, l"
      "SUPER, right, movefocus, r"
      "SUPER, up, movefocus, u"
      "SUPER, down, movefocus, d"
      "SUPER, BracketLeft, movefocus, l"
      "SUPER, BracketRight, movefocus, r"

      # Workspace Navigation
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

      # Move to Workspace
      "SUPER SHIFT, Page_Down, movetoworkspace, +1"
      "SUPER SHIFT, Page_Up, movetoworkspace, -1"
      "SUPER CTRL SHIFT, Right, movetoworkspace, +1"
      "SUPER CTRL SHIFT, Left, movetoworkspace, -1"
      "SUPER SHIFT, mouse_down, movetoworkspace, -1"
      "SUPER SHIFT, mouse_up, movetoworkspace, +1"

      # Workspace Switching (1-10)
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

      # Alt-Tab
      "ALT, Tab, cyclenext"
      "ALT, Tab, bringactivetotop,"

      # Move Window to Workspace (Silent)
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

      # Scroll Workspaces
      "SUPER, mouse_up, workspace, +1"
      "SUPER, mouse_down, workspace, -1"
      "SUPER CTRL, mouse_up, workspace, +1"
      "SUPER CTRL, mouse_down, workspace, -1"
      "SUPER CTRL, Backslash, resizeactive, exact 640 480"

      # Move to Workspace (Visible)
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

      # Workspace Scroll
      "SUPER CTRL, left, workspace, e-1"
      "SUPER CTRL, right, workspace, e+1"
      "SUPER CTRL SHIFT, left, movetoworkspace, r-1"
      "SUPER CTRL SHIFT, right, movetoworkspace, r+1"
    ];

    binde = [
      # Window Resizing
      "SUPER, Minus, splitratio, -0.1"
      "SUPER, Equal, splitratio, 0.1"
      "SUPER, Semicolon, splitratio, -0.1"
      "SUPER, Apostrophe, splitratio, 0.1"
    ];

    bindm = [
      # Mouse Bindings
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
      "SUPER, mouse:274, movewindow"
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
  };
}
