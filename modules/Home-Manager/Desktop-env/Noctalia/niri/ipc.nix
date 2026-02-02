# modules/desktop/noctalia/niri/ipc.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.desktop.noctalia;
in
{
  config = lib.mkIf (cfg.enable && cfg.backend == "niri") {
    home-manager.users.t0psh31f = {
      systemd.user.services.noctalia-shell = {
        # Same as Hyprland: systemd service for IPC reliability[web:page]
        Unit.Description = "Noctalia Shell (Niri)";
        Service.ExecStart = "${cfg.package}/bin/noctalia-shell";
        Install.WantedBy = [ "graphical-session.target" ];
      };

      programs.niri.settings."exec-once" = [
        "systemctl --user start noctalia-shell.service"
      ];
    };
  };
}
