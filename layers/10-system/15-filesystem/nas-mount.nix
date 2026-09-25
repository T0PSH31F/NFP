{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.config.nas-mount;
in
{
  options.layers.layer-10.system.config.nas-mount = {
    enable = lib.mkEnableOption "Buffalo NAS CIFS/SMB Automount";
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/NAS";
      description = "System mount point for NAS storage share";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cifs-utils ];

    clan.core.vars.generators.nas-credentials = {
      files."smb-credentials" = {
        secret = true;
        owner = "root";
        group = "root";
      };
      script = ''
        echo "username=guest" > "$out/smb-credentials"
        echo "password=guest" >> "$out/smb-credentials"
      '';
    };

    fileSystems."${cfg.mountPoint}" = {
      device = "//192.168.1.158/Share";
      fsType = "cifs";
      options = [
        "credentials=${config.clan.core.vars.generators.nas-credentials.files."smb-credentials".path}"
        "uid=1000"
        "gid=100"
        "file_mode=0775"
        "dir_mode=0775"
        "vers=1.0"
        "sec=ntlmssp"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "_netdev"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0775 root 100 - -"
      "L+ ${config.users.users.t0psh31f.home}/NAS - - - - ${cfg.mountPoint}"
    ];
  };
}
