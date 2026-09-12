# Tier: 71-harness
# Module: omp.nix
# Purpose: Oh-My-Pi (OMP) terminal AI coding agent harness integration.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
#   kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-71.harness.omp
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
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
  cfg = osConfig.layers.layer-71.harness.omp or { };
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
  sys = pkgs.stdenv.hostPlatform.system;
  ompPkg = inputs.omp.packages.${sys}.default or pkgs.omp or null;
in
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "omp" ] [ "layers" "layer-71" "harness" "omp" ])
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "omp" ]
      [ "layers" "layer-71" "harness" "omp" ]
    )
  ]
  ++ optional (
    inputs ? omp && inputs.omp ? homeManagerModules && inputs.omp.homeManagerModules ? default
  ) inputs.omp.homeManagerModules.default;

  options.layers.layer-71.harness.omp = {
    enable = mkEnableOption "Oh-My-Pi (OMP) AI coding agent harness";

    package = mkOption {
      type = types.nullOr types.package;
      default = ompPkg;
      description = "Package to use for Oh-My-Pi (OMP)";
    };

    defaultModel = mkOption {
      type = types.str;
      default = "mimo-v2.5-pro";
      description = "Default model for OMP agent";
    };

    routerEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8090/v1";
      description = "NFP LLM router OpenAI-compatible gateway endpoint (default: kong-er)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = optional (cfg.package != null) cfg.package;

    environment.sessionVariables = {
      OMP_MODEL = cfg.defaultModel;
      OMP_ROUTER_ENDPOINT = cfg.routerEndpoint;
      OPENAI_BASE_URL = cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = "http://127.0.0.1:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = "http://127.0.0.1:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = "http://127.0.0.1:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = "http://127.0.0.1:8090/llm/frontier/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
    };

    home-manager.users.${user} = { pkgs, ... }: {
      config = {
        xdg.configFile."omp/config.json".text = builtins.toJSON {
          model = cfg.defaultModel;
          apiBase = cfg.routerEndpoint;
          providers = {
            kong-er = {
              baseUrl = "http://127.0.0.1:8090/v1";
            };
            kong-omni = {
              baseUrl = "http://127.0.0.1:8090/omni/v1";
            };
            kong-free = {
              baseUrl = "http://127.0.0.1:8090/llm/free/v1";
            };
            kong-frontier = {
              baseUrl = "http://127.0.0.1:8090/llm/frontier/v1";
            };
            extreme-direct = {
              baseUrl = "http://127.0.0.1:20128/v1";
            };
          };
        };
      };
    };
  };
}
