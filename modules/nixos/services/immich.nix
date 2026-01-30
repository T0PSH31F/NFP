{
  config,
  lib,
  pkgs,
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

    enableMachineLearning = mkOption {
      type = types.bool;
      default = true;
      description = "Enable machine learning features (face detection, object recognition)";
    };

    postgresPassword = mkOption {
      type = types.str;
      default = "immich";
      description = "PostgreSQL password for Immich database";
    };
  };

  config = mkIf config.services.immich-server.enable {
    # Immich requires Docker compose, so we use OCI containers
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    # Immich Server
    virtualisation.oci-containers.containers.immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      ports = [ "${toString config.services.immich-server.port}:2283" ];
      volumes = [
        "${config.services.immich-server.uploadLocation}:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_PASSWORD = config.services.immich-server.postgresPassword;
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "immich-redis";
        UPLOAD_LOCATION = config.services.immich-server.uploadLocation;
      };
      dependsOn = [
        "immich-postgres"
        "immich-redis"
      ];
      extraOptions = [
        "--network=immich-network"
      ];
    };

    # Immich Machine Learning (optional)
    virtualisation.oci-containers.containers.immich-machine-learning =
      mkIf config.services.immich-server.enableMachineLearning
        {
          image = "ghcr.io/immich-app/immich-machine-learning:release";
          volumes = [
            "/var/lib/immich/model-cache:/cache"
          ];
          environment = {
            DB_HOSTNAME = "immich-postgres";
            DB_USERNAME = "immich";
            DB_PASSWORD = config.services.immich-server.postgresPassword;
            DB_DATABASE_NAME = "immich";
            REDIS_HOSTNAME = "immich-redis";
          };
          dependsOn = [
            "immich-postgres"
            "immich-redis"
          ];
          extraOptions = [
            "--network=immich-network"
          ];
        };

    # PostgreSQL for Immich
    virtualisation.oci-containers.containers.immich-postgres = {
      image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
      volumes = [
        "/var/lib/immich/postgres:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_PASSWORD = config.services.immich-server.postgresPassword;
        POSTGRES_DB = "immich";
      };
      extraOptions = [
        "--network=immich-network"
      ];
    };

    # Redis for Immich
    virtualisation.oci-containers.containers.immich-redis = {
      image = "redis:6.2-alpine";
      extraOptions = [
        "--network=immich-network"
      ];
    };

    # Create Docker network for Immich
    systemd.services.init-immich-network = {
      description = "Create Immich Docker network";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker network inspect immich-network >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create immich-network
      '';
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${config.services.immich-server.dataDir} 0755 root root -"
      "d ${config.services.immich-server.uploadLocation} 0755 root root -"
      "d /var/lib/immich/postgres 0755 root root -"
      "d /var/lib/immich/model-cache 0755 root root -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services.immich-server.port ];

    # Ensure Immich data is persisted
    environment.persistence."/persist" = mkIf (config.system-config.impermanence.enable or false) {
      directories = [
        config.services.immich-server.dataDir
      ];
    };
  };
}
