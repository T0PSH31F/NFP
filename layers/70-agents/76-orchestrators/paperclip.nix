# Tier: 76-orchestrators
# Module: paperclip.nix
# Purpose: Paperclip multi-agent swarm task queuing and goal tracking engine.
# Option Path: layers.layer-76.orchestrators.paperclip
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "paperclip" "enable" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "paperclip" "port" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "paperclip" "enable" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "paperclip" "port" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "port" ]
    )
  ];

  options.layers.layer-76.orchestrators.paperclip = {
    enable = mkEnableOption "Paperclip — orchestrate AI agent teams";

    port = mkOption {
      type = types.port;
      default = 3101;
      description = "Port for Paperclip web UI";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/paperclip";
      description = "Persistent data directory";
    };

    databaseUrl = mkOption {
      type = types.str;
      default = "postgres://paperclip:paperclip@localhost:5432/paperclip";
      description = "PostgreSQL connection string (requires services.ai-services.postgresql)";
    };

    authSecret = mkOption {
      type = types.str;
      default = "change-me-in-production";
      description = "BETTER_AUTH_SECRET for Paperclip authentication";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.paperclip;
      paperclipPkg =
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.paperclip or (
          if (inputs ? llm-agents && inputs.llm-agents ? outPath) then
            let
              pkgPath = "${inputs.llm-agents}/packages/paperclip/package.nix";
            in
            if builtins.pathExists pkgPath then
              pkgs.callPackage pkgPath {
                flake = inputs.llm-agents;
                mkUpdater = _args: null;
              }
            else
              pkgs.paperclip or (pkgs.writeShellScriptBin "paperclip" ''
                echo "Starting fallback Paperclip daemon..."
                exec ${pkgs.python3}/bin/python3 -m http.server "${toString cfg.port}" --bind "0.0.0.0"
              '')
          else
            pkgs.paperclip or (pkgs.writeShellScriptBin "paperclip" ''
              echo "Starting fallback Paperclip daemon..."
              exec ${pkgs.python3}/bin/python3 -m http.server "${toString cfg.port}" --bind "0.0.0.0"
            '')
        );
    in
    mkIf cfg.enable {
      nfp.services.paperclip = {
        enable = true;
        host = config.networking.hostName;
        bind = "0.0.0.0";
        inherit (cfg) port;
        tailnetName = "paperclip";
        tls = "headscale";
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [ 200 ];
        };
        homepage = {
          enable = true;
          category = "chopper";
          order = 26;
          title = "Paperclip";
          subtitle = "Swarm Control Plane";
          icon = "paperclip";
          metric = {
            mode = "health-only";
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 root root -"
      ];

      systemd.services.paperclip = {
        description = "Paperclip — orchestrate AI agent teams";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = "root";
          Group = "root";
          ExecStartPre = pkgs.writeShellScript "paperclip-init" ''
            mkdir -p /root/.paperclip/instances/default
            cat << 'EOF' > /root/.paperclip/instances/default/config.json
            {
              "$meta": {
                "version": 1,
                "updatedAt": "2026-01-01T00:00:00.000Z",
                "source": "nixos"
              },
              "database": { "url": "${cfg.databaseUrl}" },
              "logging": { "level": "info", "mode": "pretty" },
              "server": { "port": ${toString cfg.port} }
            }
            EOF
          '';
          ExecStart = "${lib.getExe paperclipPkg} run";
          Restart = "on-failure";
          RestartSec = "30s";
          WorkingDirectory = cfg.dataDir;
          Environment = [
            "PORT=${toString cfg.port}"
            "NODE_ENV=production"
            "SERVE_UI=true"
            "DATABASE_URL=${cfg.databaseUrl}"
            "BETTER_AUTH_SECRET=${cfg.authSecret}"
            "PAPERCLIP_DEPLOYMENT_MODE=authenticated"
            "PAPERCLIP_DEPLOYMENT_EXPOSURE=private"
            "PAPERCLIP_PUBLIC_URL=http://${config.networking.hostName}.nfp.nix:${toString cfg.port}"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = cfg.dataDir;
                user = "root";
                group = "root";
                mode = "0755";
              }
            ];
          };
    };
}
