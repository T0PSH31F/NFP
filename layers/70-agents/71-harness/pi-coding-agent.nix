# Tier: 71-harness
# Module: pi-coding-agent.nix
# Purpose: Pi Coding Agent terminal AI coding harness wrapper with NFP LLM router & MCP integration.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
#   kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: programs.pi-coding-agent (and layers.layer-71.harness.pi-coding-agent)
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

let
  cfg = config.layers.layer-71.harness.pi-coding-agent;
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "programs" "pi-coding-agent" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "pi-coding-agent" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
  ];

  options.layers.layer-71.harness.pi-coding-agent = {
    enable = mkEnableOption "Pi coding agent terminal tool";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.pi-coding-agent or (pkgs.pi or null);
      description = "Package to use for Pi coding agent";
    };

    defaultModel = mkOption {
      type = types.str;
      default = "mimo-v2.5-pro";
      description = "Default model for Pi coding agent";
    };

    routerEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8090/v1";
      description = "NFP LLM router OpenAI-compatible gateway endpoint";
    };

    enableMcp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Model Context Protocol (MCP) integrations with Hermes, ContextForge, and NixOS MCP";
    };

    autoCommit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic git commit generation after AI code modifications";
    };

    thinkingBudget = mkOption {
      type = types.int;
      default = 2048;
      description = "Token budget allocated for deep reasoning/thinking steps";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = optional (cfg.package != null) cfg.package;

    environment.sessionVariables = {
      PI_MODEL = cfg.defaultModel;
      PI_ROUTER_ENDPOINT = cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = "http://127.0.0.1:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = "http://127.0.0.1:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = "http://127.0.0.1:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = "http://127.0.0.1:8090/llm/frontier/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
    };

    home-manager.users.${user} = { pkgs, ... }: {
      config = {
        xdg.configFile."pi/config.json".text = builtins.toJSON {
          model = cfg.defaultModel;
          apiBase = cfg.routerEndpoint;
          inherit (cfg) autoCommit;
          inherit (cfg) thinkingBudget;
          mcpServers = optionalAttrs cfg.enableMcp {
            hermes-a2a = {
              url = "http://127.0.0.1:8085/mcp";
              description = "Hermes Autonomous Worker A2A Gateway";
            };
            context-forge = {
              url = "http://127.0.0.1:8083/mcp";
              description = "ContextForge Universal MCP/A2A Gateway";
            };
            mcp-nixos = {
              command = "${lib.getExe' pkgs.coreutils "true"}";
              args = [ ];
            };
          };
        };
      };
    };
  };
}
