{
  osConfig ? config,
  config,
  lib,
  pkgs,
  inputs,
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
    ];

    wayland.windowManager.hyprland.settings.env =
      lib.mkIf (cfg.backend == "hyprland" || cfg.backend == "both")
        [
          "NOCTALIA_SOCKET,$HOME/.cache/noctalia/noctalia.sock"
        ];
  };
}
