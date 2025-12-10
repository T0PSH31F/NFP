{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets.cloudflare_api_token = {};

  # ACME configuration remains the same but group changes to traefik
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "henry.sipp@hey.com";
    };
    certs."sipp.family" = {
      domain = "*.sipp.family";
      extraDomainNames = ["sipp.family"];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.secrets.cloudflare_api_token.path;
      group = "traefik"; # Changed from nginx
    };
  };

  # Traefik service configuration
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      # Entry points
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        websecure = {
          address = ":443";
          http.tls = true;
        };
      };

      # Logging
      accessLog = {};
      log = {
        level = "INFO";
      };

      # API/Dashboard (disabled for security)
      api = {
        dashboard = false;
      };

      # Certificate resolver using ACME certs
      providers = {
        file = {
          directory = "/etc/traefik/dynamic";
          watch = true;
        };
      };
    };

    # Dynamic configuration
    dynamicConfigOptions = {
      tls = {
        certificates = [
          {
            certFile = "/var/lib/acme/sipp.family/cert.pem";
            keyFile = "/var/lib/acme/sipp.family/key.pem";
          }
        ];
        options = {
          default = {
            minVersion = "VersionTLS12";
            cipherSuites = [
              "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
            ];
          };
        };
      };

      http = {
        # Middlewares
        middlewares = {
          # Security headers
          security-headers = {
            headers = {
              frameDeny = true;
              contentTypeNosniff = true;
              browserXssFilter = true;
              referrerPolicy = "no-referrer";
              stsSeconds = 31536000;
              stsIncludeSubdomains = true;
              stsPreload = true;
              customResponseHeaders = {
                X-Robots-Tag = "noindex, nofollow";
              };
            };
          };

          # Rate limiting (equivalent to nginx zones)
          rate-limit-login = {
            rateLimit = {
              average = 5;
              period = "1m";
              burst = 10;
            };
          };

          rate-limit-api = {
            rateLimit = {
              average = 10;
              period = "1s";
              burst = 50;
            };
          };

          # Large upload for photos
          large-upload = {
            buffering = {
              maxRequestBodyBytes = 52428800000; # 50GB
            };
          };
        };

        # Routers and services
        routers = {
          # Default catch-all (equivalent to nginx default)
          default-catch = {
            rule = "PathPrefix(`/`)";
            priority = 1;
            service = "noop@internal";
            middlewares = ["security-headers"];
            tls = {
              domains = [
                {
                  main = "sipp.family";
                  sans = ["*.sipp.family"];
                }
              ];
            };
          };

          # Home Assistant
          home = {
            rule = "Host(`home.sipp.family`)";
            service = "home";
            middlewares = ["security-headers" "rate-limit-api"];
            tls = {};
          };

          # Nextcloud
          cloud = {
            rule = "Host(`cloud.sipp.family`)";
            service = "cloud";
            middlewares = ["security-headers"];
            tls = {};
          };

          # Plex
          plex = {
            rule = "Host(`plex.sipp.family`)";
            service = "plex";
            middlewares = ["security-headers"];
            tls = {};
          };

          # Photos (Immich)
          photos = {
            rule = "Host(`photos.sipp.family`)";
            service = "photos";
            middlewares = ["security-headers" "large-upload"];
            tls = {};
          };
        };

        # Services
        services = {
          # Home Assistant
          home = {
            loadBalancer = {
              servers = [{url = "http://localhost:8123";}];
              passHostHeader = true;
            };
          };

          # Nextcloud
          cloud = {
            loadBalancer = {
              servers = [{url = "http://10.50.0.2";}];
              passHostHeader = true;
            };
          };

          # Plex
          plex = {
            loadBalancer = {
              servers = [{url = "http://10.50.0.3:32400";}];
              passHostHeader = true;
            };
          };

          # Photos (Immich)
          photos = {
            loadBalancer = {
              servers = [{url = "http://[::1]:2283";}];
              passHostHeader = true;
            };
          };
        };
      };
    };
  };

  # Create dynamic config directory
  systemd.tmpfiles.rules = [
    "d /etc/traefik/dynamic 0755 traefik traefik -"
  ];

  # Fail2ban configuration for Traefik
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "24h";
    jails = {
      traefik-auth = ''
        enabled = true
        port = http,https
        filter = traefik-auth
        logpath = /var/log/traefik/access.log
        maxretry = 3
        bantime = 24h
      '';

      traefik-rate-limit = ''
        enabled = true
        port = http,https
        filter = traefik-rate-limit
        logpath = /var/log/traefik/access.log
        maxretry = 10
        bantime = 24h
      '';
    };
  };

  # Fail2ban filters for Traefik
  environment.etc = {
    "fail2ban/filter.d/traefik-auth.conf".text = ''
      [Definition]
      failregex = ^<HOST> - - \[.*\] ".*" 401 .*$
      ignoreregex =
    '';

    "fail2ban/filter.d/traefik-rate-limit.conf".text = ''
      [Definition]
      failregex = ^<HOST> - - \[.*\] ".*" 429 .*$
      ignoreregex =
    '';
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [80 443];
}
