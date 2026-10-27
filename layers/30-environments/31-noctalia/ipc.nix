{
  osConfig ? config,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  config = lib.mkIf cfg.enable {
    # Global env for all compositors + systemd user session (fixes missing NOCTALIA_SOCKET with Niri/UWSM)
    home.sessionVariables.NOCTALIA_SOCKET = "${config.home.homeDirectory}/.cache/noctalia/noctalia.sock";
    systemd.user.sessionVariables.NOCTALIA_SOCKET = "${config.home.homeDirectory}/.cache/noctalia/noctalia.sock";

    home.packages = [
      cfg.package
      (pkgs.writeShellApplication {
        name = "noctalia-ipc";
        runtimeInputs = [ cfg.package ];
        text = ''
          cmd="$1"; shift
          noctalia msg "$cmd" "$@"
        '';
      })
      (pkgs.writeShellScriptBin "noctalia-restart" ''
        systemctl --user restart noctalia
      '')
      (pkgs.writeShellScriptBin "noctalia-wallpaper-set" ''
        noctalia msg wallpaper-set "$@"
      '')
      (pkgs.writeShellScriptBin "noctalia-theme-toggle" ''
        noctalia msg theme-mode-toggle
      '')
      (pkgs.writeShellScriptBin "noctalia-templates-apply" ''
        noctalia msg templates-apply
      '')
      (pkgs.writeShellScriptBin "noctalia-color-scheme" ''
        noctalia msg color-scheme-set "$@"
      '')
      (pkgs.writeShellScriptBin "noctalia-lock" ''
        noctalia msg session lock || loginctl lock-session
      '')
      (pkgs.writeShellScriptBin "noctalia-compositor-switch" ''
        COMPOSITOR="''${1-}"
        if [ -z "$COMPOSITOR" ]; then
          if command -v rofi >/dev/null 2>&1; then
            COMPOSITOR=$(printf "hyprland\nniri\numbriel" | rofi -dmenu -p "Noctalia Compositor")
          else
            echo "Usage: noctalia-compositor-switch [hyprland|niri|umbriel]"
            exit 1
          fi
        fi

        case "$COMPOSITOR" in
          hyprland)
            exec uwsm start -F -N "Noctalia (Hyprland)" -D Hyprland:Noctalia -C "Native Noctalia Shell v5 on Hyprland" -- /run/current-system/sw/bin/Hyprland
            ;;
          niri)
            exec uwsm start -F -N "Noctalia (Niri)" -D Niri:Noctalia -C "Native Noctalia Shell v5 on Niri" -- /run/current-system/sw/bin/niri --session
            ;;
          umbriel)
            exec uwsm start -F -N "Noctalia (Umbriel)" -D Umbriel:Noctalia -C "Noctalia Shell v5 on Umbriel compositor" -- /run/current-system/sw/bin/umbriel
            ;;
          *)
            echo "Unknown compositor: $COMPOSITOR (supported: hyprland, niri, umbriel)" >&2
            exit 1
            ;;
        esac
      '')
    ];

    wayland.windowManager.hyprland.settings.env =
      lib.mkIf (cfg.backend == "hyprland" || cfg.backend == "both" || cfg.backend == "all")
        [
          "NOCTALIA_SOCKET,$HOME/.cache/noctalia/noctalia.sock"
        ];
  };
}
