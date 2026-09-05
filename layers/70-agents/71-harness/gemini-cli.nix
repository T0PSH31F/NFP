# Tier: 71-harness
# Module: gemini-cli.nix
# Purpose: Google Gemini CLI harness for command line generation.
# Option Path: layers.layer-70.agent.gemini-cli
# Enabling Host Tags: ai-agent, development
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
      [ "layers" "layer-70" "agent" "gemini-cli" ]
      [ "layers" "layer-71" "harness" "gemini-cli" ]
    )
  ];

  options.layers.layer-71.harness.gemini-cli = {
    enable = lib.mkEnableOption "Gemini CLI agent (alias for Antigravity)";
  };

  config = lib.mkIf config.layers.layer-71.harness.gemini-cli.enable {
    layers.layer-71.harness.antigravity.enable = true;
    environment.systemPackages = lib.optional (pkgs ? gemini-cli) pkgs.gemini-cli;
  };
}
