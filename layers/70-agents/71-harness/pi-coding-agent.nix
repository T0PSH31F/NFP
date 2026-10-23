# Tier: 71-harness
# Module: pi-coding-agent.nix
# Purpose: Pi Durable Coding Agent (earendil-works/Pi) terminal AI harness with
#          durable execution, NFP LLM router hierarchy & MCP integration.
#
# Provider endpoints (Kong path multiplexer + ExtremeRouter + Jev Tier Router):
#   kong:           http://127.0.0.1:8090/v1 (or http://sanji.nfp.nix:8090/v1 / http://nami:8090/v1)
#   jev:            http://127.0.0.1:8090/jev/v1 (Jev async streaming tier router via Kong)
#   kong-omni:      http://sanji.nfp.nix:8090/omni/v1 (OmniRoute)
#   kong-free:      http://sanji.nfp.nix:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier:  http://sanji.nfp.nix:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://z0r0.nfp.nix:20128/v1 (ER direct backup)
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
      default = "Coding";
      description = "Default model or router combo for Pi coding agent";
    };

    routerEndpoint = mkOption {
      type = types.str;
      default =
        if (osConfig.services.ai-services.kong-gateway.enable or false) then
          "http://127.0.0.1:${toString (osConfig.services.ai-services.kong-gateway.proxyPort or 8090)}/v1"
        else
          "http://sanji.nfp.nix:8090/v1";
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
    environment.systemPackages = optional (cfg.package != null) cfg.package ++ [
      (pkgs.writeShellScriptBin "nfp-llm-doctor" (
        builtins.readFile ../../00-cyberia/06-scripts/nfp-llm-doctor.sh
      ))
    ];

    environment.sessionVariables = {
      PI_CODING_AGENT_DIR = "$HOME/.pi/agent";
      OPENAI_BASE_URL = lib.mkDefault cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = lib.mkDefault cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_OMNI = lib.mkDefault "http://sanji.nfp.nix:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = lib.mkDefault "http://sanji.nfp.nix:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = lib.mkDefault "http://sanji.nfp.nix:8090/llm/frontier/v1";
      OPENAI_BASE_URL_JEV_PREFLIGHT = lib.mkDefault "http://127.0.0.1:20127/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = lib.mkDefault "http://z0r0.nfp.nix:20128/v1";
    };

    home-manager.users.${user} =
      { pkgs, ... }:
      let
        piApiKeyCmd = "!cat /home/t0psh31f/.config/sops-nix/secrets/kong_key_pi 2>/dev/null || cat /run/secrets/kong_key_pi 2>/dev/null || printf '%s' \"$KONG_KEY_PI\"";

        # Explicit model IDs pulled from Kong/ExtremeRouter /v1/models (combos + top providers)
        explicitKongModels = [
          {
            id = "Coding";
            name = "ExtremeRouter Coding Combo (Cascade)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "DailyDrive";
            name = "ExtremeRouter DailyDrive Combo (Round-Robin)";
            input = [ "text" ];
          }
          {
            id = "Penny-Pincher";
            name = "ExtremeRouter Penny-Pincher Combo (Voice/Fast)";
            input = [ "text" ];
          }
          {
            id = "Free";
            name = "ExtremeRouter Free Combo (Zero-Cost Swarm)";
            input = [ "text" ];
          }
          {
            id = "Research";
            name = "ExtremeRouter Research Combo (Smart-Routing)";
            input = [ "text" ];
          }
          {
            id = "Judge";
            name = "ExtremeRouter Judge Combo (Frontier Fusion)";
            input = [ "text" ];
          }
          {
            id = "deepseek-swarm";
            name = "ExtremeRouter DeepSeek Swarm Combo";
            input = [ "text" ];
          }
          {
            id = "ag/claude-sonnet-4-6";
            name = "Claude Sonnet 4.6 (Antigravity via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "ag/claude-opus-4-6-thinking";
            name = "Claude Opus 4.6 Thinking (Antigravity via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "ag/gemini-3.6-flash-high";
            name = "Gemini 3.6 Flash High (Antigravity via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "ag/gemini-3-flash";
            name = "Gemini 3 Flash (Antigravity via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "ag/gemini-pro-agent";
            name = "Gemini Pro Agent (Antigravity via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "kr/claude-sonnet-4.5";
            name = "Claude Sonnet 4.5 (Kiro via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "kr/claude-haiku-4.5";
            name = "Claude Haiku 4.5 (Kiro via ER)";
            input = [
              "text"
              "image"
            ];
          }
          {
            id = "kr/deepseek-3.2";
            name = "DeepSeek 3.2 (Kiro via ER)";
            input = [ "text" ];
          }
          {
            id = "ocg/mimo-v2.5-pro";
            name = "MiMo V2.5 Pro (OpenCode Go via ER)";
            input = [ "text" ];
          }
          {
            id = "xmtp/mimo-v2.5-pro";
            name = "MiMo V2.5 Pro (Xiaomi Token Plan via ER)";
            input = [ "text" ];
          }
          {
            id = "nvidia/deepseek-ai/deepseek-v4-pro";
            name = "DeepSeek V4 Pro (NVIDIA NIM via ER)";
            input = [ "text" ];
          }
          {
            id = "nvidia/deepseek-ai/deepseek-v4-flash";
            name = "DeepSeek V4 Flash (NVIDIA NIM via ER)";
            input = [ "text" ];
          }
          {
            id = "nvidia/z-ai/glm-5.2";
            name = "GLM 5.2 (NVIDIA NIM via ER)";
            input = [ "text" ];
          }
          {
            id = "nvidia/moonshotai/kimi-k2.6";
            name = "Kimi K2.6 (NVIDIA NIM via ER)";
            input = [ "text" ];
          }
          {
            id = "cx/gpt-5.3-codex";
            name = "GPT-5.3 Codex (Codex via ER)";
            input = [ "text" ];
          }
          {
            id = "groq/llama-3.3-70b-versatile";
            name = "Llama 3.3 70B Versatile (Groq via ER)";
            input = [ "text" ];
          }
          {
            id = "cerebras/llama-3.3-70b";
            name = "Llama 3.3 70B (Cerebras via ER)";
            input = [ "text" ];
          }
          {
            id = "ollama/qwen3.5";
            name = "Qwen 3.5 (Ollama via ER)";
            input = [ "text" ];
          }
        ];

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
              apiKey = piApiKeyCmd;
              models = explicitKongModels;
            };
            nami = {
              baseUrl = "http://nami:8090/v1";
              api = "openai-completions";
              apiKey = piApiKeyCmd;
              models = explicitKongModels;
            };
            jev = {
              baseUrl = "http://127.0.0.1:20127/v1";
              api = "openai-completions";
              apiKey = piApiKeyCmd;
              models = [
                {
                  id = "voice-fast";
                  name = "Jev Tier: Voice Fast (Penny-Pincher)";
                  input = [ "text" ];
                }
                {
                  id = "free-first";
                  name = "Jev Tier: Free First (Free Swarm)";
                  input = [ "text" ];
                }
                {
                  id = "cascade-balanced";
                  name = "Jev Tier: Cascade Balanced (Coding)";
                  input = [
                    "text"
                    "image"
                  ];
                }
                {
                  id = "frontier";
                  name = "Jev Tier: Frontier (Judge / Research)";
                  input = [
                    "text"
                    "image"
                  ];
                }
              ]
              ++ explicitKongModels;
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

        piModelsBaseFile = pkgs.writeText "pi-models-base.json" (builtins.toJSON piModels);

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

          # Pi MCP Servers (~/.pi/agent/mcp.json and ~/.config/pi/agent/mcp.json)
          home.file.".pi/agent/mcp.json".text = builtins.toJSON piMcp;
          xdg.configFile."pi/agent/mcp.json".text = builtins.toJSON piMcp;

          # Generate ~/.pi/agent/models.json and ~/.config/pi/agent/models.json at activation time,
          # pulling explicit model IDs from Kong /v1/models when reachable and merging with baseline.
          home.activation.syncPiModelsFromKong = {
            after = [ "writeBoundary" ];
            before = [ ];
            data = ''
              for target_dir in "$HOME/.pi/agent" "$HOME/.config/pi/agent"; do
                mkdir -p "$target_dir"
                rm -f "$target_dir/models.json"
                cp "${piModelsBaseFile}" "$target_dir/models.json"
                chmod 0644 "$target_dir/models.json"
              done
              KONG_KEY=""
              if [ -r "$HOME/.config/sops-nix/secrets/kong_key_pi" ]; then
                KONG_KEY="$(cat "$HOME/.config/sops-nix/secrets/kong_key_pi")"
              elif [ -r "/run/secrets/kong_key_pi" ]; then
                KONG_KEY="$(cat "/run/secrets/kong_key_pi")"
              fi
              if [ -n "$KONG_KEY" ]; then
                ${pkgs.python3}/bin/python3 - "$KONG_KEY" "${cfg.routerEndpoint}" <<'PYEOF' || true
              import json, os, sys, urllib.request
              key, base_url = sys.argv[1], sys.argv[2].rstrip("/")
              req = urllib.request.Request(f"{base_url}/models", headers={"apikey": key})
              with urllib.request.urlopen(req, timeout=4) as resp:
                  payload = json.loads(resp.read().decode())
              live_ids = [m["id"] for m in payload.get("data", []) if isinstance(m, dict) and m.get("id")]
              if live_ids:
                  for p in [os.path.expanduser("~/.pi/agent/models.json"), os.path.expanduser("~/.config/pi/agent/models.json")]:
                      with open(p, "r") as f:
                          doc = json.load(f)
                      existing = {m["id"]: m for m in doc["providers"]["kong"]["models"]}
                      for mid in live_ids:
                          if mid not in existing:
                              existing[mid] = {"id": mid, "name": mid, "input": ["text"]}
                      merged = list(existing.values())
                      doc["providers"]["kong"]["models"] = merged
                      if "nami" in doc["providers"]:
                          doc["providers"]["nami"]["models"] = merged
                      with open(p, "w") as f:
                          json.dump(doc, f, indent=2)
              PYEOF
              fi
            '';
          };
        };
      };
  };
}
