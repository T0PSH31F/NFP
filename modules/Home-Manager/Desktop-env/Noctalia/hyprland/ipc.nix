{
  lib,
  pkgs,
  ...
}:
with lib;
{
  # Noctalia IPC commands and utilities for Hyprland
  home.packages = with pkgs; [
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
