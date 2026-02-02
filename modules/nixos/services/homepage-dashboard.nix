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
            provider = "duckduckgo";
            target = "_blank";
            showSearchSuggestions = true;
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
        {
          datetime = {
            text_size = "xl";
            format = {
              dateStyle = "long";
              timeStyle = "short";
              hour12 = false;
            };
          };
        }
      ];

      services = [
        {
          "Media Services" = flatten [
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
              };
            })
            (optional (pathExists "/var/lib/bazarr") {
              "Bazarr" = {
                icon = "bazarr.png";
                href = "http://localhost:6767";
                description = "Subtitle Management";
              };
            })
          ];
        }
        {
          "Monitoring" = flatten [
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
            (optional (pathExists "/var/lib/loki") {
              "Loki" = {
                icon = "loki.png";
                href = "http://localhost:3100";
                description = "Log Aggregation";
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
            {
              "Qdrant" = {
                icon = "qdrant.png";
                href = "http://localhost:6333/dashboard";
                description = "Vector Database";
                container = "qdrant";
              };
            }
          ];
        }
        {
          "Infrastructure" = flatten [
            (optional (pathExists "/var/lib/immich") {
              "Immich" = {
                icon = "immich.png";
                href = "http://localhost:2283";
                description = "Photo Management";
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
