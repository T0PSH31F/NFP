# Sops secrets for Polyfloor AI company OS
# Maps secrets from the central secrets file to Polyfloor's environment file.
# Env var names match the upstream config.py Settings class (env_prefix POLYFLOOR_).
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config =
    let
      polyfloorCfg = config.services.polyfloor;
      secretsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;
      postgresSecretsFile = ../../00-cyberia/03-treasure/secrets/postgres.yaml;
    in
    mkIf polyfloorCfg.enable {
      # ── Polyfloor secrets ─────────────────────────────────────────────
      sops.secrets = {
        polyfloor_api_token = {
          sopsFile = secretsFile;
          owner = "polyfloor";
          group = "polyfloor";
          mode = "0400";
        };
        # Kong consumer API key for Polyfloor (authenticate to Kong on 8090)
        kong_key_polyfloor = {
          sopsFile = secretsFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };
        postgres-password = {
          sopsFile = postgresSecretsFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      # ── Environment file template for Polyfloor ───────────────────────
      # The upstream module already sets POLYFLOOR_HOST, POLYFLOOR_PORT,
      # POLYFLOOR_DATA_DIR, POLYFLOOR_ROUTER_ENDPOINT, POLYFLOOR_DEFAULT_HR_MODEL,
      # and POLYFLOOR_DATABASE_URL. We only override/extend what we need:
      #   - POLYFLOOR_DATABASE_URL → postgres DSN (overrides SQLite default)
      #   - POLYFLOOR_API_TOKEN_FILE → platform bearer token for Polyfloor's own auth
      #   - POLYFLOOR_ROUTER_API_KEY_FILE → Kong consumer key for LLM router auth
      sops.templates."polyfloor-env" = {
        content = ''
          # Database — PostgreSQL (overrides upstream SQLite default)
          POLYFLOOR_DATABASE_URL=postgresql://polyfloor:${config.sops.placeholder.postgres-password}@localhost:5432/polyfloor

          # Polyfloor platform API token (read by config.py as api_token_file)
          POLYFLOOR_API_TOKEN_FILE=${config.sops.placeholder.polyfloor_api_token}

          # Kong consumer key for LLM router auth (read by config.py as router_api_key_file)
          POLYFLOOR_ROUTER_API_KEY_FILE=${config.sops.placeholder.kong_key_polyfloor}

          # Policy
          POLYFLOOR_ALLOW_PAID_MODELS=false
          POLYFLOOR_PAID_DAILY_BUDGET_USD=0
        '';
        owner = "polyfloor";
        group = "polyfloor";
        mode = "0400";
      };
    };
}
