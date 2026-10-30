# Tier: 10-system
# Module: nas-mounts.nix
# Purpose: Network NAS automount & Litestream SQLite live replication pipeline for Pi durable state.
# Option Path: layers.layer-10.system.config.nas-mounts
# Enabling Host Tags: workstation, desktop, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-10.system.config.nas-mounts;
  litestreamConfigFile = pkgs.writeText "litestream.yml" ''
    dbs:
      - path: ${cfg.sqliteDbPath}
        replicas:
          - type: file
            path: ${cfg.backupDir}/state.db
            sync-interval: 1s
  '';
in
{
  options.layers.layer-10.system.config.nas-mounts = {
    enable = mkEnableOption "Network NAS mounts & SQLite live replication pipeline";

    host = mkOption {
      type = types.str;
      default = "192.168.1.158";
      description = "NAS hostname or IP address";
    };

    protocol = mkOption {
      type = types.enum [
        "cifs"
        "nfs"
      ];
      default = "cifs";
      description = "Network filesystem protocol (cifs or nfs)";
    };

    share = mkOption {
      type = types.str;
      default = "Share";
      description = "SMB share name to mount (case-sensitive)";
    };

    nfsPath = mkOption {
      type = types.str;
      default = "/mnt/nas/backups";
      description = "NFS export path on the NAS host";
    };

    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/nas";
      description = "System mount point for network NAS storage";
    };

    backupDir = mkOption {
      type = types.str;
      default = "/mnt/nas/backups/nfp-durable";
      description = "Target backup directory on NAS for SQLite WAL replicas and snapshots";
    };

    sqliteDbPath = mkOption {
      type = types.str;
      default = "/home/t0psh31f/.local/share/pi-durable/state.sqlite";
      description = "Local SQLite database path to replicate via Litestream";
    };

    enableLitestream = mkOption {
      type = types.bool;
      default = true;
      description = "Enable continuous Litestream WAL frame replication to NAS";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cifs-utils
      samba
      nfs-utils
      litestream
    ];

    # Automount filesystem declaration
    fileSystems."${cfg.mountPoint}" = {
      device =
        if cfg.protocol == "nfs" then "${cfg.host}:${cfg.nfsPath}" else "//${cfg.host}/${cfg.share}";
      fsType = cfg.protocol;
      options =
        if cfg.protocol == "nfs" then
          [
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=60"
            "x-systemd.device-timeout=10s"
            "x-systemd.mount-timeout=15s"
            "_netdev"
            "soft"
            "nfsvers=4.1"
          ]
        else
          [
            "guest"
            "uid=1000"
            "gid=100"
            "file_mode=0775"
            "dir_mode=0775"
            "vers=1.0"
            "soft"
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=60"
            "x-systemd.device-timeout=10s"
            "x-systemd.mount-timeout=15s"
            "_netdev"
            "x-systemd.before=shutdown.target"
          ];
    };

    # Deploy system-wide litestream configuration
    environment.etc."litestream.yml".source = litestreamConfigFile;

    # Directory and symlink management & background sync daemons
    systemd = {
      tmpfiles.rules = [
        "d ${cfg.mountPoint} 0775 root 100 - -"
        "d ${cfg.backupDir} 0775 1000 100 - -"
        "L+ /mnt/NAS - - - - ${cfg.mountPoint}"
        "L+ ${config.users.users.t0psh31f.home}/NAS - - - - ${cfg.mountPoint}"
      ];

      services = {
        # Continuous SQLite WAL streaming daemon with recovery auto-pull on startup
        nfp-pi-durable-litestream = mkIf cfg.enableLitestream {
          description = "Litestream SQLite Live Replication Daemon for Pi Durable State";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "mnt-nas.mount"
          ];
          wants = [ "network.target" ];

          serviceConfig = {
            User = "t0psh31f";
            Group = "users";
            Restart = "always";
            RestartSec = "10s";
            # Auto-pull recovery if local state is missing
            ExecStartPre = pkgs.writeShellScript "litestream-prestart" ''
              set -euo pipefail
              DB="${cfg.sqliteDbPath}"
              REPLICA="${cfg.backupDir}/state.db"
              DIR="$(dirname "$DB")"
              mkdir -p "$DIR"

              if [ ! -f "$DB" ] && [ -d "$REPLICA" ]; then
                echo "[Litestream] Local database missing; performing recovery auto-pull from $REPLICA..."
                ${pkgs.litestream}/bin/litestream restore -if-replica-exists -config /etc/litestream.yml "$DB" || true
              fi
            '';
            ExecStart = "${pkgs.litestream}/bin/litestream replicate -config /etc/litestream.yml -restore-if-db-not-exists";
          };
        };

        # Periodic snapshot sync timer for offline / reboot survival
        nfp-pi-durable-nas-snapshot = mkIf cfg.enableLitestream {
          description = "Periodic SQLite Snapshot Sync to NAS Backup Directory";
          after = [
            "network.target"
            "mnt-nas.mount"
          ];
          serviceConfig = {
            Type = "oneshot";
            User = "t0psh31f";
            Group = "users";
            ExecStart = pkgs.writeShellScript "nas-snapshot-sync" ''
              set -euo pipefail
              DB="${cfg.sqliteDbPath}"
              TARGET_DIR="${cfg.backupDir}"

              # Gracefully exit 0 if mount is currently unreachable or offline
              if [ ! -d "$TARGET_DIR" ]; then
                echo "[SnapshotSync] NAS backup directory $TARGET_DIR not accessible, skipping."
                exit 0
              fi

              if [ -f "$DB" ]; then
                echo "[SnapshotSync] Syncing Litestream force-snapshot to $TARGET_DIR..."
                ${pkgs.litestream}/bin/litestream replicate -config /etc/litestream.yml -once -force-snapshot || true
              fi
            '';
          };
        };
      };

      timers.nfp-pi-durable-nas-snapshot = mkIf cfg.enableLitestream {
        description = "Periodic SQLite Snapshot Sync to NAS Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "15m";
          Persistent = true;
        };
      };
    };
  };
}
