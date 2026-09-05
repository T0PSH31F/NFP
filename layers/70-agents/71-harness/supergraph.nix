# Tier: 71-harness
# Module: supergraph.nix
# Purpose: Supergraph autonomous codebase navigation harness.
# Option Path: layers.layer-70.agent.supergraph
# Enabling Host Tags: ai-agent, development
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "supergraph" ]
      [ "layers" "layer-71" "harness" "supergraph" ]
    )
  ];

  options.layers.layer-71.harness.supergraph = {
    enable = lib.mkEnableOption "supergraph — monorepo intelligence for AI coding agents";
  };

  config = lib.mkIf config.layers.layer-71.harness.supergraph.enable {
    environment.systemPackages = [ pkgs.supergraph ];
  };
}
