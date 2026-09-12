# Tier: 71-harness
# Module: kiro-cli.nix
# Purpose: Kiro autonomous agent CLI tool integration.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
#   kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.kiro-cli
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:

with lib;

{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "kiro-cli" ]
      [ "layers" "layer-71" "harness" "kiro-cli" ]
    )
  ];

  options.layers.layer-71.harness.kiro-cli = {
    enable = mkEnableOption "Kiro CLI — command-line interface for Kiro agentic IDE";
    enableA2A = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Inter-Agent (A2A) communication with Hermes, OpenCode, and ContextForge";
    };
  };

  config =
    let
      cfg = config.layers.layer-71.harness.kiro-cli;
      user = osConfig.layers.meta.primaryUser or "t0psh31f";
    in
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        kiro-cli
      ];

      environment.sessionVariables = {
        OPENAI_BASE_URL_KONG_ER = "http://127.0.0.1:8090/v1";
        OPENAI_BASE_URL_KONG_OMNI = "http://127.0.0.1:8090/omni/v1";
        OPENAI_BASE_URL_KONG_FREE = "http://127.0.0.1:8090/llm/free/v1";
        OPENAI_BASE_URL_KONG_FRONTIER = "http://127.0.0.1:8090/llm/frontier/v1";
        OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
      };

      home-manager.users.${user} = { pkgs, ... }: {
        config = {
          # Kiro CLI MCP & A2A Inter-Agent Gateway Configuration
          xdg.configFile."kiro/mcp.json".text = builtins.toJSON {
            mcpServers = optionalAttrs cfg.enableA2A {
              hermes-a2a = {
                url = "http://127.0.0.1:8085/mcp";
                description = "Hermes Autonomous Worker A2A Gateway";
              };
              context-forge = {
                url = "http://127.0.0.1:8083/mcp";
                description = "ContextForge Universal MCP/A2A Gateway";
              };
              playwright = {
                command = "npx";
                args = [
                  "-y"
                  "@playwright/mcp@latest"
                ];
                description = "Playwright Browser Automation MCP Server";
              };
              mcp-nixos = {
                command = "${lib.getExe pkgs.mcp-nixos}";
                args = [ ];
              };
            };
          };
        };
      };
    };
}
