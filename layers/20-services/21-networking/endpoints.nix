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
      freellmapi = mkEndpoint "127.0.0.1" (config.layers.layer-78.llm-routers.freellmapi.port or 3003
      ) "/v1";
      ollama = mkEndpoint "127.0.0.1" (config.layers.layer-74.ai-infra.ollama.port or 11434) "/v1";
      hermes-gateway = mkEndpoint "127.0.0.1" (config.layers.layer-76.hermes.gatewayPort or 8085) "";
      context-forge = mkEndpoint "127.0.0.1" (config.layers.layer-20.services.context-forge.port or 8094
      ) "/mcp";
      camofox = mkEndpoint "127.0.0.1" 9377 "";
      signal = mkEndpoint "127.0.0.1" 8080 "";
      langfuse = mkEndpoint "127.0.0.1" 3005 "";
      matrix = mkEndpoint "matrix.local" 8008 "";
      polyfloor = mkEndpoint "127.0.0.1" (config.services.polyfloor.port or 8001) "";
      gno = mkEndpoint "127.0.0.1" (config.layers.layer-73.memory.gno.port or 3456) "";
    };
    description = "Central registry for service network endpoints across the fleet.";
  };

  config = {
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
