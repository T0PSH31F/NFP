# Noctalia Niri Desktop Experience Adapter
# Activates when: layers.desktop.experience = "noctalia-niri"
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "noctalia-niri";
in
{
  nixos = lib.mkIf isEnabled {
    layers.layer-40.desktop.noctalia = {
      enable = true;
      backend = "niri";
    };

    layers.layer-40.desktop.niri.enable = true;

    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "noctalia-niri-wayland-session";
          destination = "/share/wayland-sessions/noctalia-niri.desktop";
          passthru.providedSessions = [ "noctalia-niri" ];
          text = ''
            [Desktop Entry]
            Name=Noctalia (Niri)
            Comment=Native Noctalia Shell v5 on Niri
            Exec=uwsm start niri-uwsm.desktop
            Type=Application
            DesktopNames=Niri
          '';
        })
        // {
          providedSessions = [ "noctalia-niri" ];
        }
      )
    ];
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        systemd.user.services.noctalia-experience-dirs = {
          Unit = {
            Description = "Ensure Noctalia HVE cache and experience directories exist";
            Before = [ "graphical-session-pre.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session-pre.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.cache/noctalia/HVE'";
          };
        };
      };
    };
}
