# Tier: 71-harness
# Module: codex.nix
# Purpose: OpenAI Codex CLI terminal harness tool.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
#   kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.codex
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
      [ "layers" "layer-70" "agent" "codex" ]
      [ "layers" "layer-71" "harness" "codex" ]
    )
  ];

  options.layers.layer-71.harness.codex = {
    enable = lib.mkEnableOption "OpenAI Codex coding agent";
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.codex;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? codex) pkgs.codex;
      environment.sessionVariables = {
        OPENAI_BASE_URL_KONG_ER = "http://127.0.0.1:8090/v1";
        OPENAI_BASE_URL_KONG_OMNI = "http://127.0.0.1:8090/omni/v1";
        OPENAI_BASE_URL_KONG_FREE = "http://127.0.0.1:8090/llm/free/v1";
        OPENAI_BASE_URL_KONG_FRONTIER = "http://127.0.0.1:8090/llm/frontier/v1";
        OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
      };
    };

  home =
    let
      cfg = config.layers.layer-71.harness.codex;
    in
    lib.mkIf cfg.enable {
      xdg.configFile."deepseek/config.toml".text = ''
        [providers.openai]
        base_url = "http://127.0.0.1:8090/v1"

        [providers.kong-er]
        base_url = "http://127.0.0.1:8090/v1"

        [providers.kong-omni]
        base_url = "http://127.0.0.1:8090/omni/v1"

        [providers.kong-free]
        base_url = "http://127.0.0.1:8090/llm/free/v1"

        [providers.kong-frontier]
        base_url = "http://127.0.0.1:8090/llm/frontier/v1"

        [providers.extreme-direct]
        base_url = "http://127.0.0.1:20128/v1"
      '';
    };
}
