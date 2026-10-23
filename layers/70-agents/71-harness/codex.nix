# Tier: 71-harness
# Module: codex.nix
# Purpose: OpenAI Codex CLI terminal harness tool.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong:          http://sanji.nfp.nix:8090/v1 (ExtremeRouter via Kong, /v1/responses profile)
#   kong-omni:     http://sanji.nfp.nix:8090/omni/v1 (OmniRoute via Kong)
#   kong-free:     http://sanji.nfp.nix:8090/llm/free/v1 (FreeLLMPool via Kong)
#   kong-frontier: http://sanji.nfp.nix:8090/llm/frontier/v1 (Manifest via Kong)
#   extreme-direct: http://z0r0.nfp.nix:20128/v1 (ER direct backup)
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
      kongBase =
        if (config.services.ai-services.kong-gateway.enable or false) then
          "http://127.0.0.1:${toString (config.services.ai-services.kong-gateway.proxyPort or 8090)}"
        else
          "http://sanji.nfp.nix:8090";
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? codex) pkgs.codex;
      environment.sessionVariables = {
        OPENAI_BASE_URL_KONG_ER = lib.mkDefault "${kongBase}/v1";
        OPENAI_BASE_URL_KONG_OMNI = lib.mkDefault "${kongBase}/omni/v1";
        OPENAI_BASE_URL_KONG_FREE = lib.mkDefault "${kongBase}/llm/free/v1";
        OPENAI_BASE_URL_KONG_FRONTIER = lib.mkDefault "${kongBase}/llm/frontier/v1";
        OPENAI_BASE_URL_EXTREME_DIRECT = lib.mkDefault "http://127.0.0.1:20128/v1";
      };
    };

  home =
    { osConfig, ... }:
    let
      cfg = osConfig.layers.layer-71.harness.codex;
      kongBase =
        if (osConfig.services.ai-services.kong-gateway.enable or false) then
          "http://127.0.0.1:${toString (osConfig.services.ai-services.kong-gateway.proxyPort or 8090)}"
        else
          "http://sanji.nfp.nix:8090";
      codexConfigToml = ''
        model_provider = "kong"
        model = "cx/gpt-5.3-codex"

        [profiles.responses]
        model_provider = "kong"
        model = "cx/gpt-5.3-codex"

        [model_providers.kong]
        name = "Kong AI Gateway"
        base_url = "${kongBase}/v1"
        env_key = "KONG_KEY_CODEX"
        wire_api = "responses"

        [model_providers.kong-er]
        name = "Kong ExtremeRouter"
        base_url = "http://sanji.nfp.nix:8090/v1"
        env_key = "KONG_KEY_CODEX"
        wire_api = "responses"

        [model_providers.jev]
        name = "Jev Tier Router"
        base_url = "${kongBase}/jev/v1"
        env_key = "KONG_KEY_CODEX"
        wire_api = "responses"

        [model_providers.kong-omni]
        name = "Kong OmniRoute"
        base_url = "${kongBase}/omni/v1"
        env_key = "KONG_KEY_CODEX"
        wire_api = "responses"

        [model_providers.kong-free]
        name = "Kong FreeLLMPool"
        base_url = "${kongBase}/llm/free/v1"
        env_key = "KONG_KEY_CODEX"
        wire_api = "responses"

        [model_providers.extreme-direct]
        name = "ExtremeRouter Direct"
        base_url = "http://z0r0.nfp.nix:20128/v1"
        env_key = "EXTREMEROUTER_API_KEY"
        wire_api = "responses"
      '';
      codexInstructions = ''
        # NFP Codex — Mandatory Operating & Voice Notification Directives

        1. **Mandatory Voice Notifications (ALWAYS ACTIVE)**:
           - Always vocalize task completions, milestone updates, and alerts using GLaDOS voice in the background:
             `/home/t0psh31f/.local/bin/glados-tts-cli "<concise update in GLaDOS voice>" >/dev/null 2>&1 &`
        2. **Multi-Agent Communication (`~/Notes/EverOS/todo.md`)**:
           - Coordinate with other agents via `nfp-todo` (`~/Notes/EverOS/todo.md`) and the 24/7 Pi Durable Worker (`http://127.0.0.1:8089/v1/delegate`).
      '';
    in
    lib.mkIf cfg.enable {
      xdg.configFile."codex/config.toml".text = codexConfigToml;
      home.file.".codex/config.toml".text = codexConfigToml;
      xdg.configFile."codex/AGENTS.md".text = codexInstructions;
      home.file.".codex/AGENTS.md".text = codexInstructions;
    };
}
