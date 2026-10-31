{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.ai-services.postgresql;
in
{
  options.services.ai-services.postgresql = {
    enable = mkEnableOption "PostgreSQL with pgvector and lantern extensions";

    port = mkOption {
      type = types.int;
      default = 5432;
      description = "PostgreSQL port";
    };
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      settings.port = cfg.port;
      enableTCPIP = true;

      extensions = with pkgs.postgresql_16.pkgs; [
        pgvector
        lantern
      ];

      settings = {
        shared_preload_libraries = "vector";
        max_connections = 100;
        shared_buffers = "256MB";
      };

      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        # peer auth for unix-socket connections (postgres OS user only)
        local   all             all                                     peer
        # trusted loopback TCP connections for local agent container databases
        host    langfuse        all             127.0.0.1/32            trust
        host    langfuse        all             ::1/128                 trust
        host    paperclip       all             127.0.0.1/32            trust
        host    paperclip       all             ::1/128                 trust
        # scram-sha-256 for loopback TCP connections (services using a password)
        host    all             all             127.0.0.1/32            scram-sha-256
        host    all             all             ::1/128                 scram-sha-256
      '';

      ensureDatabases = [
        "ai"
        "vectordb"
      ];
      ensureUsers = [
        {
          name = "ai";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.postgresql-extensions = {
      description = "Ensure Postgres extensions for vectordb";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      serviceConfig = {
        User = "postgres";
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "setup-pg-extensions" ''
          until ${pkgs.postgresql_16}/bin/pg_isready -q; do
            sleep 1
          done
          echo "Creating extensions in vectordb..."
          ${pkgs.postgresql_16}/bin/psql -d vectordb -c "CREATE EXTENSION IF NOT EXISTS vector;"
          ${pkgs.postgresql_16}/bin/psql -d vectordb -c "CREATE EXTENSION IF NOT EXISTS lantern;"
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
