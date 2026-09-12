# Tier: 71-harness
# Module: gemini-cli.nix
# Purpose: Google Gemini CLI harness for command line generation.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
#   kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
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
