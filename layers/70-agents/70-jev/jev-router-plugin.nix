# Tier: 78-llm-routers
# Module: jev-router-plugin.nix
# Purpose: Jev System-1 LLM Router Pre-Flight Hook — routes, prunes, and suppresses tokens before Kong/ExtremeRouter.
# Option Path: layers.layer-78.llm-routers.jev-router-plugin
# Enabling Host Tags: ai-router, ai-agent, homelab
# RAM Footprint: minimal (<80MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-78.llm-routers.jev-router-plugin;
in
{
  options.layers.layer-78.llm-routers.jev-router-plugin = {
    enable = lib.mkEnableOption "Jev System-1 LLM Router Pre-Flight Hook";

    port = lib.mkOption {
      type = lib.types.port;
      default = 20127;
      description = "Port to listen on for pre-flight routing";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host IP to bind to (loopback/tailnet only; sits behind Kong)";
    };

    upstreamRouterUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://100.64.0.1:20128";
      description = "Upstream primary router URL (ExtremeRouter)";
    };

    jevEngineUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Local Jev decision engine URL";
    };

    localSlmUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Local SLM provider endpoint (e.g. Ollama)";
    };

    openFirewall = lib.mkEnableOption "opening port in firewall (disabled by default; accessed via Kong)";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jev-router-plugin = {
      description = "Jev Tier Router — Async Streaming Decision-Only Proxy";
      after = [
        "network.target"
        "jev-engine.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JEV_ROUTER_HOST = cfg.host;
        JEV_ROUTER_PORT = toString cfg.port;
        UPSTREAM_ROUTER_URL = cfg.upstreamRouterUrl;
        JEV_ENGINE_URL = cfg.jevEngineUrl;
        LOCAL_SLM_URL = cfg.localSlmUrl;
      };

      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./jev-router-proxy.py}";
        Restart = "always";
        RestartSec = 3;
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
