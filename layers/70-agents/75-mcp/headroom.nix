# Tier: 75-mcp
# Module: headroom.nix
# Purpose: Headroom MCP server wrapper & context compression proxy.
# Option Path: services.ai-services.headroom
# Enabling Host Tags: ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    (mkRenamedOptionModule
      [ "services" "ai-services" "headroom" ]
      [ "layers" "layer-75" "mcp" "headroom" ]
    )
  ];

  options.layers.layer-75.mcp.headroom = {
    enable = mkEnableOption "Headroom — context compression proxy for AI agents";

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Port for Headroom proxy";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.headroom-ai;
      description = "Headroom package";
    };

    maxResultBytes = mkOption {
      type = types.int;
      default = 1048576; # 1MB limit
      description = "Maximum response size cap in bytes for context compression proxy";
    };

    cacheTtlSeconds = mkOption {
      type = types.int;
      default = 300; # 5 minutes default
      description = "Cache TTL in seconds for compressed context responses";
    };
  };

  config =
    let
      cfg = config.layers.layer-75.mcp.headroom;
    in
    mkIf cfg.enable {
      # Install headroom globally
      environment.systemPackages = [ cfg.package ];

      # Run headroom proxy as a systemd service
      systemd.services.headroom-proxy = {
        description = "Headroom context compression proxy";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} proxy --port ${toString cfg.port}";
          Restart = "always";
          RestartSec = 5;
          Environment = [
            "HEADROOM_PORT=${toString cfg.port}"
            "HEADROOM_HOST=127.0.0.1"
            "HEADROOM_MAX_RESULT_BYTES=${toString cfg.maxResultBytes}"
            "HEADROOM_CACHE_TTL=${toString cfg.cacheTtlSeconds}"
            "OPENAI_BASE_URL=http://127.0.0.1:20128/v1"
            "EXTREMEROUTER_BASE_URL=http://127.0.0.1:20128/v1"
          ];
        };
      };

      # Open firewall port
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    };
}
