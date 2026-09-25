# Tier: 78-llm-routers
# Module: freellmapi.nix
# Purpose: FreeLLMAPI free provider aggregation router with OpenAI-compatible endpoint.
# Option Path: services.ai-services.freellmapi
# Enabling Host Tags: ai-router, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.ai-services.freellmapi = {
    enable = lib.mkEnableOption "FreeLLMAPI — free-tier LLM router with OpenAI-compatible endpoint";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "HTTP API port";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/freellmapi";
      description = "Data directory for SQLite DB and config";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to env file with ENCRYPTION_KEY, provider API keys, etc.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to declarative JSON config (see FREEAPI_CONFIG_PATH)";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables";
    };
  };

  config =
    let
      cfg = config.services.ai-services.freellmapi;

      # FreeLLMAPI package (Node.js workspace — server + dashboard)
      freellmapiPkg = pkgs.buildNpmPackage {
        pname = "freellmapi";
        version = "latest";
        src = pkgs.fetchFromGitHub {
          owner = "tashfeenahmed";
          repo = "freellmapi";
          rev = "93afdca5843d945852998adc7ecbf4289cb9fa71"; # pinned 2026-08-01
          hash = "sha256-te1DljLlhRfT0mWu4EB3pTKB8PkZecHHffX/kTwJlJY=";
        };

        npmDepsHash = "sha256-7W55aNLi6BlWg8wksG1a+jmWmAdJ3DRW8tq5coFH0H8=";

        # Node.js >= 20.18 required
        nativeBuildInputs = [
          pkgs.nodejs_24
          pkgs.python3
          pkgs.gcc
          pkgs.pkg-config
        ];
        # better-sqlite3 native module needs kernel headers
        buildInputs = [ pkgs.linuxHeaders ];

        # Build server + client
        buildPhase = ''
          runHook preBuild
          npm run build
          # better-sqlite3's prebuild-install downloads binaries compiled for
          # newer V8 than Node.js 22 exports at runtime.  Remove cached
          # prebuilds so rebuild falls back to source compilation against
          # the local Node.js headers.
          rm -rf node_modules/better-sqlite3/prebuilds node_modules/better-sqlite3/build
          npm rebuild better-sqlite3
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/freellmapi
          cp -r server/dist $out/share/freellmapi/
          cp -r client/dist $out/share/freellmapi/public
          # npm workspaces hoist shared deps to root node_modules.
          # Copy root first; remove dangling workspace symlinks
          # (@freellmapi/shared → ../../shared etc. that don't resolve
          # in the store path); then merge server-specific overrides.
          cp -r node_modules $out/share/freellmapi/
          find $out/share/freellmapi/node_modules -type l ! -exec test -e {} \; -delete 2>/dev/null || true
          if [ -d server/node_modules ]; then
            cp -rn server/node_modules/* $out/share/freellmapi/node_modules/
          fi
          cp server/package.json $out/share/freellmapi/
          runHook postInstall
        '';

        meta = {
          description = "One OpenAI-compatible endpoint aggregating 28 free LLM providers";
          homepage = "https://github.com/tashfeenahmed/freellmapi";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux;
        };
      };
    in
    lib.mkMerge [
      {
        nfp.services.freellmapi = {
          enable = config.services.ai-services.freellmapi.enable;
          host = config.networking.hostName;
          port = 3001;
          homepage = {
            enable = true;
            category = "agents";
            order = 45;
            title = "FreeLLMAPI";
            subtitle = "Free Provider Aggregator";
            icon = "freellmapi";
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
      (lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 freellmapi freellmapi -"
        ];

        users.users.freellmapi = {
          isSystemUser = true;
          group = "freellmapi";
          description = "FreeLLMAPI service user";
        };
        users.groups.freellmapi = { };

        systemd.services.freellmapi = {
          description = "FreeLLMAPI — free-tier LLM router";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            PORT = toString cfg.port;
            HOST = cfg.host;
            FREEAPI_DB_PATH = "${cfg.dataDir}/freeapi.db";
            NODE_ENV = "production";
          }
          // lib.optionalAttrs (cfg.configFile != null) {
            FREEAPI_CONFIG_PATH = cfg.configFile;
          }
          // cfg.extraEnv;

          serviceConfig = {
            ExecStart = "${pkgs.nodejs_24}/bin/node ${freellmapiPkg}/share/freellmapi/dist/index.js";
            Restart = "on-failure";
            RestartSec = 5;
            User = "freellmapi";
            Group = "freellmapi";
            WorkingDirectory = "${freellmapiPkg}/share/freellmapi";
            EnvironmentFile =
              if cfg.environmentFile != null then
                cfg.environmentFile
              else
                config.sops.templates."freellmapi-env".path;
            # Hardening
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ cfg.dataDir ];
          };
        };

        # Impermanence persistence support
        environment.persistence."/persist" =
          lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              directories = [
                {
                  directory = cfg.dataDir;
                  user = "freellmapi";
                  group = "freellmapi";
                  mode = "0750";
                }
              ];
            };
      })
    ];
}
