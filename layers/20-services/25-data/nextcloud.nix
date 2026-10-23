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

    adminPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the file containing the Nextcloud admin password.
        By default, this is automatically generated using a Clan vars generator.
      '';
    };
  };

  config = mkIf config.services.nextcloud-server.enable {
    clan.core.vars.generators.nextcloud = {
      files."admin-password" = {
        secret = true;
        owner = "nextcloud";
        group = "nextcloud";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 18 | tr -d '\n' > "$out/admin-password"
      '';
    };

    services = {
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;
        hostName = config.services.nextcloud-server.hostName;

        config = {
          adminuser = config.services.nextcloud-server.adminUser;
          adminpassFile =
            if config.services.nextcloud-server.adminPasswordFile != null then
              config.services.nextcloud-server.adminPasswordFile
            else
              config.clan.core.vars.generators.nextcloud.files."admin-password".path;

          dbtype = "pgsql";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          dbuser = "nextcloud";
        };

        database.createLocally = true;

        configureRedis = true;

        maxUploadSize = "16G";

        https = false;

        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
        };

        settings = {
          overwriteprotocol = "https";
        };
      };

      # PostgreSQL for Nextcloud
      postgresql = {
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
      redis.servers.nextcloud = {
        enable = true;
        port = 6380;
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    # Ensure Nextcloud and DB are persisted
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            config.services.nextcloud-server.dataDir
          ];
        };
  };
}
