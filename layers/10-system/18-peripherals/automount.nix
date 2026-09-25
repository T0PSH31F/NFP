{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.peripherals.automount;
in
{
  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
    services.devmon.enable = true;
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      udisks
      udiskie
    ];

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
             action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
             action.id == "org.freedesktop.udisks2.eject-media" ||
             action.id == "org.freedesktop.udisks2.power-off-drive") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    home-manager.users.${config.layers.meta.primaryUser} = {
      config = lib.mkIf cfg.useUdiskie {
        services.udiskie = {
          enable = true;
          automount = true;
          tray = "auto";
          notify = true;
        };
      };
    };
  };
}
