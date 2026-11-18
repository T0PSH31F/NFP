{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.calibre-web-app = {
    enable = mkEnableOption "Calibre-Web service";

    port = mkOption {
      type = types.int;
      default = 7119;
      description = "Calibre-Web port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/calibre-web";
      description = "Data directory for Calibre-Web";
    };

    libraryPath = mkOption {
      type = types.str;
      default = "/var/lib/calibre";
      description = "Path to Calibre library";
    };

    backupDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional backup destination directory for consolidated Calibre library snapshots";
    };
  };

  config = mkIf config.services.calibre-web-app.enable (
    let
      isExternalPath =
        hasPrefix "/mnt/" config.services.calibre-web-app.libraryPath
        || hasPrefix "/storage/" config.services.calibre-web-app.libraryPath
        || hasPrefix "/data/" config.services.calibre-web-app.libraryPath;
    in
    {
      nfp.services.calibre-web = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = config.services.calibre-web-app.port;
        tailnetName = "calibre-web";
        tls = "headscale";
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            302
          ];
        };
        homepage = {
          enable = true;
          category = "robin";
          order = 15;
          title = "Calibre-Web";
          subtitle = "Ancient Poneglyphs Library";
          icon = "calibre-web";
          metric = {
            mode = "native-api";
            adapter = "calibre-web";
            fields = [
              "books"
              "authors"
            ];
          };
        };
      };

      # Native NixOS Calibre-Web service
      services.calibre-web = {
        enable = true;
        listen.port = config.services.calibre-web-app.port;
        listen.ip = "0.0.0.0";
        dataDir = config.services.calibre-web-app.dataDir;

        options = {
          calibreLibrary = config.services.calibre-web-app.libraryPath;
          enableBookUploading = true;
          enableBookConversion = true;
          reverseProxyAuth = mkIf (config.layers.layer-20.services.auth.authentik.enable or false) {
            enable = true;
            header = "X-Authentik-Username";
          };
        };
      };

      # Create necessary directories (0775 calibre-web:media allows both calibre-web and human/media access)
      users.groups.media = { };

      systemd.tmpfiles.rules = [
        "d ${config.services.calibre-web-app.dataDir} 0755 calibre-web calibre-web -"
        "d ${config.services.calibre-web-app.libraryPath} 0775 calibre-web media -"
      ];

      # Auto-initialize empty metadata.db if missing so service does not crash on pre-start check
      systemd.services.calibre-web.unitConfig = mkIf isExternalPath {
        RequiresMountsFor = [ config.services.calibre-web-app.libraryPath ];
      };

      systemd.services.calibre-web.preStart = lib.mkBefore ''
        if [ -n "${toString config.services.calibre-web-app.libraryPath}" ] && [ ! -f "${config.services.calibre-web-app.libraryPath}/metadata.db" ]; then
          mkdir -p "${config.services.calibre-web-app.libraryPath}"
          ${pkgs.calibre}/bin/calibredb list --library-path "${config.services.calibre-web-app.libraryPath}" >/dev/null 2>&1 || true
          chown -R calibre-web:media "${config.services.calibre-web-app.libraryPath}" || true
        fi
      '';

      # Periodic non-destructive backup of consolidated Calibre Library (metadata.db via sqlite3 + rsync)
      systemd.services.calibre-library-backup = mkIf (config.services.calibre-web-app.backupDir != null) {
        description = "Backup Consolidated Calibre Library & SQLite metadata.db";
        after = [
          "network-online.target"
          "local-fs.target"
        ];
        wants = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = [
          config.services.calibre-web-app.libraryPath
          config.services.calibre-web-app.backupDir
        ];
        serviceConfig = {
          Type = "oneshot";
          Nice = 19;
          IOSchedulingClass = "idle";
          ExecStart = pkgs.writeShellScript "calibre-library-backup" ''
            set -euo pipefail
            SRC="${config.services.calibre-web-app.libraryPath}"
            DST="${config.services.calibre-web-app.backupDir}"
            if [ ! -f "$SRC/metadata.db" ]; then
              echo "[CalibreBackup] Source metadata.db not present at $SRC, skipping."
              exit 0
            fi
            mkdir -p "$DST"
            # Snapshot SQLite locally first so CIFS/SMB targets do not fail with POSIX file-lock errors
            LOCAL_TMP="$(mktemp /tmp/calibre-metadata.XXXXXX.db)"
            trap 'rm -f "$LOCAL_TMP"' EXIT
            ${pkgs.sqlite}/bin/sqlite3 -cmd ".timeout 15000" "$SRC/metadata.db" ".backup '$LOCAL_TMP'"
            cp -f "$LOCAL_TMP" "$DST/metadata.db.tmp"
            mv -f "$DST/metadata.db.tmp" "$DST/metadata.db"
            ${pkgs.rsync}/bin/rsync -rt --modify-window=2 --no-perms --no-owner --no-group --exclude='metadata.db' --exclude='metadata.db.*' "$SRC/" "$DST/"
            echo "[CalibreBackup] Successfully backed up $SRC -> $DST"
          '';
        };
      };

      systemd.timers.calibre-library-backup = mkIf (config.services.calibre-web-app.backupDir != null) {
        description = "Daily Backup of Consolidated Calibre Library";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "03:30";
          Persistent = true;
        };
      };

      systemd.services.calibre-web-user-sync =
        mkIf (config.layers.layer-20.services.auth.authentik.enable or false)
          {
            description = "Sync Authentik VIP/Family/Friend/Admin users & dark theme into Calibre-Web";
            after = [
              "calibre-web.service"
              "postgresql.service"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
                            set -euo pipefail
                            DB="${config.services.calibre-web-app.dataDir}/app.db"
                            [ -f "$DB" ] || exit 0
                            ROWS="$(${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/psql -d authentik -t -A -F $'\t' -c \
                              "SELECT u.username, COALESCE(u.email, u.username), string_agg(g.name, ',') FROM authentik_core_user u JOIN authentik_core_user_ak_groups ug ON u.id=ug.user_id JOIN authentik_core_group g ON g.group_uuid=ug.group_id WHERE u.is_active=true AND u.type='internal' GROUP BY u.username, u.email;")"
                            ROWS="$ROWS" ${pkgs.python3}/bin/python3 - "$DB" <<'PY'
              import os, sqlite3, sys
              conn = sqlite3.connect(sys.argv[1], timeout=15)
              cur = conn.cursor()
              cur.execute(
                  "UPDATE settings SET config_theme = 1, config_calibre_web_title = ? "
                  "WHERE config_theme != 1 OR config_calibre_web_title = ?",
                  ("⌈ＬｏｖｅＬａｉｎ　Ａｒｃｈｉｖｅ⌋", "Calibre-Web"),
              )
              for line in os.environ.get("ROWS", "").splitlines():
                  if not line.strip():
                      continue
                  uname, uemail, ugroups = line.split("\t")
                  groups = set(ugroups.split(","))
                  if "NFP Admins" in groups or "authentik Admins" in groups:
                      role, denied = 479, ""
                  elif "VIP" in groups:
                      role, denied = 338, ""
                  else:
                      role, denied = 338, "VIP"
                  cur.execute(
                      "INSERT OR IGNORE INTO user (name, email, role, password, kindle_mail, locale, sidebar_view, default_language, denied_tags, allowed_tags, denied_column_value, allowed_column_value, view_settings) "
                      "VALUES (?, ?, ?, ?, ?, ?, 262143, ?, ?, ?, ?, ?, ?)",
                      (uname, uemail, role, "", "", "en", "all", denied, "", "", "", "{}"),
                  )
                  cur.execute(
                      "UPDATE user SET role = ?, denied_tags = ?, email = COALESCE(NULLIF(?, ?), email) WHERE name = ?",
                      (role, denied, uemail, "", uname),
                  )
              conn.commit()
              PY
            '';
          };

      systemd.timers.calibre-web-user-sync =
        mkIf (config.layers.layer-20.services.auth.authentik.enable or false)
          {
            description = "Periodic Authentik -> Calibre-Web VIP & User Sync";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "1m";
              OnUnitActiveSec = "10m";
            };
          };

      # Firewall
      networking.firewall.allowedTCPPorts = [ config.services.calibre-web-app.port ];

      # Ensure data is persisted (skip libraryPath if already stored on external/secondary mount)
      environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
        directories = [
          {
            directory = config.services.calibre-web-app.dataDir;
            user = "calibre-web";
            group = "calibre-web";
            mode = "0755";
          }
        ]
        ++ optionals (!isExternalPath) [
          {
            directory = config.services.calibre-web-app.libraryPath;
            user = "calibre-web";
            group = "calibre-web";
            mode = "0755";
          }
        ];
      };
    }
  );
}
