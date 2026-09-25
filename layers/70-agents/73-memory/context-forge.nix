# Tier: 73-memory
# Module: context-forge.nix
# Purpose: ContextForge agent prompt assembly & dynamic context window manager.
# Option Path: layers.layer-73.memory.context-forge / services.ai-services.context-forge
# Enabling Host Tags: pkb-node, ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-73.memory.context-forge = {
    enable = mkEnableOption "ContextForge MCP/A2A gateway";

    port = mkOption {
      type = types.port;
      default = 8094;
      description = "Port for ContextForge gateway";
    };

    langfuseEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:3005";
      description = "Langfuse tracing endpoint";
    };
  };

  # Backwards compatibility alias
  options.services.ai-services.context-forge = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Alias for layers.layer-73.memory.context-forge.enable";
    };
    port = mkOption {
      type = types.port;
      default = 8094;
      description = "Alias for layers.layer-73.memory.context-forge.port";
    };
  };

  config = mkMerge [
    (mkIf config.services.ai-services.context-forge.enable {
      layers.layer-73.memory.context-forge.enable = true;
      layers.layer-73.memory.context-forge.port = config.services.ai-services.context-forge.port;
    })
    (
      let
        cfg = config.layers.layer-73.memory.context-forge;

        # ContextForge MCP configuration JSON
        configFile = pkgs.writeText "context-forge-config.json" (
          builtins.toJSON {
            mcpServers = {
              everos = {
                command = "npx";
                args = [
                  "-y"
                  "@evermind-ai/everos-mcp"
                ];
              };
            };
            tracing = {
              enabled = true;
              endpoint = cfg.langfuseEndpoint;
            };
          }
        );
      in
      mkIf cfg.enable {
        systemd.services.context-forge = {
          description = "ContextForge MCP Gateway & Tracing Router";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            ExecStart = "${pkgs.nodejs}/bin/npx -y @evermind-ai/context-forge --config ${configFile} --port ${toString cfg.port}";
            Restart = "always";
            RestartSec = 5;
            Environment = [
              "PORT=${toString cfg.port}"
              "NODE_ENV=production"
              "LANGFUSE_HOST=${cfg.langfuseEndpoint}"
            ];
          };
        };
      }
    )
  ];
}
