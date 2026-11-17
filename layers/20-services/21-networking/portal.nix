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

        ${optionalString (config.layers.layer-20.services.auth.authentik.enable or false) ''
          handle /outpost.goauthentik.io/* {
            reverse_proxy localhost:${toString (config.layers.layer-20.services.auth.authentik.port or 9000)}
          }

          # Authenticated identity metadata for the Media Directory UI
          handle /api/me {
            forward_auth localhost:${toString (config.layers.layer-20.services.auth.authentik.port or 9000)} {
              uri /outpost.goauthentik.io/auth/caddy
              copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid
              trusted_proxies private_ranges
            }
            header Content-Type application/json
            header Cache-Control "no-store"
            respond `{"username":"{http.request.header.X-Authentik-Username}","name":"{http.request.header.X-Authentik-Name}","email":"{http.request.header.X-Authentik-Email}","groups":"{http.request.header.X-Authentik-Groups}"}` 200
          }
        ''}

        # Redirect /dash* to dedicated Admin-only subdomain enforced by Authentik NFP Admins policy
        handle /dash* {
          redir https://dash.${cfg.domain} 302
        }

        # Authenticated Media & Gaming Directory at root
        handle {
          ${optionalString (config.layers.layer-20.services.auth.authentik.enable or false) ''
            forward_auth localhost:${toString (config.layers.layer-20.services.auth.authentik.port or 9000)} {
              uri /outpost.goauthentik.io/auth/caddy
              copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid
              trusted_proxies private_ranges
            }
          ''}
          root * ${cfg.package}
          file_server
          try_files {path} /index.html
        }
      '';
    };
  };
}
