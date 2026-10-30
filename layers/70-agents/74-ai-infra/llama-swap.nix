# Tier: 74-ai-infra
# Module: llama-swap.nix
# Purpose: Dynamic model swapper proxy — unloads/loads GGUF models on demand.
# Option Path: services.llama-swap-proxy
# Enabling Host Tags: gpu-compute, ai-server
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  ...
}:

with lib;
{
  options.services.llama-swap-proxy = {
    enable = mkEnableOption "llama-swap Proxy service";

    port = mkOption {
      type = types.port;
      default = 8085;
      description = "Port to listen on";
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Structured settings for llama-swap (e.g. server, models, groups)";
    };
  };

  config =
    let
      cfg = config.services.llama-swap-proxy;
    in
    mkIf cfg.enable {
      services.llama-swap = {
        enable = true;
        inherit (cfg) port;
        inherit (cfg) settings;
      };

      systemd.services.llama-swap.serviceConfig.ProcSubset = lib.mkForce "all";

      networking.firewall.allowedTCPPorts = [ cfg.port ];
    };
}
