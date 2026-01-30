{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # DankMaterialShell Hyprland-specific config
  # Source: https://github.com/AvengeMedia/DankMaterialShell

  config = lib.mkIf (config.desktop.dankmaterialshell.enable && (config.desktop.dankmaterialshell.backend == "hyprland" || config.desktop.dankmaterialshell.backend == "both")) {
    # Hyprland-specific DankMaterialShell settings
    home-manager.users.t0psh31f = {
      wayland.windowManager.hyprland.settings = {
        # DMS Application Launchers
        bind = lib.mkAfter [
          "SUPER ALT, Space, exec, dms ipc call hypr toggleOverview" # DMS Overview
          # "SUPER ALT, Space, exec, dms ipc call spotlight toggle" # DMS Spotlight
          "SUPER, V, exec, dms ipc call clipboard toggle" # DMS Clipboard
          "SUPER, P, exec, dms ipc call processlist focusOrToggle" # DMS Process list
          "SUPER, comma, exec, dms ipc call settings focusOrToggle" # DMS Settings
          "SUPER, N, exec, dms ipc call notifications toggle" # DMS Notifications
          "SUPER, Y, exec, dms ipc call dankdash wallpaper" # DMS Wallpaper
          "SUPER, A, exec, dms ipc call spotlight toggle" # DMS Spotlight
          # DMS Security
          "SUPER ALT, L, exec, dms ipc call lock lock" # DMS Lock screen
          # Audio Controls
          ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
          ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
          # Brightness Controls
          ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
          ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
          # Audio Mute
          ", XF86AudioMute, exec, dms ipc call audio mute"
        ];
      };
    };
  };
}

