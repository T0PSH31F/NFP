{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  # Noctalia IPC commands and utilities for Hyprland
  home.packages = with pkgs; [
    # IPC helper scripts
    (writeShellScriptBin "noctalia-ipc" ''
      #!/usr/bin/env bash
      # Noctalia IPC command wrapper
      
      case "$1" in
        overview)
          dms ipc call hypr toggleOverview
          ;;
        spotlight)
          dms ipc call spotlight toggle
          ;;
        clipboard)
          dms ipc call clipboard toggle
          ;;
        notifications)
          dms ipc call notifications toggle
          ;;
        settings)
          dms ipc call settings focusOrToggle
          ;;
        wallpaper)
          dms ipc call dankdash wallpaper
          ;;
        lock)
          dms ipc call lock lock
          ;;
        audio-up)
          dms ipc call audio increment 3
          ;;
        audio-down)
          dms ipc call audio decrement 3
          ;;
        audio-mute)
          dms ipc call audio mute
          ;;
        brightness-up)
          dms ipc call brightness increment 5
          ;;
        brightness-down)
          dms ipc call brightness decrement 5
          ;;
        *)
          echo "Usage: noctalia-ipc {overview|spotlight|clipboard|notifications|settings|wallpaper|lock|audio-up|audio-down|audio-mute|brightness-up|brightness-down}"
          exit 1
          ;;
      esac
    '')

    # Workspace management helper
    (writeShellScriptBin "noctalia-workspace" ''
      #!/usr/bin/env bash
      # Noctalia workspace management
      
      case "$1" in
        next)
          hyprctl dispatch workspace +1
          ;;
        prev)
          hyprctl dispatch workspace -1
          ;;
        move-next)
          hyprctl dispatch movetoworkspace +1
          ;;
        move-prev)
          hyprctl dispatch movetoworkspace -1
          ;;
        goto)
          hyprctl dispatch workspace "$2"
          ;;
        move-to)
          hyprctl dispatch movetoworkspace "$2"
          ;;
        *)
          echo "Usage: noctalia-workspace {next|prev|move-next|move-prev|goto <num>|move-to <num>}"
          exit 1
          ;;
      esac
    '')

    # Window management helper
    (writeShellScriptBin "noctalia-window" ''
      #!/usr/bin/env bash
      # Noctalia window management
      
      case "$1" in
        close)
          hyprctl dispatch killactive
          ;;
        fullscreen)
          hyprctl dispatch fullscreen 0
          ;;
        maximize)
          hyprctl dispatch fullscreen 1
          ;;
        float)
          hyprctl dispatch togglefloating
          ;;
        pin)
          hyprctl dispatch pin
          ;;
        *)
          echo "Usage: noctalia-window {close|fullscreen|maximize|float|pin}"
          exit 1
          ;;
      esac
    '')
  ];
}
