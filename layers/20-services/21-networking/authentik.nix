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
    # Port 6381 chosen to avoid collision with honcho-redis (6379) and Nextcloud (6380)
    services.redis.servers.authentik = {
      enable = true;
      port = 6381;
      bind = "127.0.0.1";
    };

    # PostgreSQL database provisioning
    clan.core.postgresql = {
      enable = true;
      databases.authentik.create.enable = true;
    };

    systemd = {
      services.postgresql-authentik-setup = {
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

      tmpfiles.rules = [
        "d /var/lib/authentik 0755 root root -"
        "d /var/lib/authentik/media 0755 root root -"
        "d /var/lib/authentik/custom-templates 0755 root root -"
        "d /var/lib/authentik/blueprints 0755 root root -"
      ];

      services.authentik-blueprint-sync = {
        description = "Synchronize Authentik Media Suite Blueprints";
        wantedBy = [ "multi-user.target" ];
        before = [ "podman-authentik-server.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "sync-authentik-blueprints" ''
            mkdir -p /var/lib/authentik/blueprints
            cp -f /etc/authentik/blueprints/media-suite.yaml /var/lib/authentik/blueprints/media-suite.yaml
          '';
        };
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
        AUTHENTIK_REDIS__PORT=6381
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
          AUTHENTIK_REDIS__PORT = "6381";
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
          "/var/lib/authentik/blueprints:/blueprints/custom"
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
          AUTHENTIK_REDIS__PORT = "6381";
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
          "/var/lib/authentik/blueprints:/blueprints/custom"
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

    # Provision default application catalog blueprint for user dashboard
    environment.etc."authentik/blueprints/media-suite.yaml" = {
      text = ''
        version: 1
        metadata:
          name: LoveLain Media Suite
        entries:
          - model: authentik_core.application
            identifiers:
              slug: jellyfin
            attrs:
              name: Jellyfin Cinema
              slug: jellyfin
              meta_launch_url: https://jellyfin.${publicDomain}
              meta_description: 4K HDR Movie & Television Streaming
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            identifiers:
              slug: audiobookshelf
            attrs:
              name: Audiobookshelf
              slug: audiobookshelf
              meta_launch_url: https://audiobooks.${publicDomain}
              meta_description: Unabridged Audiobooks & Podcasts
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            identifiers:
              slug: komga
            attrs:
              name: Komga Manga & Comics
              slug: komga
              meta_launch_url: https://komga.${publicDomain}
              meta_description: Digital Manga & Graphic Novels
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            identifiers:
              slug: calibre-web
            attrs:
              name: Calibre-Web Literature
              slug: calibre-web
              meta_launch_url: https://calibre.${publicDomain}
              meta_description: E-Books & Literary Manuscripts
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            identifiers:
              slug: navidrome
            attrs:
              name: Navidrome & Feishin
              slug: navidrome
              meta_launch_url: https://navidrome.${publicDomain}
              meta_description: High-Fidelity Lossless Music Streaming
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            identifiers:
              slug: searxng
            attrs:
              name: SearXNG Metasearch
              slug: searxng
              meta_launch_url: https://search.${publicDomain}
              meta_description: Private Decentralized Search Engine
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
      '';
    };

    # Public Caddy Virtual Hosts
    # Strict Boundary: Only Authentik, the shared media suite, and SearXNG receive public routes.
    # Everything else is strictly Tailnet-only.
    services.caddy.virtualHosts = {
      "${cfg.domain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:${toString cfg.port}
        '';
      };
    }
    // (mkIf cfg.publicMediaServices {
      # Calibre-Web
      "calibre.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:${toString (config.services.calibre-web-app.port or 7119)}
        '';
      };

      # Komga
      "komga.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:25600
        '';
      };

      # Audiobookshelf
      "audiobooks.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:9292
        '';
      };

      # Jellyfin
      "jellyfin.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:8096
        '';
      };

      # Navidrome (hosted on z0r0 via encrypted Tailnet)
      "navidrome.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy http://100.64.0.1:4533
        '';
      };

      # SearXNG
      "search.${publicDomain}" = {
        useACMEHost = publicDomain;
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:8888
        '';
      };
    });
  };
}
