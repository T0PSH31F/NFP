# Tier: 73-memory
# Module: langfuse.nix
# Purpose: Langfuse LLM observability, prompt management, and trace telemetry suite.
# Option Path: services.infrastructure.langfuse
# Enabling Host Tags: pkb-node, homelab
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.infrastructure.langfuse = {
    enable = lib.mkEnableOption "Langfuse Observability Platform via OCI Container";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3005;
      description = "Port for Langfuse dashboard";
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "postgresql://postgres@localhost/langfuse?host=/run/postgresql";
      description = "PostgreSQL DB connection string for Langfuse runtime";
    };
  };

  config =
    let
      cfg = config.services.infrastructure.langfuse;
    in
    lib.mkMerge [
      {
        nfp.services.langfuse = {
          enable = config.services.infrastructure.langfuse.enable;
          host = config.networking.hostName;
          bind = "127.0.0.1";
          port = 3005;
          tailnetName = "langfuse";
          tls = "headscale";
          healthcheck = {
            enable = true;
            path = "/api/public/health";
            expectedStatus = [ 200 ];
          };
          homepage = {
            enable = true;
            category = "chopper";
            order = 35;
            title = "Langfuse";
            subtitle = "LLM Observability & Traces";
            icon = "langfuse";
            metric = {
              mode = "native-api";
              adapter = "langfuse";
              fields = [
                "traces"
                "tokens"
              ];
            };
          };
        };
      }
      (lib.mkIf cfg.enable {
        clan.core.vars.generators.langfuse = {
          files."langfuse.env" = {
            secret = true;
          };
          script = ''
            NEXTAUTH=$(${pkgs.openssl}/bin/openssl rand -base64 32)
            SALT=$(${pkgs.openssl}/bin/openssl rand -hex 16)
            echo "NEXTAUTH_SECRET=$NEXTAUTH" > "$out/langfuse.env"
            echo "SALT=$SALT" >> "$out/langfuse.env"
          '';
        };

        # Auto-provision the langfuse DB in Postgres
        clan.core.postgresql = {
          enable = true;
          databases.langfuse.create.enable = true;
        };

        virtualisation.oci-containers.containers.langfuse = {
          image = "ghcr.io/langfuse/langfuse:2";
          ports = [ "${toString cfg.port}:3000" ];
          environmentFiles = [
            config.clan.core.vars.generators.langfuse.files."langfuse.env".path
          ];
          environment = {
            PORT = toString cfg.port;
            HOSTNAME = "127.0.0.1";
            NODE_ENV = "production";
            NEXTAUTH_URL = "http://127.0.0.1:${toString cfg.port}";
            NEXT_PUBLIC_SIGN_UP_DISABLED = "false";
            NEXT_PUBLIC_LANGFUSE_CLOUD_EDITION = "local";
            TELEMETRY_ENABLED = "false";
            DATABASE_URL = cfg.databaseUrl;
          };
          volumes = [
            "/run/postgresql:/run/postgresql"
          ];
          extraOptions = [
            "--network=host" # Access local postgres easily
          ];
        };

        # Open firewall for the local port
        networking.firewall.allowedTCPPorts = [ cfg.port ];
      })
    ];
}
