# Tier: 76-orchestrators
# Module: langgraph.nix
# Purpose: LangGraph stateful multi-agent flow runtime and graph execution server.
# Option Path: services.ai-services.langgraph
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services.langgraph = {
    enable = mkEnableOption "LangGraph — multi-agent orchestration layer";

    port = mkOption {
      type = types.port;
      default = 8100;
      description = "LangGraph API port (metrics, health)";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address";
    };

    kongUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8090";
      description = "Kong Gateway URL for LLM calls (supports /v1, /omni/v1, /llm/free/v1, /llm/frontier/v1, or extreme-direct at :20128/v1)";
    };

    kongApiKey = mkOption {
      type = types.str;
      default = "";
      description = "Kong API key for LangGraph (consumer: langgraph)";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/langgraph";
      description = "Data directory for workflow state";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to env file with additional secrets";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables";
    };
  };

  config =
    let
      cfg = config.services.ai-services.langgraph;

      # Python environment with LangGraph + LangChain
      langgraphEnv = pkgs.python3.withPackages (
        ps: with ps; [
          langgraph
          langchain-core
          langchain-community
          httpx
          pydantic
          python-dotenv
          prometheus-client
        ]
      );

      # Budget config — maps agent names to monthly token budgets
      budgetConfig = pkgs.writeText "langgraph-budgets.json" (
        builtins.toJSON {
          agents = {
            default = {
              monthly_token_budget = 500000;
              frontier_threshold = 0.8;
              cheap_threshold = 0.95;
              free_threshold = 1.0;
            };
            hermes = {
              monthly_token_budget = 2000000;
              frontier_threshold = 0.7;
              cheap_threshold = 0.9;
              free_threshold = 1.0;
            };
            opencode = {
              monthly_token_budget = 1000000;
              frontier_threshold = 0.5;
              cheap_threshold = 0.85;
              free_threshold = 1.0;
            };
            langgraph-workflows = {
              monthly_token_budget = 5000000;
              frontier_threshold = 0.6;
              cheap_threshold = 0.9;
              free_threshold = 1.0;
            };
          };
          routes = {
            frontier = "/llm/frontier/v1/chat/completions";
            coding = "/llm/coding/v1/chat/completions";
            cheap = "/llm/v1/chat/completions";
            free = "/llm/free/v1/chat/completions";
          };
        }
      );
    in
    mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 langgraph langgraph -"
      ];

      users.users.langgraph = {
        isSystemUser = true;
        group = "langgraph";
        description = "LangGraph service user";
      };
      users.groups.langgraph = { };

      # Persist data
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [ cfg.dataDir ];
          };

      # Budget config file
      environment.etc."langgraph/budgets.json".source = budgetConfig;

      # LangGraph service — runs as a persistent Python process
      systemd.services.langgraph = {
        description = "LangGraph — multi-agent orchestration";
        after = [
          "network.target"
          "kong.service"
        ];
        wants = [ "kong.service" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          LANGGRAPH_PORT = toString cfg.port;
          LANGGRAPH_HOST = cfg.host;
          LANGGRAPH_DATA_DIR = cfg.dataDir;
          LANGGRAPH_BUDGET_CONFIG = "/etc/langgraph/budgets.json";
          OPENAI_BASE_URL = "${cfg.kongUrl}/llm/v1";
          OPENAI_API_KEY = cfg.kongApiKey;
          PROMETHEUS_PORT = toString cfg.port;
        }
        // cfg.extraEnv;

        serviceConfig = {
          Type = "simple";
          ExecStart = "${langgraphEnv}/bin/python -m langgraph.server --host ${cfg.host} --port ${toString cfg.port}";
          Restart = "on-failure";
          RestartSec = 5;
          User = "langgraph";
          Group = "langgraph";
          WorkingDirectory = cfg.dataDir;
          EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.dataDir ];
        };
      };

      # CLI helper for budget/status checks
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "langgraph-ctl" ''
          BASE="http://127.0.0.1:${toString cfg.port}"
          case "''${1:-help}" in
            status)
              curl -s "$BASE/health" | ${pkgs.jq}/bin/jq .
              ;;
            budgets)
              curl -s "$BASE/budgets" | ${pkgs.jq}/bin/jq .
              ;;
            metrics)
              curl -s "$BASE/metrics"
              ;;
            workflows)
              curl -s "$BASE/workflows" | ${pkgs.jq}/bin/jq .
              ;;
            *)
              echo "Usage: langgraph-ctl {status|budgets|metrics|workflows}"
              ;;
          esac
        '')
      ];
    };
}
