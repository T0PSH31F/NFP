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
      default = 3100;
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
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      paperclipPkg = llmPkgs.paperclip or pkgs.paperclip;
    in
    mkIf cfg.enable {
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
              "$meta": { "version": "1.0" },
              "database": { "url": "${cfg.databaseUrl}" },
              "logging": { "level": "info" },
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
            "PAPERCLIP_PUBLIC_URL=http://localhost:${toString cfg.port}"
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
