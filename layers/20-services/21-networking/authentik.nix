# Tier: 20-services / 21-networking
# Module: authentik.nix
# Purpose: Authentik Identity Provider, SSO Gateway, and OIDC Federation Server.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.auth.authentik;
  publicDomain = config.layers.meta.publicDomain or "lovelain.duckdns.org";
in
{
  options.layers.layer-20.services.auth.authentik = {
    enable = mkEnableOption "Authentik Identity & SSO Provider";

    port = mkOption {
      type = types.port;
      default = 9000;
      description = "Authentik Web UI and API HTTP port";
    };

    domain = mkOption {
      type = types.str;
      default = "auth.${publicDomain}";
      description = "Public domain for Authentik web interface and OIDC endpoints";
    };

    ntfyTopic = mkOption {
      type = types.str;
      default = "nfp-signups";
      description = "Ntfy topic for new user registration and approval alerts";
    };

    publicMediaServices = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Expose public Caddy reverse proxy routes on DuckDNS with TLS for media services:
        Calibre-Web, Komga, Audiobookshelf, Jellyfin, Navidrome, and SearXNG.
        All other internal services remain strictly Tailnet-only.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Homepage and Fleet Contract
    nfp.services.authentik = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "authentik";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/-/health/live/";
        expectedStatus = [ 200 ];
      };
      homepage = {
        enable = true;
        category = "usopp";
        order = 18;
        title = "Authentik";
        subtitle = "Identity & SSO Federation";
        icon = "authentik";
        metric = {
          mode = "health-only";
        };
      };
    };

    # Redis backend instance dedicated to Authentik session caching & task queue
    services.redis.servers.authentik = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
    };

    # PostgreSQL database provisioning
    clan.core.postgresql = {
      enable = true;
      databases.authentik.create.enable = true;
    };

    systemd.services.postgresql-authentik-setup = {
      description = "Ensure Postgres permissions for Authentik";
      wantedBy = [ "multi-user.target" ];
      before = [ "podman-authentik-server.service" ];
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      serviceConfig = {
        User = "postgres";
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "setup-authentik-db" ''
          until ${pkgs.postgresql_16}/bin/pg_isready -q; do
            sleep 1
          done
          ${pkgs.postgresql_16}/bin/psql -d authentik -c "GRANT ALL ON SCHEMA public TO postgres; ALTER SCHEMA public OWNER TO postgres;" || true
        '';
      };
    };

    # Secrets generator for Authentik
    clan.core.vars.generators.authentik = {
      files."authentik.env" = {
        secret = true;
      };
      script = ''
        SECRET_KEY=$(${pkgs.openssl}/bin/openssl rand -base64 36)
        cat <<EOF > "$out/authentik.env"
        AUTHENTIK_SECRET_KEY=$SECRET_KEY
        AUTHENTIK_POSTGRESQL__HOST=127.0.0.1
        AUTHENTIK_POSTGRESQL__NAME=authentik
        AUTHENTIK_POSTGRESQL__USER=postgres
        AUTHENTIK_REDIS__HOST=127.0.0.1
        AUTHENTIK_REDIS__PORT=6379
        AUTHENTIK_REDIS__DB=0
        AUTHENTIK_DISABLE_STARTUP_ANALYTICS=true
        AUTHENTIK_DISABLE_UPDATE_CHECK=true
        AUTHENTIK_ERROR_REPORTING__ENABLED=false
        AUTHENTIK_LISTEN__HTTP=0.0.0.0:9000
        EOF
      '';
    };

    # Podman Containers for Authentik Server & Worker
    virtualisation.oci-containers.containers = {
      authentik-server = {
        image = "ghcr.io/goauthentik/server:2024.12.3";
        cmd = [ "server" ];
        environmentFiles = [
          config.clan.core.vars.generators.authentik.files."authentik.env".path
        ];
        environment = {
          AUTHENTIK_REDIS__HOST = "127.0.0.1";
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
          "/run/postgresql:/run/postgresql"
        ];
        extraOptions = [
          "--network=host"
        ];
      };

      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2024.12.3";
        cmd = [ "worker" ];
        environmentFiles = [
          config.clan.core.vars.generators.authentik.files."authentik.env".path
        ];
        environment = {
          AUTHENTIK_REDIS__HOST = "127.0.0.1";
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
          "/run/postgresql:/run/postgresql"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
    };

    # Persistence for custom sign-in branding, uploaded media, and certs
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        "/var/lib/authentik"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/authentik 0755 root root -"
      "d /var/lib/authentik/media 0755 root root -"
      "d /var/lib/authentik/custom-templates 0755 root root -"
    ];

    # Public Caddy Virtual Hosts
    # Strict Boundary: Only Authentik, the shared media suite, and SearXNG receive public routes.
    # Everything else is strictly Tailnet-only.
    services.caddy.virtualHosts = {
      "http://${cfg.domain}" = {
        extraConfig = ''
          reverse_proxy localhost:${toString cfg.port}
        '';
      };
    }
    // (mkIf cfg.publicMediaServices {
      # Calibre-Web
      "http://calibre.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:${toString (config.services.calibre-web-app.port or 7119)}
        '';
      };

      # Komga
      "http://komga.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:25600
        '';
      };

      # Audiobookshelf
      "http://audiobooks.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:13378
        '';
      };

      # Jellyfin
      "http://jellyfin.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:8096
        '';
      };

      # Navidrome
      "http://navidrome.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:${toString (config.layers.layer-20.services.media.navidrome.port or 4533)}
        '';
      };

      # SearXNG
      "http://search.${publicDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:8888
        '';
      };
    });
  };
}
