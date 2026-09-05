# Tier: 71-harness
# Module: antigravity.nix
# Purpose: Google Antigravity Agentic IDE & CLI suite integration.
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
