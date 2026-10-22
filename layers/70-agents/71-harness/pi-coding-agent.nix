# Tier: 71-harness
# Module: pi-coding-agent.nix
# Purpose: Pi Durable Coding Agent (earendil-works/Pi) terminal AI harness with
#          durable execution, NFP LLM router hierarchy & MCP integration.
#
# Provider endpoints (Kong path multiplexer + ExtremeRouter + Jev System-1):
#   kong-er:        http://luffy.nfp.nix:8090/v1 (ExtremeRouter)
#   kong-omni:      http://luffy.nfp.nix:8090/omni/v1 (OmniRoute)
#   kong-free:      http://luffy.nfp.nix:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier:  http://luffy.nfp.nix:8090/llm/frontier/v1 (Manifest)
#   jev-preflight:  http://127.0.0.1:20127/v1 (Jev System-1 0-token discriminative pre-flight)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
#   local-ollama:   http://127.0.0.1:11434/v1 (Ollama local inference)
#
# Option Path: layers.layer-71.harness.pi-coding-agent (and programs.pi / programs.pi-durable)
# Enabling Host Tags: ai-agent, development
{
  config,
  lib,
  pkgs,
  inputs ? { },
  osConfig ? config,
  ...
}:

with lib;

let
  cfg = config.layers.layer-71.harness.pi-coding-agent;
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
  sys = pkgs.stdenv.hostPlatform.system;
  piPkg = inputs.pi.packages.${sys}.default or (pkgs.pi or null);
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "programs" "pi-coding-agent" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule [ "programs" "pi" ] [ "layers" "layer-71" "harness" "pi-coding-agent" ])
    (lib.mkAliasOptionModule
      [ "programs" "pi-durable" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "pi-coding-agent" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule
      [ "layers" "layer-71" "harness" "pi" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule
      [ "layers" "layer-71" "harness" "pi-durable" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
    (lib.mkAliasOptionModule
      [ "layers" "layer-71" "harness" "omp" ]
      [ "layers" "layer-71" "harness" "pi-coding-agent" ]
    )
  ];

  options.layers.layer-71.harness.pi-coding-agent = {
    enable = mkEnableOption "Pi durable coding agent (earendil-works/Pi)";

    package = mkOption {
      type = types.nullOr types.package;
      default = piPkg;
      description = "Package to use for Pi coding agent (durable agent)";
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
      PI_CODING_AGENT_DIR = "$HOME/.pi/agent";
      OPENAI_BASE_URL = lib.mkDefault cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = lib.mkDefault "http://127.0.0.1:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = lib.mkDefault "http://127.0.0.1:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = lib.mkDefault "http://127.0.0.1:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = lib.mkDefault "http://127.0.0.1:8090/llm/frontier/v1";
      OPENAI_BASE_URL_JEV_PREFLIGHT = lib.mkDefault "http://127.0.0.1:20127/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = lib.mkDefault "http://127.0.0.1:20128/v1";
    };

    home-manager.users.${user} = { pkgs, ... }:
      let
        piSettings = {
          defaultProvider = "kong";
          inherit (cfg) defaultModel;
          inherit (cfg) autoCommit;
          inherit (cfg) thinkingBudget;
        };

        piModels = {
          "$schema" = "https://pi.dev/schemas/models.schema.json";
          providers = {
            kong = {
              baseUrl = cfg.routerEndpoint;
              api = "openai-completions";
              apiKey = "nfp-router-internal";
              models = [
                {
                  id = "mimo-v2.5-pro";
                  name = "MiMo Pro 2.5";
                  input = [ "text" ];
                }
                {
                  id = "claude-3-5-sonnet";
                  name = "Claude 3.5 Sonnet";
                  input = [
                    "text"
                    "image"
                  ];
                }
                {
                  id = "gpt-4o";
                  name = "GPT-4o";
                  input = [
                    "text"
                    "image"
                  ];
                }
              ];
            };
            jev-preflight = {
              baseUrl = "http://127.0.0.1:20127/v1";
              api = "openai-completions";
              apiKey = "jev-zero-token";
              models = [
                {
                  id = "mimo-v2.5-pro";
                  name = "MiMo Pro 2.5 (Jev Pre-Flight Proxy)";
                  input = [ "text" ];
                }
              ];
            };
            groq = {
              baseUrl = "https://api.groq.com/openai/v1";
              api = "openai-completions";
              apiKey = "$GROQ_API_KEY";
              models = [
                {
                  id = "qwen/qwen3.8-27b";
                  name = "Qwen 3.8 27B";
                  input = [ "text" ];
                }
              ];
            };
            ollama = {
              baseUrl = "http://127.0.0.1:11434/v1";
              api = "openai-completions";
              apiKey = "ollama";
              models = [
                {
                  id = "qwen2.5-coder:7b";
                  name = "Qwen 2.5 Coder 7B (Local)";
                  input = [ "text" ];
                }
              ];
            };
          };
        };

        piMcp = {
          mcpServers = optionalAttrs cfg.enableMcp {
            hermes-a2a = {
              url = "http://127.0.0.1:8085/mcp";
              description = "Hermes Autonomous Worker A2A Gateway";
            };
            context-forge = {
              url = osConfig.layers.layer-20.endpoints.context-forge.baseUrl or "http://127.0.0.1:8000";
              description = "ContextForge Universal MCP/A2A Gateway";
            };
            jev-decision = {
              command = "${pkgs.python3}/bin/python3";
              args = [ "${../75-mcp/jev-mcp.py}" ];
              description = "Jev System-1 Decision Engine, Telemetry & Triage Oversight";
            };
          };
        };
      in
      {
        config = {
          # Pi User Settings (~/.pi/agent/settings.json and ~/.config/pi/agent/settings.json)
          home.file.".pi/agent/settings.json".text = builtins.toJSON piSettings;
          xdg.configFile."pi/agent/settings.json".text = builtins.toJSON piSettings;

          # Pi Models Configuration (~/.pi/agent/models.json and ~/.config/pi/agent/models.json)
          home.file.".pi/agent/models.json".text = builtins.toJSON piModels;
          xdg.configFile."pi/agent/models.json".text = builtins.toJSON piModels;

          # Pi MCP Servers (~/.pi/agent/mcp.json and ~/.config/pi/agent/mcp.json)
          home.file.".pi/agent/mcp.json".text = builtins.toJSON piMcp;
          xdg.configFile."pi/agent/mcp.json".text = builtins.toJSON piMcp;

          # Backward compatibility symlink (~/.config/pi/config.json)
          xdg.configFile."pi/config.json".text = builtins.toJSON {
            model = cfg.defaultModel;
            apiBase = cfg.routerEndpoint;
            inherit (cfg) autoCommit;
            inherit (cfg) thinkingBudget;
          };
        };
      };
  };
}
