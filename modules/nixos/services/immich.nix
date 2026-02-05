{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.immich-server = {
    enable = mkEnableOption "Immich photo and video management server";

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Host address to bind Immich";
    };

    port = mkOption {
      type = types.int;
      default = 2283;
      description = "Port for Immich web interface";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/immich";
      description = "Data directory for Immich uploads and library";
    };

    uploadLocation = mkOption {
      type = types.str;
      default = "/var/lib/immich/upload";
      description = "Upload location for photos and videos";
    };
  };

  config = mkIf config.services.immich-server.enable {
    # Native NixOS Immich service
    services.immich = {
      enable = true;
      host = config.services.immich-server.host;
      port = config.services.immich-server.port;
      openFirewall = true;

      # Enable built-in Redis
      redis.enable = true;

      # Database configuration
      database = {
        createDB = true;
        name = "immich";
        user = "immich";
      };
    };

    # Media location via environment
    services.immich.environment = {
      UPLOAD_LOCATION = config.services.immich-server.uploadLocation;
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${config.services.immich-server.dataDir} 0755 immich immich -"
      "d ${config.services.immich-server.uploadLocation} 0755 immich immich -"
    ];

    # Ensure Immich data is persisted
    environment.persistence."/persist" = mkIf (config.system-config.impermanence.enable or false) {
      directories = [
        {
          directory = config.services.immich-server.dataDir;
          user = "immich";
          group = "immich";
          mode = "0755";
        }
        {
          directory = config.services.immich-server.uploadLocation;
          user = "immich";
          group = "immich";
          mode = "0755";
        }
      ];
    };
  };
}
