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
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
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

    systemd.services.podman-romm = {
      after = [ "romm-db-init.service" ];
      requires = [ "romm-db-init.service" ];
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
      };
      environmentFiles = [ "/var/lib/romm/romm.env" ];
      extraOptions = [ "--add-host=host.containers.internal:host-gateway" ];
      volumes = [
        "${cfg.romsDir}:/romm/roms"
        "${cfg.dataDir}:/romm/resources"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.romsDir} 0755 root root -"
      "d ${cfg.dataDir} 0755 root root -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [ "/var/lib/romm" ];
        };
  };
}
