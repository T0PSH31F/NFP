# Tier: 71-harness
# Module: kilocode.nix
# Purpose: Kilo Code terminal AI agent & IDE extension harness integration (Roo/Cline lineage).
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://nami:8090/v1 (ExtremeRouter)
#   kong-omni:     http://nami:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://nami:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://nami:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-71.harness.kilocode
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
  cfg = osConfig.layers.layer-71.harness.kilocode or { };
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
  kiloPkg = pkgs.kilocode or pkgs.kilo or null;
in
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "kilocode" ] [ "layers" "layer-71" "harness" "kilocode" ])
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "kilocode" ]
      [ "layers" "layer-71" "harness" "kilocode" ]
    )
  ];

  options.layers.layer-71.harness.kilocode = {
    enable = mkEnableOption "Kilo Code AI agent CLI";

    package = mkOption {
      type = types.nullOr types.package;
      default = kiloPkg;
      description = "Package to use for Kilo Code CLI";
    };

    defaultModel = mkOption {
      type = types.str;
      default = "mimo-v2.5-pro";
      description = "Default model for Kilo Code";
    };

    routerEndpoint = mkOption {
      type = types.str;
      default = "http://nami:8090/v1";
      description = "NFP LLM router OpenAI-compatible gateway endpoint (default: kong-er)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = optional (cfg.package != null) cfg.package;

    environment.sessionVariables = {
      KILO_MODEL = cfg.defaultModel;
      KILO_ROUTER_ENDPOINT = cfg.routerEndpoint;
      OPENAI_BASE_URL = cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = lib.mkDefault "http://nami:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = "http://nami:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = "http://nami:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = "http://nami:8090/llm/frontier/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
    };

    home-manager.users.${user} = { pkgs, ... }: {
      config = {
        # Declarative ~/.config/kilo configuration (OpenCode-compatible structure)
        xdg.configFile."kilo/config.json".text = builtins.toJSON {
          model = cfg.defaultModel;
          apiBase = cfg.routerEndpoint;
          providers = {
            kong-er = {
              baseUrl = "http://nami:8090/v1";
              name = "Kong ExtremeRouter";
            };
            kong-omni = {
              baseUrl = "http://nami:8090/omni/v1";
              name = "Kong OmniRoute (TODO: when merged)";
            };
            kong-free = {
              baseUrl = "http://nami:8090/llm/free/v1";
              name = "Kong FreeLLMPool";
            };
            kong-frontier = {
              baseUrl = "http://nami:8090/llm/frontier/v1";
              name = "Kong Frontier Manifest";
            };
            extreme-direct = {
              baseUrl = "http://127.0.0.1:20128/v1";
              name = "ExtremeRouter Direct (Backup)";
            };
          };
          mcpServers = { };
        };
      };
    };
  };
}
