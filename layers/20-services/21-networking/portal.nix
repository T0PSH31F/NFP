# Tier: 20-services / 21-networking
# Module: portal.nix
# Purpose: LoveLain Cyberia Guest Portal and Authenticated Media Launchpad
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.networking.portal;
  publicDomain = config.layers.meta.publicDomain or "lovelain.duckdns.org";

  portalPkg = pkgs.stdenv.mkDerivation {
    name = "lovelain-cyberia-portal";
    src = ./portal;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
{
  options.layers.layer-20.services.networking.portal = {
    enable = mkEnableOption "LoveLain Cyberia Guest Portal & Launchpad";

    package = mkOption {
      type = types.package;
      default = portalPkg;
      description = "Derivation containing static portal web assets";
    };

    domain = mkOption {
      type = types.str;
      default = publicDomain;
      description = "Root domain to serve the guest portal";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Caddy VirtualHost for root public domain
    services.caddy.virtualHosts."${cfg.domain}" = {
      useACMEHost = cfg.domain;
      extraConfig = ''
        encode zstd gzip
        header Strict-Transport-Security "max-age=31536000; includeSubDomains"

        # Operator/Admin proxy route to internal Homepage dashboard
        @internalDash path /dash*
        handle @internalDash {
          reverse_proxy localhost:3007
        }

        # Root static file server for Guest Portal & Member Launchpad
        root * ${cfg.package}
        file_server
        try_files {path} /index.html
      '';
    };
  };
}
