# Tier: 75-mcp
# Module: mcp.nix
# Purpose: Legacy MCP configuration adapter & helper imports (redirects to layer-75).
# Option Path: layers.layer-70.agent.mcp
# Enabling Host Tags: ai-agent
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "mcp" ]
      [ "layers" "layer-75" "mcp" "catalog" ]
    )
  ];

  options.layers.layer-75.mcp.catalog = {
    enable = lib.mkEnableOption "Model Context Protocol (MCP) servers catalog alias";
    servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "MCP servers catalog map";
    };
  };

  config = lib.mkIf config.layers.layer-75.mcp.catalog.enable {
    layers.layer-75.mcp = {
      enable = lib.mkDefault true;
      servers = config.layers.layer-75.mcp.catalog.servers;
    };
  };
}
