# Tier: 20-services / 25-data
# Module: storage-organizer.nix
# Purpose: Periodic fleet file mover & organizer consolidating /Downloads, /Documents,
#          /Videos, /Photos, /Pictures, and /Games across all machines onto luffy:/storage.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.data.storage-organizer;
  user = config.layers.meta.primaryUser or "t0psh31f";
  categoryDirs = [
    {
      name = "Downloads";
      paths = [
        "/home/${user}/Downloads"
        "/Downloads"
      ];
    }
    {
      name = "Documents";
      paths = [
        "/home/${user}/Documents"
        "/Documents"
      ];
    }
    {
      name = "Videos";
      paths = [
        "/home/${user}/Videos"
        "/Videos"
      ];
    }
    {
      name = "Pictures";
      paths = [ "/home/${user}/Pictures" ];
    }
    {
      name = "Photos";
      paths = [
        "/home/${user}/Photos"
        "/Photos"
      ];
    }
    {
      name = "Games";
      paths = [
        "/home/${user}/Games"
        "/Games"
      ];
    }
  ];
  flatSourceDirs = concatMap (c: c.paths) categoryDirs;

  serverRunner = pkgs.writeShellScriptBin "storage-organize" ''
    exec ${pkgs.util-linux}/bin/flock -n /run/storage-organizer.lock \
      ${pkgs.python3}/bin/python3 ${./storage_organizer.py} \
      --storage-root ${escapeShellArg cfg.storageRoot} \
      --incoming-root ${escapeShellArg "${cfg.storageRoot}/Shared/incoming"} \
      --min-age-seconds ${toString (cfg.minAgeMinutes * 60)} \
      --owner-user ${escapeShellArg user} \
      --watch-dirs ${escapeShellArgs flatSourceDirs} \
      "$@"
  '';

  clientSyncScript = pkgs.writeShellScript "storage-fleet-sync" ''
    set -euo pipefail
    HOST_NAME="${config.networking.hostName}"
    TARGET="${cfg.targetHost}"
    REMOTE_BASE="${cfg.storageRoot}/Shared/incoming/$HOST_NAME"
    SSH_CMD="${pkgs.openssh}/bin/ssh -i /etc/ssh/ssh_host_ed25519_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=8"

    if ! $SSH_CMD "$TARGET" "mkdir -p '$REMOTE_BASE' && touch '$REMOTE_BASE/.syncing'"; then
      echo "luffy unreachable over Tailnet; skipping fleet storage sync." >&2
      exit 0
    fi
    trap "$SSH_CMD \"$TARGET\" \"rm -f '$REMOTE_BASE/.syncing'\" || true" EXIT

    sync_dir() {
      local cat="$1"
      local src="$2"
      [ -d "$src" ] || return 0

      local file_list
      file_list="$(mktemp)"
      (
        cd "$src"
        ${pkgs.findutils}/bin/find . \
          \( -type d \( -name '.*' -o -name 'Syncthing' -o -exec ${pkgs.coreutils}/bin/test -e '{}/.stfolder' \; -o -exec ${pkgs.coreutils}/bin/test -e '{}/.git' \; \) \) -prune -o \
          -type f -mmin +${toString cfg.minAgeMinutes} \
          ! -name '.*' ! -name '*.part' ! -name '*.crdownload' \
          ! -name '*.aria2' ! -name '*.!qB' ! -name '*.tmp' \
          ! -name 'Thumbs.db' ! -name 'desktop.ini' \
          -print | sed 's|^\./||' > "$file_list"
      )

      if [ -s "$file_list" ]; then
        $SSH_CMD "$TARGET" "mkdir -p '$REMOTE_BASE/$cat' && chown ${user}:users '$REMOTE_BASE/$cat'"
        ${pkgs.rsync}/bin/rsync -a --remove-source-files \
          --files-from="$file_list" \
          --chown=${user}:users \
          -e "$SSH_CMD" \
          "$src/" "$TARGET:$REMOTE_BASE/$cat/"
        ${pkgs.findutils}/bin/find "$src" -mindepth 1 -type d -empty -delete 2>/dev/null || true
      fi
      rm -f "$file_list"
    }

    ${concatMapStringsSep "\n" (
      c: concatMapStringsSep "\n" (p: "sync_dir \"${c.name}\" \"${p}\"") c.paths
    ) categoryDirs}
  '';
