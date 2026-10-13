# Tier: 75-mcp
# Module: mistral-mcp.nix
# Purpose: Mistral MCP service backend daemon exposing Mistral model capabilities via MCP tools.
# Option Path: services.ai-services.mistral-mcp
# Enabling Host Tags: ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
#
# Pin policy: mistral-mcp version is pinned via src hash below.
# To upgrade: update version + sha256 + update npmDepsHash via
#   nix-prefetch-url https://registry.npmjs.org/mistral-mcp/-/mistral-mcp-<ver>.tgz
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Pinned version of mistral-mcp — update hash when bumping.
  mistral-mcp-pkg = pkgs.buildNpmPackage rec {
    pname = "mistral-mcp";
    version = "1.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "mistralai";
      repo = "mistral-mcp";
      rev = "v${version}";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # update via nix-prefetch
    };

    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # update via prefetchNpmDeps
    nodejs = pkgs.nodejs_22;

    meta = {
      description = "Mistral AI MCP server";
      license = lib.licenses.asl20;
      maintainers = [ ];
    };
  };
in
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
          ExecStart = "${mistral-mcp-pkg}/bin/mistral-mcp";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          NoNewPrivileges = true;
          PrivateTmp = true;
          MemoryDenyWriteExecute = false;
        };

        # Node.js available in PATH for any runtime require()
        path = [
          pkgs.nodejs_22
        ];
      };
    };
}
