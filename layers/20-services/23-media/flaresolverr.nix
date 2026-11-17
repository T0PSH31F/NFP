# layers/20-services/23-media/flaresolverr.nix
# FlareSolverr — Cloudflare challenge solver proxy for Prowlarr indexers
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.flaresolverr;
in
{
  options.layers.layer-20.services.config.flaresolverr = {
    enable = mkEnableOption "FlareSolverr Cloudflare challenge proxy for Prowlarr";

    port = mkOption {
      type = types.port;
      default = 8191;
      description = "Port FlareSolverr listens on.";
    };
  };

  config = mkIf cfg.enable {
    services.flaresolverr = {
      enable = true;
      inherit (cfg) port;
      openFirewall = false;
    };

    nfp.services.flaresolverr = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "flaresolverr";
      tls = "headscale";
      healthcheck = {
        enable = false;
        skipReason = "Internal Prowlarr Cloudflare solver";
        systemdUnit = "flaresolverr.service";
      };
      homepage.enable = false;
    };
  };
}
