# Tier: 10-system
# Module: nas-mounts.nix
# Purpose: Network NAS automount & Litestream SQLite live replication pipeline for Pi & Jarvis durable state.
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
  primaryUser = config.layers.meta.primaryUser or "t0psh31f";
  userHome = config.users.users.${primaryUser}.home or "/home/${primaryUser}";

  litestreamConfigFile = pkgs.writeText "litestream.yml" ''
    dbs:
    ${concatMapStringsSep "\n" (db: ''
      - path: ${db.path}
        replicas:
          - type: file
            path: ${cfg.backupDir}/${db.name}.db
            sync-interval: ${cfg.syncInterval}
            retention: ${cfg.retention}
            snapshot-interval: ${cfg.snapshotInterval}
    '') cfg.databases}
  '';

  reachabilityCheck = pkgs.writeShellScript "check-nas-reachable" ''
    set -euo pipefail
    # Fast 1-second ping or port check before attempting mount/replication
    if ${pkgs.iputils}/bin/ping -c 1 -W 1 "${cfg.host}" >/dev/null 2>&1; then
      exit 0
    fi
    PORT="${if cfg.protocol == "nfs" then "2049" else "445"}"
    if ${pkgs.netcat}/bin/nc -z -w 1 "${cfg.host}" "$PORT" >/dev/null 2>&1; then
      exit 0
    fi
    exit 1
  '';
