# Tier: 78-llm-routers
# Module: freellmpool.nix
# Purpose: FreeLLMPool connection pool manager maintaining healthy provider sockets.
# Option Path: services.ai-services.freellmpool
# Enabling Host Tags: ai-router, homelab
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services.freellmpool = {
    enable = mkEnableOption "freellmpool — free-tier LLM pool";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "HTTP API port";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/freellmpool";
      description = "Data directory for usage tracking state";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to env file with provider API keys (GROQ_API_KEY, etc.)";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables";
    };
  };

  config =
    let
      cfg = config.services.ai-services.freellmpool;

      freellmpoolPkg = pkgs.python3Packages.buildPythonApplication {
        pname = "freellmpool";
        version = "0.11.4";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "0xzr";
          repo = "freellmpool";
          rev = "172b1bb6759a1c08cb9d9f7d4e247ca05b34126c";
          hash = "sha256-yMTOdG6GV6q5FxJDmDC1D9SJM+YuqotRH21BpEVY8X0=";
        };

        build-system = [ pkgs.python3Packages.hatchling ];

        dependencies = [ pkgs.python3Packages.httpx ];

        meta = {
          description = "Free LLM API pool — 24 providers, 222 routes, keyless start";
          homepage = "https://github.com/0xzr/freellmpool";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux;
          mainProgram = "freellmpool";
        };
      };
    in
    mkMerge [
      {
        nfp.services.freellmpool = {
          enable = config.services.ai-services.freellmpool.enable;
          host = "nami";
          port = 8080;
          homepage = {
            enable = true;
            category = "agents";
            order = 46;
            title = "FreeLLMPool";
            subtitle = "Provider Socket Pool";
            icon = "freellmpool";
            metric = {
              mode = "health-only";
            };
          };
          healthcheck = {
            enable = true;
            path = "/";
            expectedStatus = 200;
          };
        };
      }
      (mkIf cfg.enable {
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 freellmpool freellmpool -"
        ];

        users.users.freellmpool = {
          isSystemUser = true;
          group = "freellmpool";
          description = "freellmpool service user";
        };
        users.groups.freellmpool = { };

        environment.persistence."/persist" =
          mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              directories = [
                {
                  directory = cfg.dataDir;
                  user = "freellmpool";
                  group = "freellmpool";
                  mode = "0750";
                }
              ];
            };

        systemd.services.freellmpool = {
          description = "freellmpool — free-tier LLM pool";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            FREELLMPOOL_DATA_DIR = cfg.dataDir;
          }
          // cfg.extraEnv;

          serviceConfig = {
            ExecStart = "${freellmpoolPkg}/bin/freellmpool proxy --host ${cfg.host} --port ${toString cfg.port}";
            Restart = "on-failure";
            RestartSec = 5;
            User = "freellmpool";
            Group = "freellmpool";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ cfg.dataDir ];
          };
        };
      })
    ];
}
