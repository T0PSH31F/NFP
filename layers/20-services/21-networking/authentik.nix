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
  ntfyPort = config.layers.layer-20.services.config.ntfy-sh.port or 8099;
  calibrePort = config.services.calibre-web-app.port or 7119;
  forwardAuthCaddy = upstream: ''
    handle /outpost.goauthentik.io/* {
      reverse_proxy localhost:${toString cfg.port}
    }
    handle {
      forward_auth localhost:${toString cfg.port} {
        uri /outpost.goauthentik.io/auth/caddy
        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
        trusted_proxies private_ranges
      }
      reverse_proxy ${upstream}
    }
  '';
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
        description = "Provision PostgreSQL user, bootstrap credentials, and OIDC secrets for Authentik";
        wantedBy = [ "multi-user.target" ];
        before = [
          "podman-authentik-server.service"
          "podman-authentik-worker.service"
        ];
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
        path = [
          pkgs.openssl
          pkgs.postgresql_16
          pkgs.util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
                    install -d -m 0755 /var/lib/authentik
                    RUNTIME_ENV="/var/lib/authentik/runtime.env"
                    ADMIN_FILE="/var/lib/authentik/bootstrap-admin.txt"
                    if [ ! -s "$RUNTIME_ENV" ]; then
                      PG_PW="$(openssl rand -hex 24)"
                      ADMIN_PW="$(openssl rand -hex 16)"
                      API_TOKEN="$(openssl rand -hex 32)"
                      ROMM_SECRET="$(openssl rand -hex 24)"
                      KOMGA_SECRET="$(openssl rand -hex 24)"
                      ABS_SECRET="$(openssl rand -hex 24)"
                      JELLYFIN_SECRET="$(openssl rand -hex 24)"
                      umask 077
                      cat > "$RUNTIME_ENV" <<EOF
          AUTHENTIK_POSTGRESQL__USER=authentik
          AUTHENTIK_POSTGRESQL__PASSWORD=$PG_PW
          AUTHENTIK_BOOTSTRAP_EMAIL=wrighterik77@gmail.com
          AUTHENTIK_BOOTSTRAP_PASSWORD=$ADMIN_PW
          AUTHENTIK_BOOTSTRAP_TOKEN=$API_TOKEN
          OIDC_ROMM_SECRET=$ROMM_SECRET
          OIDC_KOMGA_SECRET=$KOMGA_SECRET
          OIDC_AUDIOBOOKSHELF_SECRET=$ABS_SECRET
          OIDC_JELLYFIN_SECRET=$JELLYFIN_SECRET
          EOF
                      cat > "$ADMIN_FILE" <<EOF
          username=t0psh31f
          email=wrighterik77@gmail.com
          password=$ADMIN_PW
          EOF
                    fi
                    if [ -s "$RUNTIME_ENV" ] && ! grep -q '^OIDC_JELLYFIN_SECRET=' "$RUNTIME_ENV"; then
                      JELLYFIN_SECRET="$(openssl rand -hex 24)"
                      printf 'OIDC_JELLYFIN_SECRET=%s\n' "$JELLYFIN_SECRET" >> "$RUNTIME_ENV"
                    fi
                    set -a
                    . "$RUNTIME_ENV"
                    set +a
                    until runuser -u postgres -- pg_isready -q; do
                      sleep 1
                    done
                    runuser -u postgres -- psql -v ON_ERROR_STOP=1 <<SQL
          DO \$\$
          BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authentik') THEN
              CREATE ROLE authentik LOGIN PASSWORD '$AUTHENTIK_POSTGRESQL__PASSWORD' CREATEDB;
            ELSE
              ALTER ROLE authentik WITH LOGIN PASSWORD '$AUTHENTIK_POSTGRESQL__PASSWORD' CREATEDB;
            END IF;
          END
          \$\$;
          ALTER DATABASE authentik OWNER TO authentik;
          SQL
                    runuser -u postgres -- psql -d authentik -c "GRANT ALL ON SCHEMA public TO authentik; ALTER SCHEMA public OWNER TO authentik;" || true
        '';
      };

      tmpfiles.rules = [
        "d /var/lib/authentik 0755 root root -"
        "d /var/lib/authentik/media 0755 1000 1000 -"
        "Z /var/lib/authentik/media 0755 1000 1000 -"
        "d /var/lib/authentik/custom-templates 0755 root root -"
        "d /var/lib/authentik/blueprints 0755 root root -"
      ];

      services.authentik-blueprint-sync = {
        description = "Synchronize Authentik Media Suite Blueprints";
        wantedBy = [ "multi-user.target" ];
        before = [
          "podman-authentik-server.service"
          "podman-authentik-worker.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "sync-authentik-blueprints" ''
            mkdir -p /var/lib/authentik/blueprints /var/lib/authentik/media/public /var/lib/authentik/custom-templates/if
            cp -f /etc/authentik/blueprints/media-suite.yaml /var/lib/authentik/blueprints/media-suite.yaml
            cp -f /etc/authentik/custom.css /var/lib/authentik/custom.css
            cp -f /etc/authentik/templates/if/flow.html /var/lib/authentik/custom-templates/if/flow.html
            cp -f ${./portal/assets}/* /var/lib/authentik/media/public/
            chown -R 1000:1000 /var/lib/authentik/media/public
            chmod 0644 /var/lib/authentik/custom.css /var/lib/authentik/custom-templates/if/flow.html /var/lib/authentik/media/public/*
          '';
        };
      };

      services.podman-authentik-server = {
        after = [
          "postgresql-authentik-setup.service"
          "authentik-blueprint-sync.service"
          "redis-authentik.service"
        ];
        requires = [
          "postgresql-authentik-setup.service"
          "authentik-blueprint-sync.service"
          "redis-authentik.service"
        ];
      };

      services.podman-authentik-worker = {
        after = [
          "postgresql-authentik-setup.service"
          "authentik-blueprint-sync.service"
          "redis-authentik.service"
        ];
        requires = [
          "postgresql-authentik-setup.service"
          "authentik-blueprint-sync.service"
          "redis-authentik.service"
        ];
      };
    };

    # Resolve local public subdomains to luffy's LAN IP (never 127.0.0.1, because AdGuardHome
    # reads /etc/hosts and would hand 127.0.0.1 to LAN/Tailnet clients!).
    # Keeps OIDC discovery on luffy local while routing LAN browsers straight to luffy.
    networking.hosts."${config.layers.layer-20.services.networking.adguard.gatewayIp or "192.168.1.54"
    }" =
    [
      cfg.domain
      publicDomain
    ]
    ++ optionals cfg.publicMediaServices [
      "audiobooks.${publicDomain}"
      "calibre.${publicDomain}"
      "komga.${publicDomain}"
      "jellyfin.${publicDomain}"
      "navidrome.${publicDomain}"
      "romm.${publicDomain}"
      "requests.${publicDomain}"
      "search.${publicDomain}"
      "dash.${publicDomain}"
    ];

    sops.secrets = {
      authentik_google_client_id = {
        sopsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;
        key = "google_oauth_lovelain_client_id";
      };
      authentik_google_client_secret = {
        sopsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;
        key = "google_oauth_lovelain_client_secret";
      };
      authentik_smtp_pass = {
        sopsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;
        key = "smtp_pass";
      };
    };

    sops.templates."authentik-oauth.env" = {
      content = ''
        NFP_GOOGLE_CLIENT_ID=${config.sops.placeholder.authentik_google_client_id}
        NFP_GOOGLE_CLIENT_SECRET=${config.sops.placeholder.authentik_google_client_secret}
        AUTHENTIK_EMAIL__HOST=smtp.gmail.com
        AUTHENTIK_EMAIL__PORT=587
        AUTHENTIK_EMAIL__USERNAME=wrighterik77@gmail.com
        AUTHENTIK_EMAIL__PASSWORD=${config.sops.placeholder.authentik_smtp_pass}
        AUTHENTIK_EMAIL__USE_TLS=true
        AUTHENTIK_EMAIL__FROM=LoveLain Cyberia <wrighterik77@gmail.com>
      '';
      mode = "0600";
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
        AUTHENTIK_POSTGRESQL__USER=authentik
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
          "/var/lib/authentik/runtime.env"
          config.sops.templates."authentik-oauth.env".path
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
          "/var/lib/authentik/custom.css:/web/dist/custom.css:ro"
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
          "/var/lib/authentik/runtime.env"
          config.sops.templates."authentik-oauth.env".path
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
          "/var/lib/authentik/custom.css:/web/dist/custom.css:ro"
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

    # Override default Authentik flow template so flow_background.jpg is never prefetched or injected
    environment.etc."authentik/templates/if/flow.html".text = ''
      {% extends "base/skeleton.html" %}

      {% load static %}
      {% load authentik_core %}

      {% block head_before %}
      {{ block.super }}
      {% if flow.compatibility_mode and not inspector %}
      <script>ShadyDOM = { force: !navigator.webdriver };</script>
      {% endif %}
      {% include "base/header_js.html" %}
      <script>
      window.authentik.flow = {
          "layout": "{{ flow.layout }}",
      };
      </script>
      {% endblock %}

      {% block head %}
      <script src="{% versioned_script 'dist/flow/FlowInterface-%v.js' %}" type="module"></script>
      <style>
      :root {
          --ak-flow-background: url("/media/public/bg-dis-03.gif");
      }
      </style>
      <script>
      window.addEventListener("DOMContentLoaded", function () {
        var brandTitle = (window.authentik && window.authentik.brand && window.authentik.brand.branding_title) || "LoveLain";
        var fixTitle = function () {
          if (document.title.indexOf(" - undefined") !== -1) {
            document.title = document.title.replace(/ - undefined$/, " - " + brandTitle);
          }
        };
        var t = document.querySelector("title");
        if (t) new MutationObserver(fixTitle).observe(t, { childList: true });
        fixTitle();
      });
      </script>
      {% endblock %}

      {% block body %}
      <ak-message-container></ak-message-container>
      <ak-flow-executor flowSlug="{{ flow.slug }}">
          <ak-loading></ak-loading>
      </ak-flow-executor>
      {% endblock %}
    '';

    # Fauux Wired 2.0 Custom CSS injected into Authentik root + Shadow DOM
    environment.etc."authentik/custom.css".text = ''
      :root, :host {
        color-scheme: dark;
        --ak-accent: #d2738a;
        --ak-dark-background: #000000;
        --ak-dark-background-darker: #000000;
        --ak-dark-background-light: #09060b;
        --ak-dark-background-light-ish: #100b13;
        --ak-dark-background-lighter: #18101c;
        --ak-dark-foreground: #dfd5bc;
        --ak-dark-foreground-darker: #c1b492;
        --ak-dark-foreground-link: #d2738a;
        --ak-global--Color--100: #dfd5bc;
        --ak-flow-background: url("/media/public/bg-dis-03.gif") !important;
        --pf-c-background-image--BackgroundColor: #d2738a;
        --pf-c-background-image--BackgroundImage: url("/media/public/bg-dis-03.gif");
        --pf-c-background-image--BackgroundImage-2x: url("/media/public/bg-dis-03.gif");
        --pf-c-background-image--BackgroundImage--sm: url("/media/public/bg-dis-03.gif");
        --pf-c-background-image--BackgroundImage--sm-2x: url("/media/public/bg-dis-03.gif");
        --pf-c-background-image--BackgroundImage--lg: url("/media/public/bg-dis-03.gif");
        --pf-c-background-image--Filter: none;
        --pf-v5-global--primary-color--100: #d2738a;
        --pf-v5-global--primary-color--200: #e793a8;
        --pf-v5-global--link--Color: #d2738a;
        --pf-v5-global--link--Color--hover: #dfd5bc;
        --pf-v5-global--Color--100: #dfd5bc;
        --pf-v5-global--Color--200: #c1b492;
        --pf-v5-global--BackgroundColor--100: #060408;
        --pf-v5-global--BackgroundColor--200: #000000;
        --pf-v5-global--BorderColor--100: rgba(210, 115, 138, 0.42);
      }

      body,
      ak-loading {
        background-color: #000000 !important;
        background-image:
          url("/media/public/bg-dis-03.gif"),
          url("/media/public/bg-main2.gif") !important;
        color: #dfd5bc !important;
      }

      .pf-c-background-image,
      .pf-v5-c-background-image {
        background-color: #d2738a !important;
        background-image:
          repeating-linear-gradient(
            to bottom,
            rgba(0, 0, 0, 0) 0px,
            rgba(0, 0, 0, 0) 2px,
            rgba(0, 0, 0, 0.24) 3px,
            rgba(0, 0, 0, 0.24) 4px
          ),
          url("/media/public/bg-dis-03.gif"),
          url("/media/public/bg-main2.gif") !important;
        background-repeat: repeat !important;
        background-size: auto !important;
      }

      .pf-c-background-image::before,
      .pf-c-background-image::after,
      .pf-v5-c-background-image::before,
      .pf-v5-c-background-image::after {
        background-color: transparent !important;
        background-image:
          repeating-linear-gradient(
            to bottom,
            rgba(0, 0, 0, 0) 0px,
            rgba(0, 0, 0, 0) 2px,
            rgba(0, 0, 0, 0.24) 3px,
            rgba(0, 0, 0, 0.24) 4px
          ),
          url("/media/public/bg-dis-03.gif"),
          url("/media/public/bg-main2.gif") !important;
        background-repeat: repeat !important;
        background-size: auto !important;
        filter: none !important;
        opacity: 1 !important;
      }

      .pf-c-background-image__filter,
      .pf-v5-c-background-image__filter {
        display: none !important;
      }

      .pf-c-login__main,
      .pf-v5-c-login__main {
        background-color: rgba(5, 3, 7, 0.94) !important;
        background-image:
          linear-gradient(rgba(4, 2, 6, 0.68), rgba(4, 2, 6, 0.80)),
          url("/media/public/bg-rip-02.gif") !important;
        border: 1px solid rgba(210, 115, 138, 0.58) !important;
        box-shadow: 0 6px 24px #000000, 0 0 36px rgba(210, 115, 138, 0.22) !important;
        border-radius: 4px !important;
        color: #dfd5bc !important;
      }

      .pf-c-login__main-footer,
      .pf-v5-c-login__main-footer {
        background-color: rgba(12, 7, 15, 0.82) !important;
        border-top: 1px solid rgba(210, 115, 138, 0.22) !important;
      }

      .pf-c-login__footer,
      .pf-v5-c-login__footer {
        justify-content: center !important;
        color: rgba(223, 213, 188, 0.72) !important;
      }

      .pf-c-login__footer .pf-c-list li:last-child,
      .pf-v5-c-login__footer .pf-v5-c-list li:last-child {
        display: none !important;
      }

      .pf-c-login__footer::after,
      .pf-v5-c-login__footer::after {
        content: "PRESENT DAY // PRESENT TIME";
        display: block;
        font-family: "JetBrains Mono", "Courier New", monospace;
        font-size: 0.72rem;
        letter-spacing: 0.24em;
        color: rgba(223, 213, 188, 0.78);
        text-shadow: 0 1px 4px #000000;
        text-align: center;
      }

      .pf-c-login__main-header,
      .pf-v5-c-login__main-header,
      .pf-c-title,
      .pf-v5-c-title,
      h1, h2 {
        font-family: "Times New Roman", Times, Georgia, serif !important;
        letter-spacing: 0.12em;
        color: #dfd5bc !important;
      }

      .pf-c-brand,
      .pf-v5-c-brand {
        max-height: 112px;
        image-rendering: pixelated;
        filter: drop-shadow(0 0 12px rgba(210, 115, 138, 0.35));
      }

      .pf-c-form-control,
      .pf-v5-c-form-control,
      input,
      select,
      textarea {
        background-color: #000000 !important;
        color: #dfd5bc !important;
        border-color: rgba(210, 115, 138, 0.45) !important;
        font-family: "JetBrains Mono", "Courier New", monospace;
      }

      .pf-c-button.pf-m-primary,
      .pf-v5-c-button.pf-m-primary {
        background-color: transparent !important;
        color: #dfd5bc !important;
        border: 2px solid #dfd5bc !important;
        border-radius: 999px !important;
        font-family: "JetBrains Mono", "Courier New", monospace !important;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        transition: color 200ms ease, border-color 200ms ease, background-color 200ms ease;
      }

      .pf-c-button.pf-m-primary:hover,
      .pf-v5-c-button.pf-m-primary:hover {
        color: #000000 !important;
        background-color: #d2738a !important;
        border-color: #d2738a !important;
      }

      .pf-c-button.pf-m-secondary,
      .pf-v5-c-button.pf-m-secondary,
      .pf-c-login__main-footer-links-item .pf-c-button,
      .pf-v5-c-login__main-footer-links-item .pf-v5-c-button {
        border: 1px solid rgba(210, 115, 138, 0.5) !important;
        border-radius: 999px !important;
        color: #dfd5bc !important;
        background-color: #08050b !important;
      }

      .pf-c-button.pf-m-secondary:hover,
      .pf-v5-c-button.pf-m-secondary:hover {
        border-color: #d2738a !important;
        color: #d2738a !important;
      }

      a {
        color: #d2738a !important;
      }

      a:hover {
        color: #dfd5bc !important;
      }

      :where(a, button, input, select):focus-visible {
        outline: 3px solid #e793a8 !important;
        outline-offset: 2px !important;
      }

      @media (prefers-reduced-motion: reduce) {
        * {
          transition-duration: 0.01ms !important;
          animation-duration: 0.01ms !important;
        }
      }
    '';

    # Declarative Authentik Identity, SSO, Invite/Approval, OIDC & Proxy Blueprint
    environment.etc."authentik/blueprints/media-suite.yaml" = {
      text = ''
        version: 1
        metadata:
          name: LoveLain Media Suite SSO & Access Governance
        entries:
          - model: authentik_brands.brand
            identifiers:
              domain: authentik-default
            attrs:
              default: true
              branding_title: "⌈Ｗｉｒｅｄ　／　ＬｏｖｅＬａｉｎ⌋"
              branding_logo: "/media/public/wired-login.gif"
              branding_favicon: "/media/public/favicon.png"
              attributes:
                settings:
                  theme:
                    base: dark
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: default/flow-default-authentication-flow.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: default/flow-default-provider-authorization-implicit-consent.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: default/flow-default-provider-invalidation.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: default/flow-default-source-authentication.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: default/events-default.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: system/providers-oauth2.yaml
              required: false
          - model: authentik_blueprints.metaapplyblueprint
            attrs:
              identifiers:
                path: system/providers-proxy.yaml
              required: false

          # ── Strip "Welcome to authentik!" from default flow headings ──
          - model: authentik_flows.flow
            identifiers:
              slug: default-authentication-flow
            attrs:
              name: Enter the Wired
              title: Enter the Wired
              designation: authentication
          - model: authentik_flows.flow
            identifiers:
              slug: default-source-authentication
            attrs:
              name: Connect to the Wired
              title: Connect to the Wired
              designation: authentication
          - model: authentik_flows.flow
            identifiers:
              slug: default-source-enrollment
            attrs:
              name: Choose your Wired handle
              title: Choose your Wired handle
              designation: enrollment

          # ── Privilege Tiers (Groups) ───────────────────────────────────
          - model: authentik_core.group
            id: group-admins
            state: created
            identifiers:
              name: NFP Admins
            attrs:
              is_superuser: true
              users:
                - !Find [authentik_core.user, [username, t0psh31f]]
              attributes:
                role: admin
          - model: authentik_core.group
            id: group-family
            identifiers:
              name: Family
            attrs:
              is_superuser: false
              attributes:
                role: user
                tier: family
          - model: authentik_core.group
            id: group-friends
            identifiers:
              name: Friends
            attrs:
              is_superuser: false
              attributes:
                role: user
                tier: friends
          - model: authentik_core.group
            id: group-vip
            identifiers:
              name: VIP
            attrs:
              is_superuser: false
              attributes:
                role: user
                tier: vip

          # ── Self-Signup & Invite Approval Flows ───────────────────────
          - model: authentik_flows.flow
            id: enrollment-flow
            identifiers:
              slug: lovelain-enrollment
            attrs:
              name: LoveLain Invite & Signup Flow
              title: Request Access or Accept Invite
              designation: enrollment
              authentication: require_unauthenticated

          - model: authentik_flows.flow
            id: sso-enrollment-flow
            identifiers:
              slug: lovelain-sso-enrollment
            attrs:
              name: LoveLain OAuth2 Pending Approval Flow
              title: Complete Access Request
              designation: enrollment
              authentication: none

          - model: authentik_stages_invitation.invitationstage
            id: stage-invitation
            identifiers:
              name: lovelain-enrollment-invitation
            attrs:
              continue_flow_without_invitation: true

          - model: authentik_stages_prompt.prompt
            id: prompt-username
            identifiers:
              name: lovelain-field-username
            attrs:
              field_key: username
              label: Username
              type: username
              required: true
              placeholder: Choose a username
              order: 0
          - model: authentik_stages_prompt.prompt
            id: prompt-name
            identifiers:
              name: lovelain-field-name
            attrs:
              field_key: name
              label: Display Name
              type: text
              required: true
              placeholder: Your name
              order: 1
          - model: authentik_stages_prompt.prompt
            id: prompt-email
            identifiers:
              name: lovelain-field-email
            attrs:
              field_key: email
              label: Email
              type: email
              required: true
              placeholder: you@example.com
              order: 2
          - model: authentik_stages_prompt.prompt
            id: prompt-password
            identifiers:
              name: lovelain-field-password
            attrs:
              field_key: password
              label: Password
              type: password
              required: true
              placeholder: Password
              order: 3
          - model: authentik_stages_prompt.prompt
            id: prompt-password-repeat
            identifiers:
              name: lovelain-field-password-repeat
            attrs:
              field_key: password_repeat
              label: Confirm Password
              type: password
              required: true
              placeholder: Confirm Password
              order: 4

          - model: authentik_stages_prompt.promptstage
            id: stage-enrollment-prompt
            identifiers:
              name: lovelain-enrollment-prompt
            attrs:
              fields:
                - !KeyOf prompt-username
                - !KeyOf prompt-name
                - !KeyOf prompt-email
                - !KeyOf prompt-password
                - !KeyOf prompt-password-repeat

          - model: authentik_stages_prompt.promptstage
            id: stage-sso-username-prompt
            identifiers:
              name: lovelain-sso-username-prompt
            attrs:
              fields:
                - !KeyOf prompt-username

          - model: authentik_stages_user_write.userwritestage
            id: stage-write-invited
            identifiers:
              name: lovelain-write-invited
            attrs:
              user_creation_mode: always_create
              create_users_as_inactive: false
              create_users_group: !KeyOf group-friends
              user_type: external

          - model: authentik_stages_user_write.userwritestage
            id: stage-write-pending
            identifiers:
              name: lovelain-write-pending
            attrs:
              user_creation_mode: always_create
              create_users_as_inactive: true
              create_users_group: !KeyOf group-friends
              user_type: external

          - model: authentik_stages_deny.denystage
            id: stage-pending-notice
            identifiers:
              name: lovelain-pending-approval-notice
            attrs:
              deny_message: Your account request has been submitted and is awaiting administrator approval.

          - model: authentik_stages_user_login.userloginstage
            id: stage-enrollment-login
            identifiers:
              name: lovelain-enrollment-login

          - model: authentik_policies_expression.expressionpolicy
            id: policy-is-invited
            identifiers:
              name: lovelain-policy-is-invited
            attrs:
              expression: |
                flow_plan = request.context.get("flow_plan")
                return bool(flow_plan and flow_plan.context.get("invitation"))

          - model: authentik_policies_expression.expressionpolicy
            id: policy-pending-inactive
            identifiers:
              name: lovelain-policy-pending-inactive
            attrs:
              expression: |
                flow_plan = request.context.get("flow_plan")
                pending = flow_plan.context.get("pending_user") if flow_plan else None
                return bool(pending and not pending.is_active)

          - model: authentik_policies_expression.expressionpolicy
            id: policy-need-sso-username
            identifiers:
              name: lovelain-policy-need-sso-username
            attrs:
              expression: |
                return "username" not in context.get("prompt_data", {})

          - model: authentik_flows.flowstagebinding
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-invitation
              order: 0
          - model: authentik_flows.flowstagebinding
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-enrollment-prompt
              order: 10
          - model: authentik_flows.flowstagebinding
            id: bind-write-invited
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-write-invited
              order: 20
            attrs:
              evaluate_on_plan: false
              re_evaluate_policies: true
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf bind-write-invited
              policy: !KeyOf policy-is-invited
              order: 0
          - model: authentik_flows.flowstagebinding
            id: bind-write-pending
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-write-pending
              order: 21
            attrs:
              evaluate_on_plan: false
              re_evaluate_policies: true
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf bind-write-pending
              policy: !KeyOf policy-is-invited
              order: 0
            attrs:
              negate: true
          - model: authentik_flows.flowstagebinding
            id: bind-pending-notice
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-pending-notice
              order: 30
            attrs:
              evaluate_on_plan: false
              re_evaluate_policies: true
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf bind-pending-notice
              policy: !KeyOf policy-pending-inactive
              order: 0
          - model: authentik_flows.flowstagebinding
            identifiers:
              target: !KeyOf enrollment-flow
              stage: !KeyOf stage-enrollment-login
              order: 100

          # SSO (Google OAuth2) Pending Enrollment Flow
          - model: authentik_flows.flowstagebinding
            id: bind-sso-username
            identifiers:
              target: !KeyOf sso-enrollment-flow
              stage: !KeyOf stage-sso-username-prompt
              order: 0
            attrs:
              re_evaluate_policies: true
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf bind-sso-username
              policy: !KeyOf policy-need-sso-username
              order: 0
          - model: authentik_flows.flowstagebinding
            identifiers:
              target: !KeyOf sso-enrollment-flow
              stage: !KeyOf stage-write-pending
              order: 10
          - model: authentik_flows.flowstagebinding
            identifiers:
              target: !KeyOf sso-enrollment-flow
              stage: !KeyOf stage-pending-notice
              order: 20

          # ── Google OAuth2 Federation Source ────────────────────────────
          - model: authentik_sources_oauth.oauthsource
            id: source-google
            identifiers:
              slug: google
            attrs:
              name: Google
              enabled: true
              provider_type: google
              consumer_key: !Env NFP_GOOGLE_CLIENT_ID
              consumer_secret: !Env NFP_GOOGLE_CLIENT_SECRET
              authentication_flow: !Find [authentik_flows.flow, [slug, default-source-authentication]]
              enrollment_flow: !KeyOf sso-enrollment-flow
              user_matching_mode: email_link

          - model: authentik_stages_identification.identificationstage
            state: present
            identifiers:
              name: default-authentication-identification
            attrs:
              user_fields:
                - email
                - username
              show_source_labels: true
              enrollment_flow: !KeyOf enrollment-flow
              sources:
                - !KeyOf source-google

          # ── Instant ntfy Notification on New Signup ───────────────────
          - model: authentik_events.notificationwebhookmapping
            id: ntfy-mapping
            identifiers:
              name: lovelain-ntfy-signup-mapping
            attrs:
              expression: |
                return {
                    "topic": "${cfg.ntfyTopic}",
                    "title": "New LoveLain Signup Pending Approval",
                    "priority": 4,
                    "tags": ["bell", "key"],
                    "click": "https://${cfg.domain}/if/admin/#/identity/users",
                    "message": str(request.context.get("body", "A new account was created and awaits approval.")),
                }

          - model: authentik_events.notificationtransport
            id: ntfy-transport
            identifiers:
              name: lovelain-ntfy-transport
            attrs:
              mode: webhook
              webhook_url: "http://127.0.0.1:${toString ntfyPort}"
              webhook_mapping: !KeyOf ntfy-mapping
              send_once: false

          - model: authentik_policies_event_matcher.eventmatcherpolicy
            id: match-user-created
            identifiers:
              name: lovelain-match-user-created
            attrs:
              action: model_created
              model: authentik_core.user

          - model: authentik_events.notificationrule
            id: notify-user-created
            identifiers:
              name: lovelain-notify-signup
            attrs:
              severity: notice
              group: !KeyOf group-admins
              transports:
                - !KeyOf ntfy-transport
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf notify-user-created
              policy: !KeyOf match-user-created
              order: 0

          # ── Native OIDC Providers & Applications ──────────────────────
          - model: authentik_providers_oauth2.oauth2provider
            id: oidc-komga
            identifiers:
              name: Komga OIDC Provider
            attrs:
              client_type: confidential
              client_id: komga
              client_secret: !Env OIDC_KOMGA_SECRET
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
              signing_key: !Find [authentik_crypto.certificatekeypair, [name, "authentik Self-signed Certificate"]]
              include_claims_in_id_token: true
              property_mappings:
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-openid]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-email]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-profile]]
              redirect_uris:
                - matching_mode: strict
                  url: https://komga.${publicDomain}/login/oauth2/code/authentik
                - matching_mode: strict
                  url: https://komga.nfp.nix/login/oauth2/code/authentik

          - model: authentik_providers_oauth2.oauth2provider
            id: oidc-audiobookshelf
            identifiers:
              name: Audiobookshelf OIDC Provider
            attrs:
              client_type: confidential
              client_id: audiobookshelf
              client_secret: !Env OIDC_AUDIOBOOKSHELF_SECRET
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
              signing_key: !Find [authentik_crypto.certificatekeypair, [name, "authentik Self-signed Certificate"]]
              include_claims_in_id_token: true
              property_mappings:
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-openid]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-email]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-profile]]
              redirect_uris:
                - matching_mode: strict
                  url: https://audiobooks.${publicDomain}/auth/openid/callback
                - matching_mode: strict
                  url: https://audiobooks.${publicDomain}/auth/openid/mobile-redirect
                - matching_mode: strict
                  url: https://audiobookshelf.nfp.nix/auth/openid/callback
                - matching_mode: strict
                  url: audiobookshelf://oauth

          - model: authentik_providers_oauth2.oauth2provider
            id: oidc-romm
            identifiers:
              name: RomM OIDC Provider
            attrs:
              client_type: confidential
              client_id: romm
              client_secret: !Env OIDC_ROMM_SECRET
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
              signing_key: !Find [authentik_crypto.certificatekeypair, [name, "authentik Self-signed Certificate"]]
              include_claims_in_id_token: true
              property_mappings:
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-openid]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-email]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-profile]]
              redirect_uris:
                - matching_mode: strict
                  url: https://romm.${publicDomain}/api/oauth/openid
                - matching_mode: strict
                  url: https://romm.nfp.nix/api/oauth/openid

          - model: authentik_providers_oauth2.oauth2provider
            id: oidc-jellyfin
            identifiers:
              name: Jellyfin OIDC Provider
            attrs:
              client_type: confidential
              client_id: jellyfin
              client_secret: !Env OIDC_JELLYFIN_SECRET
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
              signing_key: !Find [authentik_crypto.certificatekeypair, [name, "authentik Self-signed Certificate"]]
              include_claims_in_id_token: true
              property_mappings:
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-openid]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-email]]
                - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-profile]]
              redirect_uris:
                - matching_mode: strict
                  url: https://jellyfin.${publicDomain}/sso/OID/redirect/authentik
                - matching_mode: strict
                  url: https://jellyfin.${publicDomain}/sso/OID/r/authentik
                - matching_mode: strict
                  url: https://jellyfin.nfp.nix/sso/OID/redirect/authentik

          # ── Forward-Auth Proxy Providers (Embedded Outpost) ───────────

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-calibre
            identifiers:
              name: Calibre-Web Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://calibre.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-navidrome
            identifiers:
              name: Navidrome Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://navidrome.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
              skip_path_regex: "^/(rest|share)/.*"

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-searxng
            identifiers:
              name: SearXNG Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://search.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-portal-dash
            identifiers:
              name: LoveLain Directory Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-admin-dash
            identifiers:
              name: LoveLain Admin Dash Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://dash.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-seerr
            identifiers:
              name: Seerr Requests Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://requests.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_providers_proxy.proxyprovider
            id: proxy-feishin
            identifiers:
              name: Feishin Music Proxy Provider
            attrs:
              mode: forward_single
              external_host: https://feishin.${publicDomain}
              authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
              invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]

          - model: authentik_outposts.outpost
            identifiers:
              managed: goauthentik.io/outposts/embedded
            attrs:
              name: authentik Embedded Outpost
              type: proxy
              config:
                authentik_host: https://${cfg.domain}
                authentik_host_browser: https://${cfg.domain}
                log_level: info
              providers:
                - !KeyOf proxy-calibre
                - !KeyOf proxy-navidrome
                - !KeyOf proxy-feishin
                - !KeyOf proxy-searxng
                - !KeyOf proxy-portal-dash
                - !KeyOf proxy-admin-dash
                - !KeyOf proxy-seerr

          # ── Applications & Group Access Policies ──────────────────────
          - model: authentik_core.application
            id: app-jellyfin
            identifiers:
              slug: jellyfin
            attrs:
              name: Jellyfin Cinema
              provider: !KeyOf oidc-jellyfin
              meta_launch_url: https://jellyfin.${publicDomain}
              meta_description: 4K HDR Movie & Television Streaming
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-audiobookshelf
            identifiers:
              slug: audiobookshelf
            attrs:
              name: Audiobookshelf
              provider: !KeyOf oidc-audiobookshelf
              meta_launch_url: https://audiobooks.${publicDomain}
              meta_description: Unabridged Audiobooks & Podcasts
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-komga
            identifiers:
              slug: komga
            attrs:
              name: Komga Manga & Comics
              provider: !KeyOf oidc-komga
              meta_launch_url: https://komga.${publicDomain}
              meta_description: Digital Manga & Graphic Novels
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-calibre
            identifiers:
              slug: calibre-web
            attrs:
              name: Calibre-Web Literature
              provider: !KeyOf proxy-calibre
              meta_launch_url: https://calibre.${publicDomain}
              meta_description: E-Books & Literary Manuscripts
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-navidrome
            identifiers:
              slug: navidrome
            attrs:
              name: Navidrome & Feishin
              provider: !KeyOf proxy-navidrome
              meta_launch_url: https://navidrome.${publicDomain}
              meta_description: High-Fidelity Lossless Music Streaming
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-feishin
            identifiers:
              slug: feishin
            attrs:
              name: Feishin Audio Player
              provider: !KeyOf proxy-feishin
              meta_launch_url: https://feishin.${publicDomain}
              meta_description: Modern Wired Music Streaming Interface
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-searxng
            identifiers:
              slug: searxng
            attrs:
              name: SearXNG Metasearch
              provider: !KeyOf proxy-searxng
              meta_launch_url: https://search.${publicDomain}
              meta_description: Private Decentralized Search Engine
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-romm
            identifiers:
              slug: romm
            attrs:
              name: RomM Retro Library
              provider: !KeyOf oidc-romm
              meta_launch_url: https://romm.${publicDomain}
              meta_description: Retro ROM Manager & Emulation Station
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-seerr
            identifiers:
              slug: requests
            attrs:
              name: Seerr Media Requests
              provider: !KeyOf proxy-seerr
              meta_launch_url: https://requests.${publicDomain}
              meta_description: Request New Movies, TV Shows & Anime
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-portal-dash
            identifiers:
              slug: lovelain-dash
            attrs:
              name: LoveLain Media Directory
              provider: !KeyOf proxy-portal-dash
              meta_launch_url: https://${publicDomain}
              meta_description: Unified Media & Gaming Directory
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true
          - model: authentik_core.application
            id: app-admin-dash
            identifiers:
              slug: lovelain-admin-dash
            attrs:
              name: LoveLain Admin Dashboard
              provider: !KeyOf proxy-admin-dash
              meta_launch_url: https://dash.${publicDomain}
              meta_description: Operator Fleet Dashboard
              meta_publisher: LoveLain Cyberia
              open_in_new_tab: true

          # Group-to-Application Bindings (Admin / Family / Friends)
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-admin-dash
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-portal-dash
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-portal-dash
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-portal-dash
              group: !KeyOf group-friends
              order: 2
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-seerr
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-seerr
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-seerr
              group: !KeyOf group-friends
              order: 2
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-jellyfin
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-jellyfin
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-jellyfin
              group: !KeyOf group-friends
              order: 2
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-navidrome
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-navidrome
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-navidrome
              group: !KeyOf group-friends
              order: 2
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-searxng
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-searxng
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-searxng
              group: !KeyOf group-friends
              order: 2
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-audiobookshelf
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-audiobookshelf
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-komga
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-komga
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-calibre
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-calibre
              group: !KeyOf group-family
              order: 1
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-romm
              group: !KeyOf group-admins
              order: 0
          - model: authentik_policies.policybinding
            identifiers:
              target: !KeyOf app-romm
              group: !KeyOf group-family
              order: 1
      ''
      +
        concatMapStrings
          (
            app:
            "  - model: authentik_policies.policybinding\n    identifiers:\n      target: !KeyOf ${app}\n      group: !KeyOf group-vip\n      order: 3\n"
          )
          [
            "app-portal-dash"
            "app-seerr"
            "app-jellyfin"
            "app-navidrome"
            "app-feishin"
            "app-searxng"
            "app-audiobookshelf"
            "app-komga"
            "app-calibre"
            "app-romm"
          ]
      +
        concatMapStrings
          (
            group:
            "  - model: authentik_policies.policybinding\n    identifiers:\n      target: !KeyOf app-feishin\n      group: !KeyOf ${group}\n      order: 0\n"
          )
          [
            "group-admins"
            "group-family"
            "group-friends"
          ];
    };

    # Public Caddy Virtual Hosts
    # Strict Boundary: Only Authentik, the shared media suite, and SearXNG receive public routes.
    # Everything else is strictly Tailnet-only.
    services.caddy.virtualHosts = lib.mkMerge [
      {
        "${cfg.domain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            reverse_proxy localhost:${toString cfg.port}
          '';
        };
      }
      (mkIf cfg.publicMediaServices {
        # Calibre-Web (Authentik forward_auth + X-Authentik-Username auto-login)
        "calibre.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            ${forwardAuthCaddy "localhost:${toString calibrePort}"}
          '';
        };

        # Komga (Native OIDC against auth.${publicDomain}/application/o/komga/)
        "komga.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            reverse_proxy localhost:25600
          '';
        };

        # Audiobookshelf (Native OIDC against auth.${publicDomain}/application/o/audiobookshelf/)
        "audiobooks.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            reverse_proxy localhost:9292
          '';
        };

        # Jellyfin (Native OIDC via jellyfin-plugin-sso against auth.${publicDomain}/application/o/jellyfin/)
        "jellyfin.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            reverse_proxy localhost:8096
          '';
        };

        # Navidrome (hosted on z0r0 via encrypted Tailnet; forward_auth on web UI, preserve Subsonic /rest/*)
        "navidrome.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            handle /outpost.goauthentik.io/* {
              reverse_proxy localhost:${toString cfg.port}
            }
            @navidromeBrowser not path /rest/* /share/*
            handle @navidromeBrowser {
              forward_auth localhost:${toString cfg.port} {
                uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid
                trusted_proxies private_ranges
              }
              reverse_proxy http://100.64.0.1:4533
            }
            handle {
              reverse_proxy http://100.64.0.1:4533
            }
          '';
        };

        # Feishin Modern Spotify-Like Music Client (hosted on luffy:9180, forward_auth gated)
        "feishin.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            ${forwardAuthCaddy "localhost:9180"}
          '';
        };

        # SearXNG (Authentik forward_auth gated)
        "search.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            ${forwardAuthCaddy "localhost:8888"}
          '';
        };

        # RomM (Native OIDC against auth.${publicDomain}/application/o/romm/)
        "romm.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            reverse_proxy localhost:8098
          '';
        };

        # Seerr Movie/TV Requests (Authentik forward_auth gated)
        "requests.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            ${forwardAuthCaddy "localhost:5055"}
          '';
        };

        # Operator Fleet Dashboard (Authentik forward_auth, NFP Admins only)
        "dash.${publicDomain}" = {
          useACMEHost = publicDomain;
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"
            ${forwardAuthCaddy "localhost:3007"}
          '';
        };
      })
    ];
  };
}
