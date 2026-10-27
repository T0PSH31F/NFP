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
  isEnabled = exp == "noctalia" || exp == "noctalia-niri";
in
{
  nixos = lib.mkIf isEnabled {
    layers.layer-40.desktop.noctalia = {
      enable = true;
      backend = lib.mkDefault (if exp == "noctalia" then "all" else "niri");
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
            Exec=${pkgs.uwsm}/bin/uwsm start -F -N "Noctalia (Niri)" -D Niri:Noctalia -C "Native Noctalia Shell v5 on Niri" -- /run/current-system/sw/bin/niri --session
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
    { lib, ... }:
    {
      config = lib.mkIf isEnabled { };
    };
}
