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
  system.stateVersion = "25.05";

  # Memory services run here (brain-service, Honcho, GNO) — see layers/90-profiles/tags/pkb-node.nix
  machine.tags = [
    "homelab"
    "pkb-node"
    "network-router" # Headscale control server + homepage-dashboard (moved from nami 2026-09-15)
  ];

  # Headscale: migrated DB from nami; reachable via LAN + tailnet.
  # enable + serverUrl set in services block below (mkForce true).

  # Honcho postgres password from sops. The template file is read by the module
  # at runtime via databaseUrlFile (kept out of the nix store).
  sops.templates."honcho-database-url".content = ''
    DATABASE_URL=postgresql://honcho:${
      config.sops.placeholder."postgres-password"
    }@host.containers.internal:5432/honcho
  '';
  services.honcho.databaseUrlFile = config.sops.templates."honcho-database-url".path;

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
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  nix.gc.automatic = lib.mkForce false; # Do not run automatic GC/delete generations

  # ============================================================================
  # 02 - LAYERED FEATURE FLAGS (Overrides)
  # ============================================================================
  layers = {
    layer-10.system = {
      # Options: "latest" | "cachyos" | "zen"
      hardware.kernel = "cachyos"; # Maximum performance for desktop
      config.impermanence.enable = true;
      virtualization.enable = true;
      mobile.android.enable = true;
      peripherals.razer.enable = lib.mkForce false; # Disabled: openrazer driver incompatible with linux 7.0.10
    };
  };
  layers.layer-20.services.config.your-spotify.enable = true;

  layers.layer-20.services.communication.rustdesk = {
    enable = true;
    client.enable = true;
    server.enable = true;
  };
  services.rustdesk-server.signal.relayHosts = [ "192.168.1.54" ];

  # Noctalia Greeter (native Wayland login)
  layers.layer-30.theming.themes.greeter = {
    # Options: "sddm" | "greetd" | "noctalia-greeter"
    type = "noctalia-greeter";
    noctalia-greeter.session = "hyprland-uwsm";
  };

  # xserver not needed with cage greeter

  layers.layer-40.desktop = {
    hyprland.enable = true;
    noctalia.backend = "hyprland";
  };

  layers.layer-20.services.config = {
    monitoring = {
      enable = false;
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
      bindHosts = [
        "127.0.0.1" # Localhost for Caddy reverse proxy
        "192.168.1.54" # LAN IP for network clients
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
    package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # ============================================================================
  # 03 - SERVICE SPECIFICS & OVERRIDES (Layer 20)
  # ============================================================================
  services = {
    # Disable SillyTavern Tag Default to completely disable it
    sillytavern-app.enable = lib.mkForce false;

    # Headscale moved BACK to luffy (2026-09-15) — was on nami, unreachable behind Alibaba SG
    headscale-server = {
      enable = lib.mkForce true;
      serverUrl = "http://192.168.1.54:8086";
    };

    # Native Postgres (Shared for Nextcloud, Immich, MaxKB etc.)
    postgresql = {
      enableTCPIP = true;
    };

    # DuckDNS Auto-Updater using ddclient
    ddclient = {
      enable = true;
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
      defaultHTTPListenPort = 8084;
      virtualHosts = {
        "matrix.local" = {
          enableACME = lib.mkForce false;
          forceSSL = lib.mkForce false;
          onlySSL = lib.mkForce true;
          sslCertificate = "/var/lib/acme/matrix.local/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/matrix.local/key.pem";
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
          sslCertificate = "/var/lib/acme/element.local/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/element.local/key.pem";
          listen = lib.mkForce [
            {
              addr = "127.0.0.1";
              port = 8444;
              ssl = true;
            }
          ];
          root = elementWebPkg;
        };
        "searx.local".listen = lib.mkForce [
          {
            addr = "127.0.0.1";
            port = 8084;
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
    n8n-server.enable = true;
    mautrix-bridges = {
      enable = true;
      homeserverUrl = "http://localhost:8008";
      homeserverDomain = "matrix.local";
      whatsapp.enable = true;
      signal.enable = true;
    };

    # Bind SearXNG to LAN so dashboard search works from z0r0
    searx.settings.server.bind_address = lib.mkForce "0.0.0.0";

    # Glances — re-enabled for homepage-dashboard cross-machine system stats
    glances-server.enable = lib.mkForce true;

    # Caddy Reverse Proxy
    caddy = {
      enable = true;
      globalConfig = ''
        email admin@lovelain.duckdns.org
      '';
      virtualHosts."lovelain.duckdns.org" = {
        useACMEHost = "lovelain.duckdns.org";
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy localhost:3007
        '';
      };
      virtualHosts."*.lovelain.duckdns.org" = {
        useACMEHost = "lovelain.duckdns.org";
        extraConfig = ''
          encode zstd gzip
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"

          @crawl4ai host crawl4ai.lovelain.duckdns.org
          handle @crawl4ai { reverse_proxy localhost:32775 }

          @skyvernui host skyvern.lovelain.duckdns.org
          handle @skyvernui { reverse_proxy localhost:32776 }

          @skyvernapi host skyvernapi.lovelain.duckdns.org
          handle @skyvernapi { reverse_proxy localhost:32779 }

          @skyvernchrome host skyvernchrome.lovelain.duckdns.org
          handle @skyvernchrome { reverse_proxy localhost:32780 }

          @simstudio host simstudio.lovelain.duckdns.org
          handle @simstudio { reverse_proxy localhost:32790 }

          @simstudiort host simstudiort.lovelain.duckdns.org
          handle @simstudiort { reverse_proxy localhost:32789 }

          @spacedrive host spacedrive.lovelain.duckdns.org
          handle @spacedrive { reverse_proxy localhost:32768 }

          @spacedriveapi host spacedriveapi.lovelain.duckdns.org
          handle @spacedriveapi { reverse_proxy localhost:32769 }

          @vault host vault.lovelain.duckdns.org
          handle @vault { reverse_proxy localhost:8222 }

          @kavita host kavita.lovelain.duckdns.org
          handle @kavita { reverse_proxy localhost:5000 }

          @headscale host headscale.lovelain.duckdns.org
          handle @headscale { reverse_proxy http://47.254.90.69:8086 }

          @chat host chat.lovelain.duckdns.org
          handle @chat { reverse_proxy localhost:3004 }

          @beszel host beszel.lovelain.duckdns.org
          # handle @beszel { reverse_proxy localhost:32772 }  # removed — beszel dropped

          @adguard host adguard.lovelain.duckdns.org
          handle @adguard { reverse_proxy localhost:3002 }

          @openclaw host openclaw.lovelain.duckdns.org
          handle @openclaw { reverse_proxy localhost:59879 }

          @n8n host n8n.lovelain.duckdns.org
          handle @n8n { reverse_proxy localhost:5678 }

          @komga host komga.lovelain.duckdns.org
          # handle @komga { reverse_proxy localhost:25600 }  # removed — komga dropped

          @spotify host spotify.lovelain.duckdns.org
          handle @spotify { reverse_proxy localhost:3457 }

          @missionctrl host mission-control.lovelain.duckdns.org
          handle @missionctrl { reverse_proxy http://47.254.90.69:3099 }
        '';
      };
      virtualHosts."element.local" = {
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
      virtualHosts."element.lovelain.duckdns.org" = {
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
      virtualHosts."matrix.local" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8008 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
          }
        '';
      };
      # Public Matrix homeserver on duckdns domain
      virtualHosts."matrix.lovelain.duckdns.org" = {
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

  layers.layer-20.services.config.reverseProxy.routes = {
    ollama = 11434;
  };

  # ============================================================================
  # 04 - SYSTEM & PROGRAM OVERRIDES
  # ============================================================================
  # Podman Rootless Virtualization
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Machine-specific firewall overrides (Master fleet firewall rules defined in layer-10 networking.nix)

  services.ollama.package = lib.mkForce pkgs.ollama;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # ============================================================================
  # 05 - SECURITY & SECRETS (SOPS/ACME)
  # ============================================================================
  sops.age.keyFile = "/persist/home/t0psh31f/.config/sops/age/keys.txt";

  # Login passwords: clan-core's users service generates user-password-root var
  # (vars/per-machine/luffy/user-password-root/) and wires hashedPasswordFile itself.
  # The root password lives in vars/per-machine/luffy/user-password-root/user-password (sops-encrypted).
  # NOTE: do NOT define hashedPasswordFile here — it conflicts with the clan users service.

  sops.secrets."duckdns-token" = {
    sopsFile = lib.mkForce ../../layers/00-cyberia/03-treasure/secrets/duckdns.yaml;
    format = lib.mkForce "yaml";
  };
  sops.templates."duckdns-env".content = ''
    DUCKDNS_TOKEN=${config.sops.placeholder."duckdns-token"}
  '';
  sops.secrets."postgres-password" = {
    sopsFile = lib.mkForce ../../layers/00-cyberia/03-treasure/secrets/postgres.yaml;
    format = lib.mkForce "yaml";
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

  # ── Matrix Synapse SMTP (email verification, password resets) ─────────
  sops.secrets.smtp_pass = {
    sopsFile = ../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
  };

  sops.templates."synapse-email-config" = {
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

  services.matrix-synapse.extraConfigFiles = [
    config.sops.templates."synapse-email-config".path
  ];

  sops.templates."homepage-api-env" = {
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

  # Bind Synapse HTTP listener to 0.0.0.0 so z0r0's hermes can reach it via Tailscale
  services.matrix-synapse.settings.listeners = [
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

  # ============================================================================
  # 06 - STORE INTEGRITY & SAFE GARBAGE COLLECTION
  # ============================================================================
  # Same util-linux GC root fix as z0r0 — prevents nix-store --gc from
  # deleting boot-critical util-linux sibling outputs (mount, login, swap).
  # See machines/z0r0/default.nix for full explanation.

  system.activationScripts.gcroot-util-linux = ''
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

  system.activationScripts.clean-boot-entries = ''
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

  # Safe automatic garbage collection
  systemd.services.nix-safe-gc = {
    description = "Safe Nix GC (old generations only, preserves unreferenced-but-needed paths)";
    startAt = "Sun 04:00";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  # Reverse tunnel: expose luffy's headscale on nami as localhost:8087 so nami's
  # tailscale client can reach the (migrated) control server over SSH.
  # Requires luffy's root SSH key on nami (installed 2026-09-15).
  systemd.services.headscale-tunnel-nami = {
    description = "Reverse tunnel: expose luffy headscale on nami:8087";
    after = [
      "network-online.target"
      "headscale.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.openssh}/bin/ssh -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -R 8087:127.0.0.1:8086 root@47.254.90.69";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # === Prowlarr: disable systemd StateDirectory — conflicts with nixarr's
  # /data/.state/nixarr/prowlarr data dir AND the /var/lib/prowlarr impermanence
  # bind mount ("Device or resource busy" at STATE_DIRECTORY setup step).
  # ExecStart already points -data at /data/.state/nixarr/prowlarr.
  systemd.services.prowlarr.serviceConfig = {
    StateDirectory = lib.mkForce null;
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "prowlarr";
    Group = lib.mkForce "prowlarr";
    ReadWritePaths = [ "/data/.state/nixarr/prowlarr" ];
  };

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
}
