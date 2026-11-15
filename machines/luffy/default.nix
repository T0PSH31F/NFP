{
  config,
  lib,
  pkgs,
  ...
}:
let
  elementConf = {
    default_server_config = {
      "${"m.homeserver"}" = {
        base_url = "https://matrix.lovelain.duckdns.org";
        server_name = "lovelain.duckdns.org";
      };
    };
    disable_custom_urls = false;
    disable_guests = true;
    disable_login_language_selector = false;
    disable_3pid_login = false;
    force_verification = false;
    brand = "NFP Element";
    integrations_ui_url = "";
    integrations_rest_url = "";
    integrations_widgets_urls = [ ];
    default_widget_container_height = 280;
    default_country_code = "US";
    show_labs_settings = false;
    features = { };
    default_federate = true;
    default_theme = "dark";
    setting_defaults.breadcrumbs = true;
    jitsi.preferred_domain = "meet.element.io";
    element_call = {
      url = "https://call.element.io";
      brand = "Element Call";
    };
  };
  elementWebPkg = pkgs.runCommand "element-web-custom" { } ''
    cp -a ${pkgs.element-web} $out
    chmod +w $out/config.json
    cp ${builtins.toFile "config.json" (builtins.toJSON elementConf)} $out/config.json
  '';
in
{
  # ============================================================================
  # 00 - CORE IMPORTS
  # ============================================================================
  imports = [
    ./hardware.nix
    ./containers.nix

    ../../layers/10-system/13-users/t0psh31f.nix
  ];

  # ============================================================================
  # 01 - MACHINE IDENTITY
  # ============================================================================
  networking.hostName = "luffy";

  # Memory services run here (brain-service, Honcho, GNO) — see layers/90-profiles/tags/pkb-node.nix
  machine.tags = [
    "homelab"
    "pkb-node"
    "network-router" # Headscale control server + homepage-dashboard (moved from nami 2026-09-15)
    "desktop"
  ];

  # Headscale: migrated DB from nami; reachable via LAN + tailnet.
  # enable + serverUrl set in services block below (mkForce true).

  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # 02 - BOOT & KERNEL (Systemd-Boot)
  # ============================================================================
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = lib.mkForce null; # Do not prune old generations
    efi.canTouchEfiVariables = true;
    timeout = 5;
  };
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "consoleblank=120"
  ];

  nix.gc.automatic = lib.mkForce false; # Do not run automatic GC/delete generations

  # ============================================================================
  # 02 - LAYERED FEATURE FLAGS (Overrides)
  # ============================================================================
  layers = {
    layer-10.system = {
      # Options: "latest" | "cachyos" | "zen"
      hardware.kernel = "cachyos"; # Maximum performance for desktop
      config.impermanence.enable = true;
      config.nas-mount.enable = false;
      config.nas-mounts = {
        enable = true;
        enableLitestream = false;
      };
      virtualization.enable = true;
      mobile.android.enable = true;
      peripherals.razer.enable = lib.mkForce false; # Disabled: openrazer driver incompatible with linux 7.0.10
    };
    layer-40.desktop.noctalia.idle = {
      dpmsTimeout = 120; # 2 minutes screen off (like Sanji was)
      lockTimeout = 180; # 3 minutes session lock
      dpmsIgnoreAc = false;
    };
  };
  layers.layer-20.services.config.your-spotify.enable = true;
  layers.layer-20.services.auth.authentik.enable = true;
  layers.layer-76.hermes-live-voice.enable = true;
  layers.layer-78.llm-routers.jev-router-plugin = {
    enable = true;
    port = 20127;
    host = "127.0.0.1";
    openFirewall = false;
    upstreamRouterUrl = "http://100.64.0.1:20128";
  };
  layers.layer-20.services.config.nixarr-stack = {
    enable = true;
    mediaDir = "/mnt/drives/backup-1/Media";
  };
  layers.layer-20.services.config.jackett.enable = false;
  layers.layer-20.services.config.netdata.enable = true;

  # Central fleet orchestrators hosted strictly on luffy (single instance for all 3 machines)
  layers.layer-76.orchestrators = {
    paperclip = {
      enable = true;
      client.enable = true;
      remoteHost = "luffy.nfp.nix";
    };
    aionui = {
      enable = true;
      client.enable = true;
      remoteHost = "luffy.nfp.nix";
    };
    mission-control = {
      enable = true;
      client.enable = true;
      remoteHost = "luffy.nfp.nix";
    };
  };

  # Keep extreme-router strictly on z0r0
  layers.layer-78.llm-routers.extreme-router.enable = false;

  # Headplane web UI for local Headscale server
  layers.layer-20.services.config.headplane = {
    enable = true;
    port = 3050;
    headscaleUrl = "http://127.0.0.1:8086";
  };

  # OmniRoute AI Gateway on luffy
  services.ai-services.omniroute = {
    enable = true;
    port = 20129;
    environmentFile = config.sops.templates."omniroute-env".path;
  };

  # Langfuse LLM Observability suite
  services.infrastructure.langfuse = {
    enable = true;
    port = 3005;
  };

  layers.layer-20.services.communication.rustdesk = {
    enable = true;
    client.enable = true;
    server.enable = true;
  };

  # LoveLain Cyberia Guest Portal & Authenticated Media Launchpad
  layers.layer-20.services.networking.portal.enable = true;

  # Desktop experience: owned by tag/profile architecture.
  # luffy is hybrid server+desktop: desktop tag enables base Hyprland/Noctalia
  # via layers/90-profiles/tags/desktop.nix, and experience selector owns the
  # Noctalia-Hyprland adapter. Do NOT set hyprland.enable / noctalia.enable
  # directly here — they derive from desktop.experience.
  # Explicit machine boundary selection required for hybrid server+desktop.
  layers.desktop.experience = "noctalia";

  # Agent harnesses available on central orchestrator node
  layers.layer-71.harness = {
    antigravity = {
      enable = true;
      enableIde = true;
    };
    claude-code.enable = true;
    opencode.enable = true;
    herdr.enable = true;
    pi-coding-agent.enable = true;
    aider-chat.enable = true;
  };

  # Greeter follows desktop tag default (noctalia-greeter / hyprland-uwsm);
  # keep explicit only if diverging from tag default — currently redundant,
  # so rely on tag profile. Remove duplicate greeter config to avoid drift.

  layers.layer-20.services.config = {
    monitoring = {
      enable = true; # central Prometheus/Loki/Grafana for the whole fleet (role = server)
      domain = "grafana.lovelain.duckdns.org";
      prometheus.port = 9090;
    };
    homepage-dashboard = {
      enable = true;
      port = 3007;
      environmentFile = config.sops.templates."homepage-api-env".path;
    };
    adguard = {
      enable = true;
      port = 3002;
      # Phase 4: Bind to localhost + LAN + Tailnet-reachable (100.64.0.3) as
      # supported by AdGuard config. Firewall restricts DNS to LAN/Tailnet/localhost only, never WAN.
      bindHosts = [
        "127.0.0.1"
        "192.168.1.54"
        "100.64.0.3"
      ];
      dhcp = false; # Spectrum router handles DHCP
      gatewayIp = "192.168.1.54"; # Luffy's reserved LAN IP
      subnet = "192.168.1.0/24";
    };
    gateway = {
      enable = true;
      wanInterface = "eth0"; # Connected to Spectrum router
      vpnInterfaces = [
        "tailscale0"
        "wg0"
        "zt0"
      ];
      lanIp = "192.168.1.54"; # Must match IP reservation on Spectrum router
    };
  };

  hardware.nvidia = {
    enable = true;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    powerManagement.enable = lib.mkForce true;
    package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # ============================================================================
  # 02.1 - HARDWARE & PERFORMANCE OPTIMIZATION (Intel i7-9700F + Quadro P620)
  # ============================================================================
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  services.thermald.enable = true;

  # ZRAM compressed swap in RAM to absorb memory spikes and protect SSD
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Sysctl optimizations for 24GB RAM desktop/server workload
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
  };

  # ============================================================================
  # 03 - SERVICE SPECIFICS & OVERRIDES (Layer 20)
  # ============================================================================
  services = {
    honcho.databaseUrlFile = config.sops.templates."honcho-database-url".path;
    searxng.enable = true;
    calibre-web-app = {
      enable = true;
      libraryPath = "/mnt/drives/backup-1/CalibreLibrary";
      backupDir = "/mnt/NAS1/backups/CalibreLibrary";
    };
    recovery-organizer.enable = true;
    jev-engine.enable = true;
    jev-exporter.enable = true;
    wyoming-services.enable = true;
    lead-triage-webhook.enable = true;
    ad-hook-miner.enable = true;
    rustdesk-server.signal.relayHosts = [ "luffy.nfp.nix" ];

    # Headscale moved BACK to luffy (2026-09-15) — was on nami, unreachable behind Alibaba SG
    headscale-server = {
      enable = lib.mkForce true;
      serverUrl = "http://luffy.nfp.nix:8086";
    };

    # Native Postgres (Shared for Nextcloud, Immich, MaxKB etc.)
    postgresql = {
      enableTCPIP = true;
    };

    # DuckDNS Auto-Updater using ddclient
    ddclient = {
      enable = true;
      usev6 = "";
      domains = [
        "lovelain.duckdns.org"
        "t0psh31f.duckdns.org"
        "nixfp.duckdns.org"
        "chat.lovelain.duckdns.org"
      ];
      protocol = "duckdns";
      passwordFile = config.sops.secrets."duckdns-token".path;
    };

    # Enable Native Services from flake-parts
    # Matrix homeserver nginx vhost (Caddy reverse-proxies to this)
    # Deprecated: Caddy now proxies directly to Synapse on 8008 and serves Element Web
    # nginx config kept in case it's needed by other services
    nginx = {
      defaultHTTPListenPort = 8097;
      virtualHosts = {
        "matrix.local" = {
          enableACME = lib.mkForce false;
          forceSSL = lib.mkForce false;
          onlySSL = lib.mkForce true;
          sslCertificate = "/run/nginx/matrix.local.crt";
          sslCertificateKey = "/run/nginx/matrix.local.key";
          listen = lib.mkForce [
            {
              addr = "127.0.0.1";
              port = 8443;
              ssl = true;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:8008";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_read_timeout 600s;
            '';
          };
        };
        "element.local" = {
          enableACME = lib.mkForce false;
          forceSSL = lib.mkForce false;
          onlySSL = lib.mkForce true;
          sslCertificate = "/run/nginx/element.local.crt";
          sslCertificateKey = "/run/nginx/element.local.key";
          listen = lib.mkForce [
            {
              addr = "127.0.0.1";
              port = 8444;
              ssl = true;
            }
          ];
          root = lib.mkForce elementWebPkg;
        };
        "searx.local".listen = lib.mkForce [
          {
            addr = "127.0.0.1";
            port = 8097;
          }
        ];
        "hermes-matrix.local" = {
          listen = lib.mkForce [
            {
              addr = "0.0.0.0";
              port = 8087;
              extraParameters = [ "default_server" ];
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:8008";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
      };
    };

    vaultwarden = {
      enable = true;
      config = {
        ROCKET_PORT = 8222;
        ROCKET_ADDRESS = lib.mkForce "127.0.0.1";
      };
    };

    # Moved from Nami
    n8n-server.enable = false;
    mautrix-bridges = {
      enable = true;
      homeserverUrl = "http://localhost:8008";
      homeserverDomain = "matrix.lovelain.duckdns.org";
      whatsapp.enable = true;
      signal.enable = true;
      telegram.enable = true;
      discord.enable = true;
      instagram.enable = true;
      facebook.enable = true;
      # Disabled 2026-11-04: same unconfigured-bridge failure as linkedin —
      # stock sample config, no appservice registration, exit 20
      # "Homeserver domain is not set" on every boot.
      gmessages.enable = false;
      gvoice.enable = false;
      # Disabled 2026-11-04: enabled but never configured. /var/lib/mautrix-linkedin
      # holds the stock upstream sample (domain example.com, placeholder as_token,
      # public_address bridge.example.com), there is no registration.yaml, and no
      # Synapse appservice registration exists — so the container exited 20 on
      # every boot ("Homeserver domain is not set") and hit start-limit-hit.
      # Re-enable only together with a real bridge setup (tokens in SOPS +
      # Synapse app_service_config_files entry).
      linkedin.enable = false;
    };

    # Bind SearXNG to LAN so dashboard search works from z0r0
    searx.settings.server.bind_address = lib.mkForce "0.0.0.0";

    # Glances — disabled, replaced by Netdata for fleet vitals
    glances-server.enable = lib.mkForce false;

    # Caddy Reverse Proxy
    caddy = {
      enable = true;
      globalConfig = ''
        email admin@lovelain.duckdns.org
      '';
      virtualHosts = {
        # lovelain.duckdns.org root domain is managed by layers.layer-20.services.networking.portal
        "*.lovelain.duckdns.org" = {
          useACMEHost = "lovelain.duckdns.org";
          extraConfig = ''
            encode zstd gzip
            header Strict-Transport-Security "max-age=31536000; includeSubDomains"

            # Headscale control plane: public route required for mobile WAN WireGuard handshakes.
            # All internal admin dashboards (aionui, paperclip, mission-control, adguard, etc.)
            # are strictly gated to the encrypted Tailnet (*.nfp.nix / 100.64.0.0/10).
            @headscale host headscale.lovelain.duckdns.org
            handle @headscale { reverse_proxy localhost:8086 }
          '';
        };
        "element.local" = {
          extraConfig = ''
            root * ${elementWebPkg}
            file_server
            @noext not path *.html *.js *.css *.png *.svg *.ico *.json *.webp
            handle @noext {
              try_files {path} /index.html
              file_server
            }
          '';
        };
        "element.lovelain.duckdns.org" = {
          extraConfig = ''
            root * ${elementWebPkg}
            file_server
            @noext not path *.html *.js *.css *.png *.svg *.ico *.json *.webp
            handle @noext {
              try_files {path} /index.html
              file_server
            }
          '';
        };
        "matrix.local" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8008 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
            }
          '';
        };
        # Public Matrix homeserver on duckdns domain
        "matrix.lovelain.duckdns.org" = {
          extraConfig = ''
            # Serve well-known discovery documents for phone clients
            @wellknownClient path /.well-known/matrix/client
            handle @wellknownClient {
              header Content-Type application/json
              respond `{"m.homeserver":{"base_url":"https://matrix.lovelain.duckdns.org"}}` 200
            }
            @wellknownServer path /.well-known/matrix/server
            handle @wellknownServer {
              header Content-Type application/json
              respond `{"m.server":"matrix.lovelain.duckdns.org:443"}` 200
            }
            reverse_proxy http://127.0.0.1:8008 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
            }
          '';
        };
      };
    };

    # Bind Synapse HTTP listener to 0.0.0.0 so z0r0's hermes can reach it via Tailscale
    matrix-synapse = {
      extraConfigFiles = [
        config.sops.templates."synapse-email-config".path
      ];
      settings.listeners = [
        {
          port = 8008;
          bind_addresses = [ "0.0.0.0" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [ "client" ];
              compress = true;
            }
            {
              names = [ "federation" ];
              compress = false;
            }
          ];
        }
      ];
    };

    autobrr = {
      enable = true;
      openFirewall = true; # nixarr had host = 0.0.0.0; native module defaults to loopback
      settings = {
        host = "0.0.0.0";
        port = 7474;
        checkForUpdates = false;
      };
    };
  };

  # Podman Rootless Virtualization
  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };
  };

  # Machine-specific firewall overrides (Master fleet firewall rules defined in layer-10 networking.nix)

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.layers.meta.primaryUser} = {
      xdg.configFile."hypr/monitors.conf".text = ''
        # Luffy 4-Monitor 2x2 Square Configuration
        monitor = desc:Acer Technologies Acer B277 0x95112E9B, 1920x1080@74.99, 0x0, 1
        monitor = desc:Acer Technologies XB271HK T4UAA0018502, 1920x1080@60, 0x1080, 1
        monitor = desc:Acer Technologies Acer B277 0x95112E9D, 1920x1080@74.99, 1920x0, 1
        monitor = desc:Acer Technologies Acer B277 0x95112EBE, 1920x1080@74.99, 1920x1080, 1
        monitor = , preferred, auto, 1
      '';
    };
  };

  # ============================================================================
  # 05 - SECURITY & SECRETS (SOPS/ACME)
  # ============================================================================
  sops = {
    age.keyFile = "/persist/home/t0psh31f/.config/sops/age/keys.txt";

    secrets = {
      "duckdns-token" = {
        sopsFile = lib.mkForce ../../layers/00-cyberia/03-treasure/secrets/duckdns.yaml;
        format = lib.mkForce "yaml";
      };
      "postgres-password" = {
        sopsFile = lib.mkForce ../../layers/00-cyberia/03-treasure/secrets/postgres.yaml;
        format = lib.mkForce "yaml";
      };
      smtp_pass = {
        sopsFile = ../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
      };
    };

    templates = {
      "honcho-database-url".content = ''
        DATABASE_URL=postgresql://honcho:${
          config.sops.placeholder."postgres-password"
        }@host.containers.internal:5432/honcho
      '';
      "duckdns-env".content = ''
        DUCKDNS_TOKEN=${config.sops.placeholder."duckdns-token"}
      '';
      "synapse-email-config" = {
        content = ''
          email:
            smtp_host: smtp.gmail.com
            smtp_port: 587
            smtp_user: wrighterik77@gmail.com
            smtp_pass: ${config.sops.placeholder.smtp_pass}
            require_transport_security: true
            enable_tls: true
            force_tls: true
            notif_from: "Matrix <wrighterik77@gmail.com>"
            app_name: "NFP Matrix"
        '';
        # Synapse runs as matrix-synapse user, needs read access
        mode = "0644";
        owner = "matrix-synapse";
      };
      "homepage-api-env" = {
        content = ''
          IMMICH_API_KEY=""
          HEADSCALE_API_KEY=""
          ADGUARD_AUTH=""
          PORTAINER_API_KEY=""
          JELLYFIN_API_KEY=""
          SONARR_API_KEY=""
          RADARR_API_KEY=""
          LIDARR_API_KEY=""
          PROWLARR_API_KEY=""
          BAZARR_API_KEY=""
          OVERSEERR_API_KEY=""
          READARR_API_KEY=""
          GRAFANA_API_KEY=""
        '';
        mode = "0640";
        owner = "homepage-dashboard";
      };
    };
  };

  # ACME Let's Encrypt Wildcard via DuckDNS
  security.acme = {
    acceptTerms = true;
    defaults.email = lib.mkForce "admin@lovelain.duckdns.org";
    # Cert only on the wildcard - Caddy handles the public vhosts
    # ACME extraDomainNames would create nginx vhosts on port 443 conflicting with Caddy
    certs."lovelain.duckdns.org" = {
      domain = "*.lovelain.duckdns.org";
      dnsProvider = "duckdns";
      environmentFile = config.sops.templates."duckdns-env".path;
    };
  };

  # ============================================================================
  # 06 - STORE INTEGRITY & SAFE GARBAGE COLLECTION
  # ============================================================================
  # Same util-linux GC root fix as z0r0 — prevents nix-store --gc from
  # deleting boot-critical util-linux sibling outputs (mount, login, swap).
  # See machines/z0r0/default.nix for full explanation.

  system = {
    stateVersion = "25.05";
    activationScripts = {
      gcroot-util-linux = ''
        mkdir -p /nix/var/nix/gcroots
        _ulbin="${pkgs.util-linux.bin}"
        if [ -d "$_ulbin/bin" ]; then
          for link in "$_ulbin"/bin/*; do
            [ -L "$link" ] || continue
            target=$(readlink -f "$link" 2>/dev/null) || continue
            case "$target" in
              /nix/store/*)
                storepath=$(echo "$target" | cut -d/ -f1-4)
                name=$(basename "$storepath")
                ln -sfn "$storepath" "/nix/var/nix/gcroots/util-linux-fix-$name"
                ;;
            esac
          done
        fi
      '';

      clean-boot-entries = ''
        if [ -d /boot/loader/entries ]; then
          for f in /boot/loader/entries/*.conf; do
            [ -f "$f" ] || continue
            init_path=$(${pkgs.gnugrep}/bin/grep -E 'options.*init=' "$f" | ${pkgs.gnused}/bin/sed -E 's/.*init=([^ ]+).*/\1/')
            if [ -n "$init_path" ] && [ ! -e "$init_path" ]; then
              echo "Pruning orphan boot entry: $f (init $init_path missing)"
              rm -f "$f"
            fi
          done
        fi
      '';
    };
  };

  # Safe automatic garbage collection & service overrides
  systemd.services = {
    nix-safe-gc = {
      description = "Safe Nix GC (old generations only, preserves unreferenced-but-needed paths)";
      startAt = "Sun 04:00";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    prowlarr.serviceConfig = {
      StateDirectory = lib.mkForce null;
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "prowlarr";
      Group = lib.mkForce "prowlarr";
      ReadWritePaths = [ "/data/.state/nixarr/prowlarr" ];
    };

    # Ensure postgresql-setup refreshes collation versions so CREATE DATABASE never fails
    postgresql-setup = {
      preStart = ''
        ${config.services.postgresql.package}/bin/psql -d postgres -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;" || true
        ${config.services.postgresql.package}/bin/psql -d postgres -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;" || true
      '';
    };

    # Ensure nginx waits for network-online and has valid internal TLS certs for local vhosts
    nginx = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      preStart = lib.mkBefore ''
        mkdir -p /run/nginx
        for h in matrix.local element.local; do
          if [ ! -s "/run/nginx/$h.crt" ] || [ ! -s "/run/nginx/$h.key" ]; then
            ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
              -keyout "/run/nginx/$h.key" \
              -out "/run/nginx/$h.crt" \
              -subj "/CN=$h" >/dev/null 2>&1
            chmod 600 "/run/nginx/$h.key"
            chmod 644 "/run/nginx/$h.crt"
          fi
        done
      '';
    };

    # Wyoming faster whisper network online and restart safety
    wyoming-faster-whisper-local = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig.RestartSec = lib.mkForce "10s";
    };

    # Fix ad-hook-miner StateDirectory migration error
    ad-hook-miner.serviceConfig.DynamicUser = lib.mkForce false;

    # VictoriaMetrics impermanence bind-mount compatibility
    victoriametrics.serviceConfig.DynamicUser = lib.mkForce false;

    # Filebrowser data directory permissions (service runs unprivileged as filebrowser; ownership is enforced by tmpfiles)
    filebrowser.preStart = ''
      mkdir -p /var/lib/filebrowser/data
      chmod 700 /var/lib/filebrowser/data
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/filebrowser 0750 filebrowser filebrowser -"
    "Z /var/lib/filebrowser - filebrowser filebrowser -"
  ];

  # Persist luffy's root SSH keypair across impermanence rollbacks.
  environment.persistence."/persist".directories = [
    {
      directory = "/root/.ssh";
      mode = "0700";
    }
  ];

  # Reverse tunnel (headscale-tunnel-nami) and Prowlarr service overrides
  # are defined in systemd.services above.

  # Provide a safe-gc convenience script
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-safe-gc" ''
      echo "Running safe garbage collection (deleting generations older than ''${1:-14d})..."
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than "''${1:-14d}"
      if [ -d /boot/loader/entries ]; then
        echo "Pruning orphan boot entries..."
        for f in /boot/loader/entries/*.conf; do
          [ -f "$f" ] || continue
          init_path=$(grep -E 'options.*init=' "$f" | sed -E 's/.*init=([^ ]+).*/\1/')
          if [ -n "$init_path" ] && [ ! -e "$init_path" ]; then
            echo "Removing orphan entry: $f"
            sudo rm -f "$f"
          fi
        done
      fi
      echo "Done. No unreferenced-but-needed paths were harmed."
    '')
  ];

  # nixarr's autobrr wrapper is incompatible with current nixpkgs and must be
  # bypassed, not disabled-and-forgotten:
  #
  #   nixarr/autobrr/default.nix:182 sets `services.autobrr.secretFile =
  #   "/dev/null"` as a deliberate placeholder (it manages the session secret
  #   itself). nixpkgs removed that option in autobrr >= 1.82.0 via
  #   mkRemovedOptionModule, whose assertion is `!opt.isDefined` — it fires if
  #   ANY file defines the option, so it cannot be overridden back to null or
  #   any other value. Confirmed still present on nix-media-server/nixarr main
  #   and master, so `nix flake update nixarr` does not help.
  #
  # Because nixarr.nixosModules.default.imports the whole ./nixarr tree as one
  # merged module, the offending submodule cannot be excluded from it. So we
  # turn off nixarr's autobrr and run nixpkgs' native module in its place.
  # Lossless: the repo configures no autobrr settings and the live
  # /data/.state/nixarr/autobrr/config.toml is defaults only
  # (checkForUpdates=false, host 0.0.0.0, port 7474 — no filters), so nothing
  # is lost by moving to the native module's StateDirectory.
  nixarr.autobrr.enable = lib.mkForce false;
  nixarr.anchorr.enable = lib.mkForce false;
}
