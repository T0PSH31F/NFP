# Tier: 78-llm-routers
# Module: jev.nix
# Purpose: Jev System-1 Pre-Flight Classifier Daemon — two-stage zero-token and local SLM triage.
# Option Path: layers.layer-78.llm-routers.jev
# Enabling Host Tags: ai-router, ai-agent, workstation
# RAM Footprint: minimal (<50MB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-78.llm-routers.jev;
in
{
  options.layers.layer-78.llm-routers.jev = {
    enable = mkEnableOption "Jev System-1 Pre-Flight Classifier Daemon";

    port = mkOption {
      type = types.port;
      default = 20127;
      description = "Port to listen on for pre-flight triage and classification";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host IP to bind to";
    };

    ollamaUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:11434";
      description = "Endpoint of local Ollama SLM instance";
    };

    ollamaModel = mkOption {
      type = types.str;
      default = "qwen3.5:9b";
      description = "Local model tag for Stage-2 classification";
    };

    upstreamRouterUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:20128";
      description = "Upstream primary router URL (ExtremeRouter)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.nfp-jev-classifier = {
      description = "Jev System-1 Pre-Flight Classifier Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "ollama.service"
      ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./jev_classifier.py}";
        Restart = "always";
        RestartSec = "3s";
        User = "t0psh31f";
        Environment = [
          "JEV_PORT=${toString cfg.port}"
          "JEV_HOST=${cfg.host}"
          "OLLAMA_URL=${cfg.ollamaUrl}"
          "OLLAMA_MODEL=${cfg.ollamaModel}"
          "UPSTREAM_ROUTER_URL=${cfg.upstreamRouterUrl}"
        ];
      };
    };
  };
}
