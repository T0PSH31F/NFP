# RomM — ROM Manager & Emulator Web Interface
# Containerized via Podman on port 8098
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.romm;
in
{
  options.layers.layer-20.services.config.romm = {
    enable = mkEnableOption "RomM — Web-based ROM Manager";

    port = mkOption {
      type = types.port;
      default = 8098;
      description = "Port to expose RomM on";
    };

    romsDir = mkOption {
      type = types.str;
      default = "/var/lib/romm/roms";
      description = "Path to ROM files directory";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/romm/data";
      description = "Path to RomM application state and DB";
    };

    remoteRoms = {
      enable = mkEnableOption "Mount remote ROMs library into RomM via rclone FUSE";

      source = mkOption {
        type = types.str;
        default = "gdrive:Games/Games/ROMs";
        description = "rclone remote:path to mount read-only at cfg.romsDir";
      };

      rcloneConfigFile = mkOption {
        type = types.str;
        default = "/persist/home/t0psh31f/.config/rclone/rclone.conf";
        description = "Path to rclone.conf with OAuth credentials for remoteRoms.source";
      };
    };
  };

  config = mkIf cfg.enable {
    nfp.services.romm = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "romm";
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
        category = "vegapunk";
        order = 30;
        title = "RomM";
        subtitle = "Atlas — Retro Memory Station";
        icon = "romm";
        satellite = "atlas";
        metric = {
          mode = "native-api";
          adapter = "romm";
          fields = [
            "roms"
            "platforms"
          ];
        };
      };
    };

    services.mysql = {
      enable = true;
      package = mkDefault pkgs.mariadb;
      settings.mysqld.bind-address = mkDefault "0.0.0.0";
    };

    networking.firewall.interfaces."podman0".allowedTCPPorts = [ 3306 ];

    systemd.services.romm-db-init = {
      description = "Provision MariaDB database and credentials for RomM";
      after = [
        "mysql.service"
      ]
      ++ optional (config.layers.layer-20.services.auth.authentik.enable or false
      ) "postgresql-authentik-setup.service";
      requires = [
        "mysql.service"
      ]
      ++ optional (config.layers.layer-20.services.auth.authentik.enable or false
      ) "postgresql-authentik-setup.service";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.openssl
        config.services.mysql.package
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
                install -d -m 0750 /var/lib/romm
                ENV_FILE="/var/lib/romm/romm.env"
                if [ ! -s "$ENV_FILE" ]; then
                  DB_PW="$(openssl rand -hex 24)"
                  AUTH_KEY="$(openssl rand -hex 32)"
                  umask 077
                  cat > "$ENV_FILE" <<EOF
        DB_PASSWD=$DB_PW
        ROMM_AUTH_SECRET_KEY=$AUTH_KEY
        EOF
                fi
                if [ -r /var/lib/authentik/runtime.env ]; then
                  . /var/lib/authentik/runtime.env
                  if [ -n "''${OIDC_ROMM_SECRET:-}" ]; then
                    grep -v '^OIDC_CLIENT_SECRET=' "$ENV_FILE" > "$ENV_FILE.tmp" || true
                    printf 'OIDC_CLIENT_SECRET=%s\n' "$OIDC_ROMM_SECRET" >> "$ENV_FILE.tmp"
                    chmod 600 "$ENV_FILE.tmp"
                    mv "$ENV_FILE.tmp" "$ENV_FILE"
                  fi
                fi
                set -a
                . "$ENV_FILE"
                set +a
                mariadb -u root <<SQL
        CREATE DATABASE IF NOT EXISTS romm;
        CREATE USER IF NOT EXISTS 'romm'@'%' IDENTIFIED BY '$DB_PASSWD';
        CREATE USER IF NOT EXISTS 'romm'@'localhost' IDENTIFIED BY '$DB_PASSWD';
        ALTER USER 'romm'@'%' IDENTIFIED BY '$DB_PASSWD';
        ALTER USER 'romm'@'localhost' IDENTIFIED BY '$DB_PASSWD';
        GRANT ALL PRIVILEGES ON romm.* TO 'romm'@'%';
        GRANT ALL PRIVILEGES ON romm.* TO 'romm'@'localhost';
        FLUSH PRIVILEGES;
        SQL
      '';
    };

    programs.fuse.userAllowOther = mkIf cfg.remoteRoms.enable true;

    systemd.services.romm-gdrive-roms = mkIf cfg.remoteRoms.enable {
      description = "Mount remote Google Drive ROM library for RomM";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "simple";
        Environment = "PATH=/run/wrappers/bin";
        ExecStartPre = [
          "-/run/wrappers/bin/fusermount3 -uz ${cfg.romsDir}"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.romsDir}"
        ];
        ExecStart = "${pkgs.rclone}/bin/rclone mount ${escapeShellArg cfg.remoteRoms.source} ${escapeShellArg cfg.romsDir} --config ${escapeShellArg cfg.remoteRoms.rcloneConfigFile} --read-only --allow-other --vfs-cache-mode full --vfs-cache-max-size 10G --dir-cache-time 12h";
        ExecStartPost = "${pkgs.bash}/bin/bash -c 'i=0; while [ \"$i\" -lt 30 ]; do ${pkgs.util-linux}/bin/mountpoint -q ${escapeShellArg cfg.romsDir} && exit 0; i=$((i+1)); ${pkgs.coreutils}/bin/sleep 0.5; done; exit 1'";
        ExecStop = "-/run/wrappers/bin/fusermount3 -uz ${cfg.romsDir}";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.podman-romm = {
      after = [ "romm-db-init.service" ] ++ optional cfg.remoteRoms.enable "romm-gdrive-roms.service";
      requires = [ "romm-db-init.service" ] ++ optional cfg.remoteRoms.enable "romm-gdrive-roms.service";
      partOf = optional cfg.remoteRoms.enable "romm-gdrive-roms.service";
    };

    virtualisation.oci-containers.containers.romm = {
      image = "ghcr.io/rommapp/romm:latest";
      autoStart = true;
      ports = [ "${toString cfg.port}:8080" ];
      environment = {
        DB_HOST = "host.containers.internal";
        DB_PORT = "3306";
        DB_NAME = "romm";
        DB_USER = "romm";
      }
      // lib.optionalAttrs (config.layers.layer-20.services.auth.authentik.enable or false) {
        OIDC_ENABLED = "true";
        OIDC_AUTOLOGIN = "true";
        OIDC_PROVIDER = "authentik";
        OIDC_CLIENT_ID = "romm";
        OIDC_CLAIM_ROLES = "groups";
        OIDC_ROLE_ADMIN = "NFP Admins";
        OIDC_REDIRECT_URI = "https://romm.${
          config.layers.meta.publicDomain or "lovelain.duckdns.org"
        }/api/oauth/openid";
        OIDC_SERVER_APPLICATION_URL = "https://${config.layers.layer-20.services.auth.authentik.domain}/application/o/romm/";
      };
      environmentFiles = [ "/var/lib/romm/romm.env" ];
      extraOptions = [
        "--add-host=host.containers.internal:host-gateway"
      ]
      ++ lib.optional (config.layers.layer-20.services.auth.authentik.enable or false
      ) "--add-host=${config.layers.layer-20.services.auth.authentik.domain}:host-gateway";
      volumes = [
        "${cfg.romsDir}:/romm/library/roms${optionalString cfg.remoteRoms.enable ":ro,rslave"}"
        "${cfg.dataDir}:/romm/resources"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ]
    ++ optional (!cfg.remoteRoms.enable) "d ${cfg.romsDir} 0755 root root -";

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [ "/var/lib/romm" ];
        };
  };
}