in
{
  options.layers.layer-20.services.data.storage-organizer = {
    enable = mkEnableOption "Periodic fleet file mover and organizer into luffy:/storage";

    mode = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      default = "client";
      description = "server runs the /storage organizer locally; client pushes staged folders to luffy.";
    };

    storageRoot = mkOption {
      type = types.str;
      default = "/storage";
      description = "Root path of centralized multi-drive Btrfs storage on luffy.";
    };

    targetHost = mkOption {
      type = types.str;
      default = "root@100.64.0.3";
      description = "Tailnet SSH target for luffy storage server.";
    };

    interval = mkOption {
      type = types.str;
      default = "*:0/15";
      description = "Systemd OnCalendar schedule (default: every 15 minutes).";
    };

    minAgeMinutes = mkOption {
      type = types.int;
      default = 5;
      description = "Minimum file modification age in minutes before relocation.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.mode == "server") {
      environment.systemPackages = [ serverRunner ];

      systemd.tmpfiles.rules = [
        "d ${cfg.storageRoot}/Pictures 0775 ${user} users -"
        "d ${cfg.storageRoot}/Games/PC 0775 ${user} users -"
        "d ${cfg.storageRoot}/Games/Emulators 0775 ${user} users -"
        "d ${cfg.storageRoot}/ROMs/roms 0775 ${user} media -"
        "d ${cfg.storageRoot}/Calibre/auto_add 0775 calibre-web media -"
        "d ${cfg.storageRoot}/Media/home_videos 0775 root media -"
        "d ${cfg.storageRoot}/Media/library/movies 0775 root media -"
        "d ${cfg.storageRoot}/Media/library/shows 0775 root media -"
        "d ${cfg.storageRoot}/Media/library/music 0775 root media -"
        "d ${cfg.storageRoot}/Media/library/books 0775 root media -"
        "d ${cfg.storageRoot}/Documents/Guides_and_Tutorials 0775 ${user} users -"
        "d ${cfg.storageRoot}/Documents/Development 0775 ${user} users -"
        "d ${cfg.storageRoot}/Documents/Spreadsheets 0775 ${user} users -"
        "d ${cfg.storageRoot}/Documents/Databases_and_Wallets 0775 ${user} users -"
        "d ${cfg.storageRoot}/Documents/Software 0775 ${user} users -"
        "d ${cfg.storageRoot}/Documents/Archives 0775 ${user} users -"
        "d ${cfg.storageRoot}/Backups/OS_Images 0775 root users -"
        "d ${cfg.storageRoot}/Backups/archives 0775 root users -"
        "d ${cfg.storageRoot}/Misc 0775 ${user} users -"
        "d ${cfg.storageRoot}/Shared/incoming 0775 ${user} users -"
      ];

      systemd.services.storage-organizer = {
        description = "Organize local and fleet-incoming media, books, docs, photos, and games under ${cfg.storageRoot}";
        after = [ "local-fs.target" ];
        unitConfig.RequiresMountsFor = [ cfg.storageRoot ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${serverRunner}/bin/storage-organize";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      systemd.timers.storage-organizer = {
        description = "Periodic /storage Organizer Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.interval;
          RandomizedDelaySec = "30s";
          Persistent = true;
        };
      };
    })

    (mkIf (cfg.mode == "client") {
      systemd.services.storage-fleet-sync = {
        description = "Move aged /Downloads, /Documents, /Videos, /Photos, /Games to luffy:/storage/Shared/incoming";
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/flock -n /run/storage-fleet-sync.lock ${clientSyncScript}";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      systemd.timers.storage-fleet-sync = {
        description = "Periodic Fleet Storage Consolidation Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.interval;
          RandomizedDelaySec = "45s";
          Persistent = true;
        };
      };
    })
  ]);
}
