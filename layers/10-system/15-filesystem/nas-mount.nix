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

    host = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.158";
      description = "NAS hostname or IP address";
    };

    share = lib.mkOption {
      type = lib.types.str;
      default = "Share";
      description = "SMB share name to mount (case-sensitive)";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/NAS";
      description = "System mount point for NAS storage share";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.cifs-utils
      pkgs.samba # smbclient -L //host for share discovery/diagnostics (pkgs.smbclient attr was removed; samba ships the binary)
    ];

    # Credentials are user-supplied via `clan vars set <machine> nas-credentials smb-credentials`
    # File format must be:
    #   username=<user>
    #   password=<pass>
    # Buffalo NAS default: guest/guest
    clan.core.vars.generators.nas-credentials = {
      files."smb-credentials" = {
        secret = true;
        owner = "root";
        group = "root";
      };
      prompts."smb-credentials" = {
        type = "hidden";
        description = "NAS SMB credentials file — two lines: username=<user> then password=<pass>";
      };
    };

    fileSystems."${cfg.mountPoint}" = {
      device = "//${cfg.host}/${cfg.share}";
      fsType = "cifs";
      options = [
        "credentials=${config.clan.core.vars.generators.nas-credentials.files."smb-credentials".path}"
        "uid=1000"
        "gid=100"
        "file_mode=0775"
        "dir_mode=0775"
        # Buffalo LinkStation requires SMB 1.0 (NT1)
        "vers=1.0"
        "soft"
        # Systemd automount — only mount on first access, unmount after idle
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=15s"
        # Correctly mark as network-dependent so it waits for the network
        "_netdev"
        # Ensure clean unmount during shutdown (avoids stale mount on next boot)
        "x-systemd.before=shutdown.target"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0775 root 100 - -"
      "L+ ${config.users.users.t0psh31f.home}/NAS - - - - ${cfg.mountPoint}"
    ];
  };
}
