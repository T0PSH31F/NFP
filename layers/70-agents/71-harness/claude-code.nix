# Tier: 71-harness
# Module: claude-code.nix
# Purpose: Anthropic Claude Code terminal agent harness wrapper.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://nami:8090/v1 (ExtremeRouter)
#   kong-omni:     http://nami:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://nami:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://nami:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.claude-code
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
      [ "layers" "layer-70" "agent" "claude-code" ]
      [ "layers" "layer-71" "harness" "claude-code" ]
    )
  ];

  options.layers.layer-71.harness.claude-code = {
    enable = lib.mkEnableOption "Anthropic Claude Code agentic coding tool";
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.claude-code;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? claude-code) pkgs.claude-code;
      environment.sessionVariables = {
        ANTHROPIC_BASE_URL_KONG_ER = "http://nami:8090/v1";
        ANTHROPIC_BASE_URL_KONG_OMNI = "http://nami:8090/omni/v1";
        ANTHROPIC_BASE_URL_KONG_FREE = "http://nami:8090/llm/free/v1";
        ANTHROPIC_BASE_URL_KONG_FRONTIER = "http://nami:8090/llm/frontier/v1";
        ANTHROPIC_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
      };
    };

  home =
    let
      cfg = config.layers.layer-71.harness.claude-code;
    in
    lib.mkIf cfg.enable {
      home.packages = lib.optional (
        pkgs ? vscode-extension-anthropic-claude-code
      ) pkgs.vscode-extension-anthropic-claude-code;

      xdg.configFile."claude/settings.json".text = builtins.toJSON {
        hasCompletedOnboarding = true;
        env = {
          ANTHROPIC_BASE_URL = "http://nami:8090/v1";
        };
      };
    };
}
