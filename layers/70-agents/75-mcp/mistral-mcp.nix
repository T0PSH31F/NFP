# Tier: 75-mcp
# Module: mistral-mcp.nix
# Purpose: Mistral MCP service backend daemon exposing Mistral model capabilities via MCP tools.
# Option Path: services.ai-services.mistral-mcp
# Enabling Host Tags: ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.ai-services.mistral-mcp = {
    enable = lib.mkEnableOption "Mistral MCP server — full Mistral AI surface over MCP";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3333;
      description = "HTTP MCP port (for Streamable HTTP mode)";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address";
    };

    profile = lib.mkOption {
      type = lib.types.enum [
        "core"
        "admin"
        "workflows"
        "metier-docs"
      ];
      default = "core";
      description = "MCP profile controlling how many tools are exposed";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to env file with MISTRAL_API_KEY";
    };
  };

  config =
    let
      cfg = config.services.ai-services.mistral-mcp;
    in
    lib.mkIf cfg.enable {
      systemd.services.mistral-mcp = {
        description = "Mistral MCP Server (Streamable HTTP)";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          HOME = "/tmp"; # npx needs writable HOME for cache (DynamicUser defaults HOME=/)
          MCP_TRANSPORT = "http";
          MCP_HTTP_PORT = toString cfg.port;
          MCP_HTTP_HOST = cfg.host;
          MCP_HTTP_PATH = "/mcp";
          MISTRAL_MCP_PROFILE = cfg.profile;
        };

        serviceConfig = {
          ExecStart = "${pkgs.nodejs_22}/bin/npx -y mistral-mcp";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          NoNewPrivileges = true;
          PrivateTmp = true;
          MemoryDenyWriteExecute = false;
        };

        # npx needs sh and node in PATH for downloaded packages
        path = [
          pkgs.bash
          pkgs.nodejs_22
        ];
      };
    };
}
