# Tier: 78-llm-routers
# Module: jev-proxy.nix
# Purpose: Enterprise Jarvis System-1 Pre-Flight Proxy & Multi-Channel Webhook Ingress (:20127)
# Option Path: layers.layer-78.llm-routers.jev-proxy
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-78.llm-routers.jev-proxy;
in
{
  options.layers.layer-78.llm-routers.jev-proxy = {
    enable = mkEnableOption "Enterprise Jarvis System-1 Pre-Flight Proxy & Webhook Ingress";

    channels = mkOption {
      type = types.listOf types.str;
      default = [
        "twilio"
        "telnyx"
        "slack"
        "discord"
        "matrix"
      ];
      description = "Enabled multi-channel webhook ingress adapters on :20127";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."jarvis/jev-channels.json".text = builtins.toJSON {
      inherit (cfg) channels;
    };
  };
}
