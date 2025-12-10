{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.services.matrix-server = {
    enable = mkEnableOption "Matrix Synapse homeserver";

    serverName = mkOption {
      type = types.str;
      default = "matrix.local";
      description = "The domain name of the Matrix homeserver";
    };

    port = mkOption {
      type = types.int;
      default = 8008;
      description = "Port for Matrix Synapse";
    };

    enableRegistration = mkOption {
      type = types.bool;
      default = false;
      description = "Allow new user registration";
    };

    enableMetrics = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Prometheus metrics";
    };

    maxUploadSize = mkOption {
      type = types.str;
      default = "50M";
      description = "Maximum upload size for media";
    };
  };

  config = mkIf config.services.matrix-server.enable {
    services.matrix-synapse = {
      enable = true;

      settings = {
        server_name = config.services.matrix-server.serverName;

        listeners =
          [
            {
              port = config.services.matrix-server.port;
              bind_addresses = ["::1" "127.0.0.1"];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = ["client" "federation"];
                  compress = false;
                }
              ];
            }
          ]
          ++ optional config.services.matrix-server.enableMetrics {
            port = 9000;
            bind_addresses = ["127.0.0.1"];
            type = "http";
            tls = false;
            resources = [
              {
                names = ["metrics"];
                compress = false;
              }
            ];
          };

        # Database configuration
        database = {
          name = "psycopg2";
          args = {
            user = "matrix-synapse";
            database = "matrix-synapse";
            host = "localhost";
            cp_min = 5;
            cp_max = 10;
          };
        };

        # Registration
        enable_registration = config.services.matrix-server.enableRegistration;
        registration_shared_secret_path = "/var/lib/matrix-synapse/registration_shared_secret";

        # Media
        max_upload_size = config.services.matrix-server.maxUploadSize;
        url_preview_enabled = true;
        url_preview_ip_range_blacklist = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
          "169.254.0.0/16"
          "::1/128"
          "fe80::/64"
          "fc00::/7"
        ];

        # Performance
        enable_metrics = config.services.matrix-server.enableMetrics;

        # Federation
        federation_domain_whitelist = null; # Allow federation with all servers

        # Presence
        presence.enabled = true;
      };

      # Extra configuration
      extraConfigFiles = [
        # Add path to signing key if needed
      ];
    };

    # PostgreSQL database for Matrix
    services.postgresql = {
      enable = true;
      ensureDatabases = ["matrix-synapse"];
      ensureUsers = [
        {
          name = "matrix-synapse";
          ensureDBOwnership = true;
        }
      ];

      # Optimize for Matrix
      settings = {
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
      };
    };

    # Nginx reverse proxy (optional but recommended)
    services.nginx.virtualHosts.${config.services.matrix-server.serverName} = mkIf config.services.nginx.enable {
      enableACME = true;
      forceSSL = true;

      locations."/_matrix" = {
        proxyPass = "http://[::1]:${toString config.services.matrix-server.port}";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;
          client_max_body_size ${config.services.matrix-server.maxUploadSize};
        '';
      };

      locations."/_synapse/client" = {
        proxyPass = "http://[::1]:${toString config.services.matrix-server.port}";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      config.services.matrix-server.port
      8448 # Federation port
    ];
  };
}
