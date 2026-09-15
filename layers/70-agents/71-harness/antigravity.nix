# Tier: 71-harness
# Module: antigravity.nix
# Purpose: Google Antigravity Agentic IDE & CLI suite integration.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://nami:8090/v1 (ExtremeRouter)
#   kong-omni:     http://nami:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://nami:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://nami:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.antigravity
# Enabling Host Tags: ai-agent, workstation, desktop
# RAM Footprint: medium (300MB-1GB)
{
  config,
  pkgs,
  lib,
  osConfig ? config,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "antigravity" ]
      [ "layers" "layer-71" "harness" "antigravity" ]
    )
  ];

  options.layers.layer-71.harness.antigravity = {
    enable = lib.mkEnableOption "Antigravity agentic IDE & CLI";

    enableIde = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install Antigravity IDE GUI application in system packages";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "gemini-3.7-flash";
      description = "Default model for Antigravity CLI";
    };

    enableA2A = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Inter-Agent (A2A) communication with Hermes, OpenCode, and ContextForge";
    };
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.antigravity;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.antigravity-cli
      ]
      ++ lib.optional cfg.enableIde pkgs.antigravity-ide;

      environment.sessionVariables = {
        OPENAI_BASE_URL_KONG_ER = "http://nami:8090/v1";
        OPENAI_BASE_URL_KONG_OMNI = "http://nami:8090/omni/v1";
        OPENAI_BASE_URL_KONG_FREE = "http://nami:8090/llm/free/v1";
        OPENAI_BASE_URL_KONG_FRONTIER = "http://nami:8090/llm/frontier/v1";
        OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
      };
    };

  home =
    let
      cfg = config.layers.layer-71.harness.antigravity;
    in
    lib.mkIf cfg.enable {
      # Antigravity MCP & A2A Inter-Agent Gateway Configuration
      xdg.configFile."antigravity/mcp_config.json".text = builtins.toJSON {
        mcpServers = lib.optionalAttrs cfg.enableA2A {
          hermes-a2a = {
            url = "${osConfig.layers.layer-20.endpoints.hermes-gateway.baseUrl}/mcp";
            description = "Hermes Autonomous Worker A2A Gateway";
          };
          context-forge = {
            url = osConfig.layers.layer-20.endpoints.context-forge.baseUrl;
            description = "ContextForge Universal MCP/A2A Gateway";
          };
          brain-service = {
            command = "/run/current-system/sw/bin/brain-mcp";
            args = [ ];
            description = "PKB Brain RAG Search & Vector Index";
          };
          ncp = {
            command = "npx";
            args = [
              "-y"
              "@portel/ncp"
            ];
            description = "Semantic MCP Gateway (Context Reduction)";
          };
          playwright = {
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
            ];
            description = "Playwright Browser Automation MCP Server";
          };
          headroom = {
            command = "headroom";
            args = [
              "mcp"
              "serve"
            ];
            description = "Headroom Context Token Compressor";
          };
          mcp-nixos = {
            command = "${lib.getExe pkgs.mcp-nixos}";
            args = [ ];
          };
          github = {
            command = "${lib.getExe pkgs.github-mcp-server}";
            args = [ ];
          };
        };
      };
    };
}
