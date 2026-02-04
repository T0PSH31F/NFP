# Homepage Dashboard
# Documentation: https://gethomepage.dev
# Service Widgets (Plugin Catalog): https://gethomepage.dev/latest/widgets/services/
# Customization: https://gethomepage.dev/latest/configs/settings/
# modules/nixos/services/homepage-dashboard.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services-config.homepage-dashboard;

  # Safe port getter with fallback
  getServicePort =
    service: default:
    if hasAttr service config.services && hasAttr "port" config.services.${service} then
      toString config.services.${service}.port
    else
      toString default;

  # Check if service is enabled
  isServiceEnabled =
    service:
    hasAttr service config.services
    && hasAttr "enable" config.services.${service}
    && config.services.${service}.enable;
in
{
  options.services-config.homepage-dashboard = {
    enable = mkEnableOption "Homepage Dashboard";

    port = mkOption {
      type = types.port;
      default = 8082;
      description = "Port to expose Homepage Dashboard on";
    };

    noctalia = {
      enable = mkEnableOption "Noctalia theme integration";

      templatePath = mkOption {
        type = types.str;
        default = "/etc/homepage-dashboard/noctalia-theme.yaml";
        description = "Path to Noctalia-generated theme configuration";
      };
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Domain name for the dashboard (for reverse proxy)";
    };
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;

      settings = mkMerge [
        {
          title = "Grandlix Dashboard";
          favicon = "https://raw.githubusercontent.com/gethomepage/homepage/main/public/homepage.png";

          # Base theme (will be overridden by Noctalia if enabled)
          theme = "dark";
          color = "slate";

          layout = {
            "Media Services" = {
              style = "row";
              columns = 4;
              icon = "mdi-multimedia";
            };
            "Monitoring" = {
              style = "row";
              columns = 3;
              icon = "mdi-chart-line";
            };
            "AI & Automation" = {
              style = "row";
              columns = 4;
              icon = "mdi-robot";
            };
            "Infrastructure" = {
              style = "row";
              columns = 4;
              icon = "mdi-server";
            };
          };

          headerStyle = "boxed";
          cardBlur = "sm";
          hideVersion = true;
        }

        # Noctalia theme override
        (mkIf cfg.noctalia.enable {
          # Theme colors will be injected via custom CSS
          customCss = builtins.readFile cfg.noctalia.templatePath;
        })
      ];

      widgets = [
        {
          search = {
            provider = "perplexity";
            target = "_blank";
            showSearchSuggestions = true;
            focus = true;
          };
        }
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
            uptime = true;
          };
        }
      ];

      services = [
        {
          "Media Services" = flatten [
            (optional (pathExists "/var/lib/jellyfin") {
              "Jellyfin" = {
                icon = "jellyfin.png";
                href = "http://localhost:8096";
                description = "Media Server";
                widget = {
                  type = "jellyfin";
                  url = "http://localhost:8096";
                  key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                };
              };
            })
            (optional (isServiceEnabled "calibre-web-app") {
              "Calibre-Web" = {
                icon = "calibre-web.png";
                href = "http://localhost:${getServicePort "calibre-web-app" 8083}";
                description = "E-Book Library";
              };
            })
            (optional (isServiceEnabled "audiobookshelf-app") {
              "BookLore (Audiobookshelf)" = {
                icon = "audiobookshelf.png";
                href = "http://localhost:${getServicePort "audiobookshelf-app" 13378}";
                description = "Audiobook Server";
                widget = {
                  type = "audiobookshelf";
                  url = "http://localhost:${getServicePort "audiobookshelf-app" 13378}";
                  key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY}}";
                };
              };
            })
            (optional (pathExists "/var/lib/sonarr") {
              "Sonarr" = {
                icon = "sonarr.png";
                href = "http://localhost:8989";
                description = "TV Series Management";
                widget = {
                  type = "sonarr";
                  url = "http://localhost:8989";
                  key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
                };
              };
            })
            (optional (pathExists "/var/lib/radarr") {
              "Radarr" = {
                icon = "radarr.png";
                href = "http://localhost:7878";
                description = "Movie Management";
                widget = {
                  type = "radarr";
                  url = "http://localhost:7878";
                  key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
                };
              };
            })
            (optional (pathExists "/var/lib/prowlarr") {
              "Prowlarr" = {
                icon = "prowlarr.png";
                href = "http://localhost:9696";
                description = "Indexer Manager";
                widget = {
                  type = "prowlarr";
                  url = "http://localhost:9696";
                  key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
                };
              };
            })
            (optional (pathExists "/var/lib/bazarr") {
              "Bazarr" = {
                icon = "bazarr.png";
                href = "http://localhost:6767";
                description = "Subtitle Management";
                widget = {
                  type = "bazarr";
                  url = "http://localhost:6767";
                  key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
                };
              };
            })
            (optional (isServiceEnabled "deluge-server") {
              "Deluge" = {
                icon = "deluge.png";
                href = "http://localhost:${getServicePort "deluge-server" 8113}";
                description = "Torrent Client";
                widget = {
                  type = "deluge";
                  url = "http://localhost:${getServicePort "deluge-server" 8113}";
                  password = "{{HOMEPAGE_VAR_DELUGE_PASSWORD}}";
                };
              };
            })
            (optional (isServiceEnabled "transmission-server") {
              "Transmission" = {
                icon = "transmission.png";
                href = "http://localhost:${getServicePort "transmission-server" 9091}";
                description = "Torrent Client";
                widget = {
                  type = "transmission";
                  url = "http://localhost:${getServicePort "transmission-server" 9091}";
                  username = "{{HOMEPAGE_VAR_TRANSMISSION_USERNAME}}";
                  password = "{{HOMEPAGE_VAR_TRANSMISSION_PASSWORD}}";
                };
              };
            })
          ];
        }
        {
          "Monitoring" = flatten [
            (optional (isServiceEnabled "glances-server") {
              "Glances" = {
                icon = "glances.png";
                href = "http://localhost:${getServicePort "glances-server" 61208}";
                description = "System Monitoring";
                widget = {
                  type = "glances";
                  url = "http://localhost:${getServicePort "glances-server" 61208}";
                };
              };
            })
            (optional (isServiceEnabled "grafana") {
              "Grafana" = {
                icon = "grafana.png";
                href = "http://localhost:${getServicePort "grafana" 3000}";
                description = "Metrics & Dashboards";
              };
            })
            (optional (isServiceEnabled "prometheus") {
              "Prometheus" = {
                icon = "prometheus.png";
                href = "http://localhost:${getServicePort "prometheus" 9090}";
                description = "Metrics Collection";
              };
            })
            (optional (isServiceEnabled "pihole-server") {
              "Pi-hole" = {
                icon = "pi-hole.png";
                href = "http://localhost:${getServicePort "pihole-server" 8089}/admin";
                description = "DNS Ad Blocker";
                widget = {
                  type = "pihole";
                  url = "http://localhost:${getServicePort "pihole-server" 8089}";
                  key = "{{HOMEPAGE_VAR_PIHOLE_KEY}}";
                };
              };
            })
          ];
        }
        {
          "AI & Automation" = [
            {
              "Open WebUI" = {
                icon = "openai.png";
                href = "http://localhost:8080";
                description = "LLM Interface";
                container = "open-webui";
              };
            }
            {
              "SillyTavern" = {
                icon = "mdi-chat";
                href = "http://localhost:8000";
                description = "Character AI Chat";
                container = "sillytavern";
              };
            }
            {
              "n8n" = {
                icon = "n8n.png";
                href = "http://localhost:5678";
                description = "Workflow Automation";
              };
            }
          ];
        }
        {
          "Infrastructure" = flatten [
            (optional (isServiceEnabled "filebrowser-app") {
              "FileBrowser" = {
                icon = "filebrowser.png";
                href = "http://localhost:${getServicePort "filebrowser-app" 8085}";
                description = "Web File Manager";
              };
            })
            (optional (isServiceEnabled "nextcloud") {
              "Nextcloud" = {
                icon = "nextcloud.png";
                href = "http://localhost:6380";
                description = "Cloud Storage";
                widget = {
                  type = "nextcloud";
                  url = "http://localhost:6380";
                  username = "{{HOMEPAGE_VAR_NEXTCLOUD_USERNAME}}";
                  password = "{{HOMEPAGE_VAR_NEXTCLOUD_PASSWORD}}";
                };
              };
            })
            (optional (isServiceEnabled "home-assistant-server") {
              "Home Assistant" = {
                icon = "home-assistant.png";
                href = "http://localhost:${getServicePort "home-assistant-server" 8123}";
                description = "Home Automation";
                widget = {
                  type = "homeassistant";
                  url = "http://localhost:${getServicePort "home-assistant-server" 8123}";
                  key = "{{HOMEPAGE_VAR_HASS_KEY}}";
                };
              };
            })
            (optional (isServiceEnabled "headscale-server") {
              "Headscale" = {
                icon = "headscale.png";
                href = "http://localhost:${getServicePort "headscale-server" 8086}/web";
                description = "Tailscale Control Server";
              };
            })
            (optional (isServiceEnabled "searxng") {
              "SearXNG" = {
                icon = "searxng.png";
                href = "http://localhost:${getServicePort "searxng" 8888}";
                description = "Meta Search Engine";
              };
            })
            (optional (pathExists "/var/lib/immich") {
              "Immich" = {
                icon = "immich.png";
                href = "http://localhost:2283";
                description = "Photo Management";
                widget = {
                  type = "immich";
                  url = "http://localhost:2283";
                  key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                };
              };
            })
            {
              "Portainer" = {
                icon = "portainer.png";
                href = "http://localhost:9000";
                description = "Container Management";
              };
            }
            (optional (pathExists "/var/lib/matrix-synapse") {
              "Matrix Synapse" = {
                icon = "matrix.png";
                href = "http://localhost:8008";
                description = "Federated Chat";
              };
            })
            (optional (isServiceEnabled "mautrix-bridges") {
              "Mautrix Bridges" = {
                icon = "matrix.png";
                href = "http://localhost:8008/_matrix/static/";
                description = "Matrix Bridges Status";
              };
            })
            {
              "Caddy" = {
                icon = "caddy.png";
                href = "http://localhost:2019";
                description = "Web Server";
              };
            }
          ];
        }
      ];
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # User/Group with proper permissions
    users.users.homepage-dashboard = {
      isSystemUser = true;
      group = "homepage-dashboard";
      extraGroups = [ "docker" ];
    };
    users.groups.homepage-dashboard = { };

    # Impermanence support
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/homepage-dashboard";
          user = "homepage-dashboard";
          group = "homepage-dashboard";
          mode = "0700";
        }
      ];
    };

    # Fix StateDirectory conflict with impermanence
    systemd.services.homepage-dashboard = {
      serviceConfig = {
        StateDirectory = mkForce [ ];
        ReadWritePaths = [ "/var/lib/homepage-dashboard" ];
      };

      # Ensure Docker socket access
      after = [ "docker.socket" ];
      requires = mkIf config.virtualisation.docker.enable [ "docker.socket" ];
    };

    # Tmpfiles rules for directory creation
    systemd.tmpfiles.rules = [
      "d /var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -"
    ]
    ++ optional config.system-config.impermanence.enable "d /persist/var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -";
  };
}