in
{
  options.layers.layer-10.system.config.nas-mounts = {
    enable = mkEnableOption "Network NAS mounts & SQLite live replication pipeline";

    host = mkOption {
      type = types.str;
      default = "169.254.16.208";
      description = "NAS hostname or IP address (Buffalo LinkStation active link-local address: 169.254.16.208)";
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

    smbVersion = mkOption {
      type = types.str;
      default = "1.0";
      description = "SMB protocol version (e.g. 1.0, 2.1, 3.0, 3.1.1 — Buffalo LinkStation requires 1.0)";
    };

    credentialsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to CIFS credentials file for authenticated shares";
    };

    nfsPath = mkOption {
      type = types.str;
      default = "/mnt/nas/backups";
      description = "NFS export path on the NAS host";
    };

    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/NAS1";
      description = "System mount point for primary network NAS (NAS1 - 2TB Buffalo LinkStation)";
    };

    backupDir = mkOption {
      type = types.str;
      default = "/mnt/NAS1/backups/nfp-durable";
      description = "Target backup directory on NAS for SQLite WAL replicas and snapshots";
    };

    nas2 = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable secondary network NAS automount (NAS2 - 1TB Buffalo TeraStation)";
      };

      host = mkOption {
        type = types.str;
        default = "192.168.1.225";
        description = "NAS2 hostname or IP address (Buffalo TeraStation HD-HTGL0BB)";
      };

      share = mkOption {
        type = types.str;
        default = "share";
        description = "NAS2 SMB share name to mount";
      };

      port = mkOption {
        type = types.int;
        default = 139;
        description = "NAS2 SMB port (older TeraStation uses NetBIOS TCP port 139)";
      };

      smbVersion = mkOption {
        type = types.str;
        default = "1.0";
        description = "NAS2 SMB protocol version (1.0 / NT1 for TeraStation HD-HTGL)";
      };

      mountPoint = mkOption {
        type = types.str;
        default = "/mnt/NAS2";
        description = "System mount point for secondary network NAS (NAS2 - 1TB)";
      };

      credentialsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional path to CIFS credentials file for NAS2";
      };
    };

    databases = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Database identifier name for the replica folder on NAS";
            };
            path = mkOption {
              type = types.str;
              description = "Absolute local path to the SQLite database";
            };
          };
        }
      );
      default = [
        {
          name = "state";
          path = "${userHome}/.local/share/pi-durable/state.sqlite";
        }
        {
          name = "screenpipe";
          path = "${userHome}/.local/share/jarvis/screenpipe.db";
        }
        {
          name = "execution";
          path = "${userHome}/.local/share/jarvis/execution.db";
        }
        {
          name = "tasklist";
          path = "${userHome}/.local/share/nfp-task-watcher/tasklist.db";
        }
      ];
      description = "List of local SQLite databases to continuously replicate to the NAS.";
    };

    sqliteDbPath = mkOption {
      type = types.str;
      default = "${userHome}/.local/share/pi-durable/state.sqlite";
      description = "Backwards-compatible legacy single database option (superseded by databases).";
    };

    retention = mkOption {
      type = types.str;
      default = "168h";
      description = "Retention duration for Litestream WAL segments on NAS (e.g. 168h for 7 days).";
    };

    syncInterval = mkOption {
      type = types.str;
      default = "1s";
      description = "Litestream continuous WAL frame synchronization interval.";
    };

    snapshotInterval = mkOption {
      type = types.str;
      default = "24h";
      description = "Litestream periodic baseline snapshot creation interval.";
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
      iputils
      netcat
    ];

    networking.networkmanager.dispatcherScripts = mkIf (lib.hasPrefix "169.254." cfg.host) [
      {
        source = pkgs.writeShellScript "nas-link-local-dispatcher" ''
          IFACE="$1"
          ACTION="$2"
          case "$IFACE" in
            wl*|en*|eth*) ;;
            *) exit 0 ;;
          esac
          if [ "$ACTION" = "up" ] || [ "$ACTION" = "dhcp4-change" ]; then
            ${pkgs.iproute2}/bin/ip route replace 169.254.0.0/16 dev "$IFACE" scope link metric 1000 || true
          fi
        '';
        type = "basic";
      }
    ];

    # Automount filesystem declaration (NAS1 - 2TB)
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
          (
            (
              if cfg.credentialsFile != null then
                [
                  "credentials=${toString cfg.credentialsFile}"
                ]
              else
                [
                  "guest"
                ]
            )
            ++ [
              "uid=1000"
              "gid=100"
              "file_mode=0775"
              "dir_mode=0775"
              "vers=${cfg.smbVersion}"
              "soft"
              "nofail"
              "x-systemd.automount"
              "noauto"
              "x-systemd.idle-timeout=60"
              "x-systemd.device-timeout=3s"
              "x-systemd.mount-timeout=3s"
              "_netdev"
              "x-systemd.before=shutdown.target"
            ]
          );
    };

    # Secondary NAS automount declaration (NAS2 - 1TB Buffalo TeraStation)
    fileSystems."${cfg.nas2.mountPoint}" = mkIf cfg.nas2.enable {
      device = "//${cfg.nas2.host}/${cfg.nas2.share}";
      fsType = "cifs";
      options =
        (
          if cfg.nas2.credentialsFile != null then
            [ "credentials=${toString cfg.nas2.credentialsFile}" ]
          else
            [ "guest" ]
        )
        ++ [
          "uid=1000"
          "gid=100"
          "file_mode=0775"
          "dir_mode=0775"
          "port=${toString cfg.nas2.port}"
          "vers=${cfg.nas2.smbVersion}"
          "soft"
          "nofail"
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=3s"
          "x-systemd.mount-timeout=3s"
          "_netdev"
          "x-systemd.before=shutdown.target"
        ];
    };

    # Safely convert an unmounted empty legacy /mnt/nas dir to a symlink -> NAS1
    system.activationScripts.nasCompatSymlinks = mkIf (cfg.mountPoint != "/mnt/nas") ''
      if [ -d /mnt/nas ] && [ ! -L /mnt/nas ] && ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/nas; then
        rmdir /mnt/nas 2>/dev/null || true
      fi
      if [ ! -e /mnt/nas ] && [ ! -L /mnt/nas ]; then
        ln -s "${cfg.mountPoint}" /mnt/nas
      fi
      if [ -d /mnt/NAS ] && [ ! -L /mnt/NAS ] && ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/NAS; then
        rmdir /mnt/NAS 2>/dev/null || true
      fi
      if [ ! -e /mnt/NAS ] && [ ! -L /mnt/NAS ]; then
        ln -s "${cfg.mountPoint}" /mnt/NAS
      fi
    '';

    # Deploy system-wide litestream configuration
    environment.etc."litestream.yml" = mkIf cfg.enableLitestream {
      source = litestreamConfigFile;
    };

    # Directory and symlink management & background sync daemons
    systemd = {
      tmpfiles.rules = [
        "d ${cfg.mountPoint} 0775 root 100 - -"
        "L+ ${userHome}/NAS - - - - ${cfg.mountPoint}"
        "L+ ${userHome}/NAS1 - - - - ${cfg.mountPoint}"
      ]
      ++ optionals cfg.nas2.enable [
        "d ${cfg.nas2.mountPoint} 0775 root 100 - -"
        "L+ ${userHome}/NAS2 - - - - ${cfg.nas2.mountPoint}"
      ]
      ++ optionals cfg.enableLitestream [
        "d ${cfg.backupDir} 0775 1000 100 - -"
      ];

      services = {
        ensure-nas-route = {
          description = "Ensure Link-Local Route to Network NAS";
          wantedBy = [ "network-online.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "ensure-nas-route" ''
              if echo "${cfg.host}" | ${pkgs.gnugrep}/bin/grep -q '^169\.254\.'; then
                DEFAULT_IFACE=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gnugrep}/bin/grep -E '^default.*dev (wl|en|eth)' | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
                if [ -z "$DEFAULT_IFACE" ]; then
                  DEFAULT_IFACE=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gnugrep}/bin/grep '^default' | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
                fi
                case "$DEFAULT_IFACE" in
                  wl*|en*|eth*)
                    ${pkgs.iproute2}/bin/ip route replace 169.254.0.0/16 dev "$DEFAULT_IFACE" scope link metric 1000 || true
                    ;;
                esac
              fi
            '';
          };
        };

        # Continuous SQLite WAL streaming daemon with recovery auto-pull on startup
        nfp-pi-durable-litestream = mkIf cfg.enableLitestream {
          description = "Litestream SQLite Live Replication Daemon for Pi & Jarvis Durable State";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "mnt-NAS1.mount"
          ];
          wants = [ "network.target" ];

          serviceConfig = {
            User = primaryUser;
            Group = "users";
            Restart = "on-failure";
            RestartSec = "30s";
            Slice = "background.slice";
            MemoryHigh = "256M";
            MemoryMax = "512M";

            # Pre-flight reachability check: cleanly pause if NAS is offline
            ExecCondition = reachabilityCheck;

            # Auto-pull recovery if local databases are missing
            ExecStartPre = pkgs.writeShellScript "litestream-prestart" ''
              set -euo pipefail
              TARGET_DIR="${cfg.backupDir}"

              ${concatMapStringsSep "\n" (db: ''
                DB="${db.path}"
                REPLICA="${cfg.backupDir}/${db.name}.db"
                DIR="$(dirname "$DB")"
                mkdir -p "$DIR"

                if [ ! -f "$DB" ] && [ -d "$REPLICA" ]; then
                  echo "[Litestream] Local database $DB missing; performing recovery auto-pull from $REPLICA..."
                  ${pkgs.litestream}/bin/litestream restore -if-replica-exists -config /etc/litestream.yml "$DB" || true
                fi
              '') cfg.databases}
            '';
            ExecStart = "${pkgs.litestream}/bin/litestream replicate -config /etc/litestream.yml -restore-if-db-not-exists";
          };
        };

        # Periodic snapshot sync timer for offline / reboot survival
        nfp-pi-durable-nas-snapshot = mkIf cfg.enableLitestream {
          description = "Periodic SQLite Snapshot Sync to NAS Backup Directory";
          after = [
            "network.target"
            "mnt-NAS1.mount"
          ];
          serviceConfig = {
            Type = "oneshot";
            User = primaryUser;
            Group = "users";
            Slice = "background.slice";
            MemoryHigh = "256M";
            MemoryMax = "512M";

            ExecCondition = reachabilityCheck;

            ExecStart = pkgs.writeShellScript "nas-snapshot-sync" ''
              set -euo pipefail
              TARGET_DIR="${cfg.backupDir}"

              if [ ! -d "$TARGET_DIR" ]; then
                echo "[SnapshotSync] NAS backup directory $TARGET_DIR not accessible, skipping."
                exit 0
              fi

              ${concatMapStringsSep "\n" (db: ''
                DB="${db.path}"
                if [ -f "$DB" ]; then
                  echo "[SnapshotSync] Syncing Litestream force-snapshot for $DB to $TARGET_DIR..."
                  ${pkgs.litestream}/bin/litestream replicate -config /etc/litestream.yml -once -force-snapshot || true
                fi
              '') cfg.databases}
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
