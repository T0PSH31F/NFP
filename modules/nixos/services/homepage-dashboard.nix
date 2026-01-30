# Homepage Dashboard
# Documentation: https://gethomepage.dev
# Service Widgets (Plugin Catalog): https://gethomepage.dev/latest/widgets/services/
# Customization: https://gethomepage.dev/latest/configs/settings/

{
  config,
  lib,
  ...
}:
with lib;
{
  options.services-config.homepage-dashboard = {
    enable = mkEnableOption "Homepage Dashboard";

    port = mkOption {
      type = types.port;
      default = 8082;
      description = "Port to expose Homepage Dashboard on";
    };
  };

  config = mkIf config.services-config.homepage-dashboard.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = config.services-config.homepage-dashboard.port;

      settings = {
        title = "Grandlix Dashboard";
        background = {
          image = "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop";
          opacity = 0.5;
        };
        cardBlur = "sm";
        theme = "dark";
        color = "slate";
        layout = {
          "Media" = {
            style = "row";
            columns = 4;
          };
          "Monitoring" = {
            style = "row";
            columns = 3;
          };
          "AI Services" = {
            style = "row";
            columns = 4;
          };
          "Home Lab" = {
            style = "row";
            columns = 4;
          };
        };
      };

      widgets = [
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
        {
          docker = {
            endpoint = "unix:///var/run/docker.sock";
            socket = "/var/run/docker.sock";
          };
        }
      ];

      # Define services with checks for enablement where possible, or just list them
      services = [
        {
          "Media" = [
            {
              "Sonarr" = {
                icon = "sonarr.png";
                href = "http://localhost:8989";
                description = "TV Shows";
              };
            }
            {
              "Radarr" = {
                icon = "radarr.png";
                href = "http://localhost:7878";
                description = "Movies";
              };
            }
            {
              "Lidarr" = {
                icon = "lidarr.png";
                href = "http://localhost:8686";
                description = "Music";
              };
            }
            {
              "Readarr" = {
                icon = "readarr.png";
                href = "http://localhost:8787";
                description = "Books";
              };
            }
            {
              "Prowlarr" = {
                icon = "prowlarr.png";
                href = "http://localhost:9696";
                description = "Indexers";
              };
            }
            {
              "Bazarr" = {
                icon = "bazarr.png";
                href = "http://localhost:6767";
                description = "Subtitles";
              };
            }
            {
              "Deluge" = {
                icon = "deluge.png";
                href = "http://localhost:8112";
                description = "Torrents";
              };
            }
            {
              "Aria2" = {
                icon = "aria2.png";
                href = "http://localhost:6800/jsonrpc"; # Aria2 is usually RPC only, usually fronted by AriaNg but linking RPC for now or dashboard might support it natively
                description = "Downloader";
              };
            }
          ];
        }
        {
          "Monitoring" = [
            {
              "Grafana" = {
                icon = "grafana.png";
                href = "http://localhost:${toString config.services-config.monitoring.grafana.port}";
                description = "Metrics Dashboard";
              };
            }
            {
              "Prometheus" = {
                icon = "prometheus.png";
                href = "http://localhost:${toString config.services-config.monitoring.prometheus.port}";
                description = "Metrics Backend";
              };
            }
          ];
        }
        {
          "AI Services" = [
            {
              "Open WebUI" = {
                icon = "openai.png"; # Placeholder or generic AI icon
                href = "http://localhost:8080";
                description = "LLM Interface";
                container = "open-webui";
              };
            }
            {
              "LocalAI" = {
                icon = "robot.png";
                href = "http://localhost:8081";
                description = "Local AI API";
                container = "local-ai";
              };
            }
            {
              "SillyTavern" = {
                icon = "sillytavern.png";
                href = "http://localhost:${toString config.services.sillytavern-app.port}";
                description = "Roleplay Chat";
                container = "sillytavern";
              };
            }
            {
              "Qdrant" = {
                icon = "qdrant.png";
                href = "http://localhost:6333/dashboard";
                description = "Vector DB";
                container = "qdrant";
              };
            }
          ];
        }
        {
          "Home Lab" = [
            {
              "Immich" = {
                icon = "immich.png";
                href = "http://localhost:${toString config.services.immich-server.port}";
                description = "Photos";
              };
            }
            {
              "n8n" = {
                icon = "n8n.png";
                href = "http://localhost:5678";
                description = "Automation";
              };
            }
            {
              "Synapse" = {
                icon = "matrix.png";
                href = "http://localhost:8008";
                description = "Matrix Server";
              };
            }
            {
              "Calibre-Web" = {
                icon = "calibre.png";
                href = "http://localhost:${toString config.services.calibre-web-app.port}";
                description = "E-book library";
              };
            }
          ];
        }
      ];
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services-config.homepage-dashboard.port ];

    # User/Group configuration for security
    users.users.homepage-dashboard = {
      isSystemUser = true;
      group = "homepage-dashboard";
      extraGroups = [ "docker" ];
    };
    users.groups.homepage-dashboard = { };

    # Ensure data is persisted


    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        "/var/lib/homepage-dashboard"
      ];
    };

    # Fix for STATE_DIRECTORY failure with impermanence
    # Systemd managing StateDirectory conflicts with impermanence symlinks/bind-mounts
    systemd.services.homepage-dashboard.serviceConfig = {
      StateDirectory = lib.mkForce [ ]; # Disable systemd management
    };

    systemd.tmpfiles.rules = [
      "d /persist/var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -"
      "d /var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -"
    ];
  };
}
