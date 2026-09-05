# Tier: 71-harness
# Module: codegraph.nix
# Purpose: CodeGraph semantic code intelligence for AI coding agents.
# Option Path: layers.layer-70.agent.codegraph
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
      [ "layers" "layer-70" "agent" "codegraph" ]
      [ "layers" "layer-71" "harness" "codegraph" ]
    )
  ];

  options.layers.layer-71.harness.codegraph = {
    enable = lib.mkEnableOption "codegraph — semantic code intelligence for AI coding agents";
  };

  config = lib.mkIf config.layers.layer-71.harness.codegraph.enable {
    environment.systemPackages = [
      pkgs.codegraph
      pkgs.lazyskills
    ];
  };
}
