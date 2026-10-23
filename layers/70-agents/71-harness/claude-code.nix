# Tier: 71-harness
# Module: claude-code.nix
# Purpose: Anthropic Claude Code terminal agent harness wrapper.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://sanji.nfp.nix:8090/v1 (ExtremeRouter via Kong)
#   kong-omni:     http://sanji.nfp.nix:8090/omni/v1 (OmniRoute via Kong)
#   kong-free:     http://sanji.nfp.nix:8090/llm/free/v1 (FreeLLMPool via Kong)
#   kong-frontier: http://sanji.nfp.nix:8090/llm/frontier/v1 (Manifest via Kong)
#   extreme-direct: http://z0r0.nfp.nix:20128/v1 (ER direct backup)
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
      kongBase =
        if (config.services.ai-services.kong-gateway.enable or false) then
          "http://127.0.0.1:${toString (config.services.ai-services.kong-gateway.proxyPort or 8090)}"
        else
          "http://sanji.nfp.nix:8090";
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? claude-code) pkgs.claude-code;
      environment.sessionVariables = {
        ANTHROPIC_BASE_URL = kongBase;
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        ANTHROPIC_BASE_URL_KONG_ER = "${kongBase}/v1";
        ANTHROPIC_BASE_URL_KONG_OMNI = "${kongBase}/omni/v1";
        ANTHROPIC_BASE_URL_KONG_FREE = "${kongBase}/llm/free/v1";
        ANTHROPIC_BASE_URL_KONG_FRONTIER = "${kongBase}/llm/frontier/v1";
        ANTHROPIC_BASE_URL_EXTREME_DIRECT = "http://z0r0.nfp.nix:20128/v1";
      };
    };

  home =
    { osConfig, ... }:
    let
      cfg = osConfig.layers.layer-71.harness.claude-code;
      kongBase =
        if (osConfig.services.ai-services.kong-gateway.enable or false) then
          "http://127.0.0.1:${toString (osConfig.services.ai-services.kong-gateway.proxyPort or 8090)}"
        else
          "http://sanji.nfp.nix:8090";
      claudeSettings = builtins.toJSON {
        hasCompletedOnboarding = true;
        apiKeyHelper = "cat /home/t0psh31f/.config/sops-nix/secrets/kong_key_claude_code 2>/dev/null || cat /run/secrets/kong_key_claude_code 2>/dev/null || printf '%s' \"$ANTHROPIC_AUTH_TOKEN\"";
        env = {
          ANTHROPIC_BASE_URL = kongBase;
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        };
      };
    in
    lib.mkIf cfg.enable {
      home.packages = lib.optional (
        pkgs ? vscode-extension-anthropic-claude-code
      ) pkgs.vscode-extension-anthropic-claude-code;

      xdg.configFile."claude/settings.json".text = claudeSettings;
      home.file.".claude/settings.json".text = claudeSettings;
    };
}
