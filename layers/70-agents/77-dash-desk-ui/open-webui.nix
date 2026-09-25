# Tier: 77-dash-desk-ui
# Module: open-webui.nix
# Purpose: Full-featured chat & RAG user interface supporting multi-user LLM interactions.
# Option Path: services.ai-services.open-webui
# Enabling Host Tags: desktop, workstation, homelab
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.ai-services.open-webui = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Open WebUI for LLM interfaces";
    };

    port = mkOption {
      type = types.int;
      default = 8088;
      description = "Open WebUI port";
    };
  };

  config =
    let
      cfg = config.services.ai-services.open-webui;
    in
    mkMerge [
      {
        nfp.services.open-webui = {
          enable = config.services.ai-services.open-webui.enable;
          host = config.networking.hostName;
          port = 8088;
          homepage = {
            enable = true;
            category = "agents";
            order = 60;
            title = "Open WebUI";
            subtitle = "LLM Chat Interface";
            icon = "open-webui";
            metric = {
              mode = "health-only";
            };
          };
          healthcheck = {
            enable = true;
            path = "/health";
            expectedStatus = 200;
          };
        };
      }
      (mkIf cfg.enable {
        services.open-webui = {
          enable = true;
          host = "127.0.0.1";
          inherit (cfg) port;
          openFirewall = false;
          environment = {
            OLLAMA_API_BASE_URL = "http://localhost:11434";
            WEBUI_AUTH = "true";
            OPENAI_API_BASE_URLS = "http://127.0.0.1:8642";
          };
        };
      })
    ];
}
