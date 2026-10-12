# Tier: 75-mcp
# Module: jev-mcp.nix
# Purpose: Jev System-1 Decision MCP server configuration & tools.
# Option Path: layers.layer-75.mcp.jev
# Enabling Host Tags: ai-agent, workstation, homelab
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-75.mcp.jev;
in
{
  options.layers.layer-75.mcp.jev = {
    enable = lib.mkEnableOption "Jev Decision Model MCP server";

    engineUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://luffy.nfp.nix:20130";
      description = "Endpoint URL for the Jev decision engine";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "jev-mcp" ''
        export JEV_ENGINE_URL="''${JEV_ENGINE_URL:-${cfg.engineUrl}}"
        exec ${pkgs.python3}/bin/python3 ${./jev-mcp.py} "$@"
      '')
    ];
  };
}
