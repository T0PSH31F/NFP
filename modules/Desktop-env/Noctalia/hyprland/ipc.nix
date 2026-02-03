# modules/desktop/noctalia/hyprland/ipc.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.desktop.noctalia;
in
{
  config = lib.mkIf (cfg.enable && cfg.backend == "hyprland") {
    home-manager.users.t0psh31f = {
      # Noctalia systemd service (recommended for reliability)[web:page]
      systemd.user.services.noctalia-shell = {
        Unit = {
          Description = "Noctalia Shell";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
        Service = {
          ExecStart = "${cfg.package}/bin/noctalia-shell";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };

      # IPC helpers (wrap common calls)
      home.packages = [
        (pkgs.writeShellApplication {
          name = "noctalia-ipc";
          runtimeInputs = [ cfg.package ];
          text = ''
            cmd="$1"; shift
            noctalia-shell ipc "$cmd" "$@"
          '';
        })
      ];

      # Env vars for Noctalia IPC discovery/integration
      wayland.windowManager.hyprland.settings.env = [
        "NOCTALIA_SOCKET,~/.cache/noctalia/noctalia.sock"  # If socket-based
      ];

      # Startup order: Ensure Noctalia starts after Hyprland plugins
      wayland.windowManager.hyprland.settings."exec-once" = lib.mkAfter [
        "systemctl --user start noctalia-shell.service"
      ];
    };
  };
}