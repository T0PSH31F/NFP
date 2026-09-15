# Tier: 73-memory
# Module: honcho.nix
# Purpose: Honcho user profile & memory state engine (containerized API, deriver, Redis).
# Option Path: services.honcho
# Enabling Host Tags: pkb-node, ai-agent, homelab
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.honcho = {
    enable = mkEnableOption "Honcho — self-hosted cross-agent memory";

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port for Honcho API server";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/honcho";
      description = "Data directory for Honcho";
    };

    databaseUrl = mkOption {
      type = types.str;
      default = "postgresql://honcho:***@host.containers.internal:5432/honcho";
      description = "PostgreSQL connection string (used when databaseUrlFile is null)";
    };

    databaseUrlFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing 'DATABASE_URL=<url>' (sops template). Takes precedence over databaseUrl.";
    };

    llmProvider = mkOption {
      type = types.str;
      default = "openai";
      description = "LLM provider for memory extraction (openai, anthropic, etc.)";
    };

    llmModel = mkOption {
      type = types.str;
      default = "gpt-5.4-mini";
      description = "LLM model for memory extraction";
    };

    llmBaseUrl = mkOption {
      type = types.str;
      default = "";
      description = "Custom LLM base URL (for OpenRouter, local models, etc.)";
    };

    enableDeriver = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the deriver background worker for memory processing";
    };
  };

  config =
    let
      cfg = config.services.honcho;
    in
    mkIf cfg.enable {
      # PostgreSQL with pgvector
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "honcho" ];
        ensureUsers = [
          {
            name = "honcho";
            ensureDBOwnership = true;
          }
        ];
        extensions = ps: with ps; [ pgvector ];
        initialScript = pkgs.writeText "honcho-init" ''
          \c honcho
          CREATE EXTENSION IF NOT EXISTS vector;
        '';
      };

      # Honcho API server (containerized)
      virtualisation.oci-containers.containers.honcho-api = {
        image = "ghcr.io/plastic-labs/honcho:latest"; # nicepkg/honcho on ghcr no longer exists (403)
        ports = [ "127.0.0.1:${toString cfg.port}:8000" ];
        environment = {
          CACHE_ENABLED = "true";
          CACHE_URL = "redis://host.containers.internal:6379";
          AUTH_USE_AUTH = "false";
          METRICS_ENABLED = "true";
        }
        // optionalAttrs (cfg.databaseUrlFile == null) {
          DATABASE_URL = cfg.databaseUrl;
        }
        // optionalAttrs (cfg.llmBaseUrl != "") {
          DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llmBaseUrl;
          DIALECTIC_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llmBaseUrl;
          SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llmBaseUrl;
        };
        # When databaseUrlFile is set, inject DATABASE_URL at runtime via
        # podman --env-file (sops template renders KEY=value content).
        extraOptions = mkIf (cfg.databaseUrlFile != null) [
          "--env-file=${cfg.databaseUrlFile}"
        ];
        volumes = [
          "${cfg.dataDir}:/app/data"
        ];
        dependsOn = [ "honcho-redis" ];
        autoStart = true;
      };

      # Honcho deriver (background worker for memory processing)
      virtualisation.oci-containers.containers.honcho-deriver = mkIf cfg.enableDeriver {
        image = "ghcr.io/plastic-labs/honcho:latest"; # nicepkg/honcho on ghcr no longer exists (403)
        cmd = [
          "uv"
          "run"
          "python"
          "-m"
          "honcho.deriver"
        ];
        environment = {
          DATABASE_URL = cfg.databaseUrl;
          CACHE_ENABLED = "true";
          CACHE_URL = "redis://host.containers.internal:6379";
        }
        // optionalAttrs (cfg.llmBaseUrl != "") {
          DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llmBaseUrl;
        };
        volumes = [
          "${cfg.dataDir}:/app/data"
        ];
        dependsOn = [ "honcho-redis" ];
        autoStart = true;
      };

      # Redis for caching
      virtualisation.oci-containers.containers.honcho-redis = {
        image = "docker.io/library/redis:7-alpine";
        ports = [ "127.0.0.1:6379:6379" ];
        volumes = [
          "${cfg.dataDir}/redis:/data"
        ];
        autoStart = true;
      };

      # Data directory
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 root root -"
        "d ${cfg.dataDir}/redis 0755 root root -"
      ];

      # Impermanence persistence
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              cfg.dataDir
            ];
          };

      # Open firewall port
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    };
}
