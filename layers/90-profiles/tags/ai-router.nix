# ai-router — LLM routing and gateway services
# Deployed on always-on control-plane machines that route agent LLM requests.
# Primary router: ExtremeRouter (+ Jev Tier Router pre-flight).
# Standalone FreeLLMAPI/FreeLLMPool are DEPRECATED; free providers consolidated in ExtremeRouter.
# Kong Gateway is REMOVED from LLM request path (SSE buffering caused agent stalls).
# Unused routers (OmniRoute, Manifest, LiteLLM) are disabled by default.
{ config, lib, ... }:
{
  config = lib.mkIf (lib.elem "ai-router" config.machine.tags) {
    services.ai-services = {
      kong-gateway.enable = lib.mkDefault false;
      omniroute.enable = lib.mkDefault false;
      manifest.enable = lib.mkDefault false;
      freellmapi.enable = lib.mkDefault false;
      freellmpool.enable = lib.mkDefault false;
      postgresql.enable = lib.mkDefault true;
    };

    layers.layer-78.llm-routers = {
      extreme-router.enable = lib.mkDefault true;
      jev-router-plugin.enable = lib.mkDefault false;
      jev.enable = lib.mkDefault true;
    };
  };
}
