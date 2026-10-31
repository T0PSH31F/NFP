# flake-parts/services/infrastructure/databases.nix
# Persistence for common databases.
# Auto-detects if a database is enabled by ANY service and persists
# its data directory. Explicit flags allow manual override.
{ config, lib, ... }:
with lib;
{
  options.services.databases = {
    postgresql.enable = mkEnableOption "Persist PostgreSQL data. Auto-detected from services.postgresql.enable by default.";
    mysql.enable = mkEnableOption "Persist MySQL data. Auto-detected from services.mysql.enable by default.";
    redis.enable = mkEnableOption "Persist Redis data. Auto-detected from services.redis.servers by default.";
    mongodb.enable = mkEnableOption "Persist MongoDB data. Auto-detected from services.mongodb.enable by default.";
    influxdb.enable = mkEnableOption "Persist InfluxDB data. Auto-detected from services.influxdb.enable by default.";
    victoriametrics.enable = mkEnableOption "Persist VictoriaMetrics data. Auto-detected from services.victoriametrics.enable by default.";
  };

  config = mkIf config.layers.layer-10.system.config.impermanence.enable {
    # Auto-detect enabled databases — mkDefault allows explicit override
    services.databases = {
      postgresql.enable = mkDefault (config.services.postgresql.enable or false);
      mysql.enable = mkDefault (config.services.mysql.enable or false);
      redis.enable = mkDefault ((config.services.redis.servers or { }) != { });
      mongodb.enable = mkDefault (config.services.mongodb.enable or false);
      influxdb.enable = mkDefault (config.services.influxdb.enable or false);
      victoriametrics.enable = mkDefault (config.services.victoriametrics.enable or false);
    };

    environment.persistence."/persist" = {
      directories =
        # postgresql: persisted unconditionally in 10-system/15-filesystem/
        # impermanence.nix (AI-services state consolidation) — keep only here
        # to avoid environment.persistence duplicate-directory assertion.
        (optional config.services.databases.mysql.enable "/var/lib/mysql")
        ++ (optional config.services.databases.redis.enable "/var/lib/redis")
        ++ (optional (lib.hasAttr "nextcloud" (
          config.services.redis.servers or { }
        )) "/var/lib/redis-nextcloud")
        ++ (optional config.services.databases.mongodb.enable "/var/lib/mongodb")
        ++ (optional config.services.databases.influxdb.enable "/var/lib/influxdb")
        ++ (optional config.services.databases.victoriametrics.enable "/var/lib/victoriametrics");
    };
  };
}
