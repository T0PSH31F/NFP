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
    services = {
      udisks2.enable = true;
      devmon.enable = false;
      gvfs.enable = true;
      udev.extraRules = ''
        # Poll removable block devices (USB hubs/readers) every 2s for partition changes
        SUBSYSTEM=="block", ATTRS{removable}=="1", ATTR{events_poll_msecs}="2000"
      '';
    };

    environment.etc."udisks2/mount_options.conf".text = ''
      [defaults]
      ntfs_defaults=uid=$UID,gid=$GID,force
      ntfs_allow=uid=$UID,gid=$GID,umask,dmask,fmask,locale,norecover,ignore_case,windows_names,compression,nocompression,nohidden,sys_immutable,sparse,showmeta,hide_dot_files,windows_names,force
      ntfs:ntfs3_defaults=uid=$UID,gid=$GID,force
      ntfs:ntfs3_allow=uid=$UID,gid=$GID,umask,dmask,fmask,iocharset,discard,nodiscard,force,ro,rw
    '';

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
