# ai-router — LLM routing and gateway services
# Deployed on always-on control-plane machines that route agent LLM requests.
# Primary router: ExtremeRouter (+ Jev Tier Router pre-flight).
# Upstream custom free pools: FreeLLMAPI & freellmpool.
# Unused routers (OmniRoute, Manifest, LiteLLM) are disabled by default.
{ config, lib, ... }:
{
  config = lib.mkIf (lib.elem "ai-router" config.machine.tags) {
    services.ai-services = {
      kong-gateway.enable = lib.mkDefault true;
      omniroute.enable = lib.mkDefault false;
      manifest.enable = lib.mkDefault false;
      freellmapi.enable = lib.mkDefault true;
      freellmpool.enable = lib.mkDefault true;
      postgresql.enable = lib.mkDefault true;
    };

    layers.layer-78.llm-routers = {
      extreme-router.enable = lib.mkDefault true;
      jev-router-plugin.enable = lib.mkDefault true;
    };
  };
}
