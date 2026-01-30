{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.nextcloud-server = {
    enable = mkEnableOption "Nextcloud server";

    hostName = mkOption {
      type = types.str;
      default = "cloud.local";
      description = "Hostname for Nextcloud";
    };

    adminUser = mkOption {
      type = types.str;
      default = "admin";
      description = "Admin username";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/nextcloud";
      description = "Data directory for Nextcloud";
    };
  };

  config = mkIf config.services.nextcloud-server.enable {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;
      hostName = config.services.nextcloud-server.hostName;

      config = {
        adminuser = config.services.nextcloud-server.adminUser;
        adminpassFile = "/etc/nextcloud-admin-pass";

        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbuser = "nextcloud";
      };

      database.createLocally = true;

      configureRedis = true;

      maxUploadSize = "16G";

      https = true;

      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
      };
    };

    # PostgreSQL for Nextcloud
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          ensureDBOwnership = true;
        }
      ];
    };

    # Redis for caching
    services.redis.servers.nextcloud = {
      enable = true;
      port = 6379;
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    # Ensure Nextcloud and DB are persisted
    environment.persistence."/persist" = mkIf (config.system-config.impermanence.enable or false) {
      directories = [
        config.services.nextcloud-server.dataDir
        # "/var/lib/postgresql"
        "/var/lib/redis-nextcloud"
      ];
    };
  };
}
