# Tier: 78-llm-routers
# Module: litellm.nix
# Purpose: LiteLLM proxy server — unified OpenAI-compatible format with cost tracking & load balancing.
# Polyfloor (76-orchestrators) can point services.polyfloor.routerEndpoint here
# (http://127.0.0.1:<port>/v1, its default) and enumerate models via GET /v1/models.
# Option Path: services.litellm-proxy
# Enabling Host Tags: ai-router, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  ...
}:

with lib;
{
  options.services.litellm-proxy = {
    enable = mkEnableOption "LiteLLM Proxy service";

    port = mkOption {
      type = types.port;
      default = 8084;
      description = "Port to listen on";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address to bind to. Set to 127.0.0.1 to restrict access to localhost.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open ports in the firewall for LiteLLM. Note that external exposure also requires setting the host option to a non-loopback address.";
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Structured settings for LiteLLM";
    };
  };

  config =
    let
      cfg = config.services.litellm-proxy;
    in
    mkIf cfg.enable {
      services.litellm = {
        enable = true;
        inherit (cfg) port;
        inherit (cfg) host;
        inherit (cfg) settings;
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
    };
}
