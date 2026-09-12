# Tier: 78-llm-routers
# Module: omniroute.nix
# Purpose: OmniRoute Next.js OCI container LLM routing and visual management app.
# Option Path: services.ai-services.omniroute
# Enabling Host Tags: ai-router, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services.omniroute = {
    enable = mkEnableOption "OmniRoute — AI gateway with RTK compression and 4-tier fallback";

    port = mkOption {
      type = types.port;
      default = 20129;
      description = "HTTP API port (host side)";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/omniroute";
      description = "Data directory for config, DB, and combo definitions";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Env file with provider API keys (merged into container env)";
    };
  };

  config =
    let
      cfg = config.services.ai-services.omniroute;

      composeTemplate = pkgs.writeText "omniroute-compose.yml" ''
        name: omniroute

        services:
          omniroute:
            image: ghcr.io/diegosouzapw/omniroute:latest
            ports:
              - "127.0.0.1:${toString cfg.port}:20128"
            environment:
              - NODE_ENV=production
              - PORT=20128
              - HOSTNAME=0.0.0.0
              - DATA_DIR=/app/data
              - NODE_OPTIONS=--max-old-space-size=512
            volumes:
              - ${cfg.dataDir}:/app/data
            healthcheck:
              test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:20128/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
              interval: 30s
              timeout: 5s
              start_period: 60s
              retries: 3
            logging:
              driver: json-file
              options:
                max-size: "10m"
                max-file: "3"
            security_opt:
              - no-new-privileges:true
            mem_limit: 1g
            pids_limit: 512
            restart: unless-stopped
      '';

      helperPkg = pkgs.writeShellScriptBin "omniroute-ctl" ''
        set -e
        DATA_DIR="${cfg.dataDir}"
        COMPOSE_FILE="$DATA_DIR/docker-compose.yml"
        ENV_FILE="$DATA_DIR/.env"

        mkdir -p "$DATA_DIR"
        cp -f ${composeTemplate} "$COMPOSE_FILE"
        chmod 644 "$COMPOSE_FILE"
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"

        case "''${1:-up}" in
          up)
            cd "$DATA_DIR"
            ${pkgs.podman-compose}/bin/podman-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --remove-orphans 2>&1
            ;;
          down)
            cd "$DATA_DIR"
            ${pkgs.podman-compose}/bin/podman-compose -f "$COMPOSE_FILE" down 2>&1 || true
            ;;
          restart)
            "$0" down; "$0" up
            ;;
          status)
            cd "$DATA_DIR"
            ${pkgs.podman-compose}/bin/podman-compose -f "$COMPOSE_FILE" ps 2>&1 || true
            ;;
          logs)
            cd "$DATA_DIR"; shift
            ${pkgs.podman-compose}/bin/podman-compose -f "$COMPOSE_FILE" logs "$@" 2>&1 || true
            ;;
          pull)
            cd "$DATA_DIR"
            ${pkgs.podman-compose}/bin/podman-compose -f "$COMPOSE_FILE" pull 2>&1
            ;;
          *)
            echo "Usage: $0 {up|down|restart|status|logs|pull}"
            exit 1
            ;;
        esac
      '';
    in
    mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.podman-compose
        helperPkg
      ];

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = cfg.dataDir;
                user = "root";
                group = "root";
                mode = "0700";
              }
            ];
          };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0700 root root -"
      ];

      systemd.services.omniroute = {
        description = "OmniRoute — AI gateway with RTK compression";
        after = [
          "network-online.target"
          "podman.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [
          podman-compose
          podman
          coreutils
        ];

        script = ''
          ${helperPkg}/bin/omniroute-ctl up
        '';
        preStop = ''
          ${helperPkg}/bin/omniroute-ctl down
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.dataDir ];
        };
      };
    };
}
