# 🌐 Central Service Endpoints Registry
#
# Single source of truth for service ports, hostnames, and base URLs across the fleet.
# Modules consume `config.layers.layer-20.endpoints.<service>.baseUrl` instead of hardcoding IP addresses or ports.
# Evaluates fleet-wide port uniqueness via build-time assertions.
{ config, lib, ... }:
with lib;
let
  mkEndpoint = host: port: path: {
    inherit host port path;
    baseUrl = "http://${host}:${toString port}${path}";
  };
in
{
  options.layers.layer-20.endpoints = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; };
          path = mkOption {
            type = types.str;
            default = "";
          };
          baseUrl = mkOption { type = types.str; };
        };
      }
    );
    default = {
      extreme-router = mkEndpoint "127.0.0.1" (config.layers.layer-78.llm-routers.extreme-router.port
        or 20128
      ) "/v1";
      freellmapi = mkEndpoint "127.0.0.1" (config.services.ai-services.freellmapi.port or 3001) "/v1";
      freellmpool = mkEndpoint "127.0.0.1" (config.services.ai-services.freellmpool.port or 8083) "/v1";
      manifest = mkEndpoint "127.0.0.1" (config.services.ai-services.manifest.port or 2099) "/v1";
      kong = mkEndpoint "127.0.0.1" (config.services.ai-services.kong-gateway.proxyPort or 8090) "/v1";
      jev-router = mkEndpoint "127.0.0.1" (config.layers.layer-78.llm-routers.jev-router-plugin.port
        or 20127
      ) "/v1";
      ollama = mkEndpoint "127.0.0.1" (config.layers.layer-74.ai-infra.ollama.port or 11434) "/v1";
      hermes-gateway = mkEndpoint "127.0.0.1" (config.layers.layer-76.hermes.gatewayPort or 8085) "";
      context-forge = mkEndpoint "127.0.0.1" (config.layers.layer-20.services.context-forge.port or 8094
      ) "/mcp";
      camofox = mkEndpoint "127.0.0.1" 9377 "";
      signal = mkEndpoint "127.0.0.1" 8080 "";
      langfuse = mkEndpoint "127.0.0.1" 3005 "";
      matrix = mkEndpoint "matrix.local" 8008 "";
      polyfloor = mkEndpoint "127.0.0.1" (
        if config.services ? polyfloor then config.services.polyfloor.port else 7777
      ) "";
      gno = mkEndpoint "127.0.0.1" (config.layers.layer-73.memory.gno.port or 3456) "";
    };
    description = "Central registry for service network endpoints across the fleet.";
  };

  config = {
    # Static Headscale tailnet host mappings so container --network=host and CLI harnesses
    # resolve fleet nodes (and legacy `nami` router alias -> sanji) in <1ms without DNS recursion lag.
    networking.extraHosts = mkAfter ''
      100.64.0.1 z0r0.nfp.nix z0r0
      100.64.0.3 luffy.nfp.nix luffy
      100.64.0.6 sanji.nfp.nix sanji nami
    '';

    assertions = [
      {
        assertion =
          let
            endpointsList = builtins.attrValues config.layers.layer-20.endpoints;
            portsList = map (e: e.port) endpointsList;
            uniquePortsList = lib.unique portsList;
          in
          builtins.length portsList == builtins.length uniquePortsList;
        message = "Fleet port collision detected in layers.layer-20.endpoints! All assigned service ports must be unique.";
      }
    ];
  };
}
