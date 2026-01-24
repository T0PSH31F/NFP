{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services-config.monitoring = {
    enable = mkEnableOption "Comprehensive monitoring stack with Prometheus, Loki, and Grafana";

    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain for Grafana access";
    };

    prometheus.port = mkOption {
      type = types.port;
      default = 9090;
      description = "Prometheus port";
    };

    loki.port = mkOption {
      type = types.port;
      default = 3100;
      description = "Loki port";
    };

    grafana.port = mkOption {
      type = types.port;
      default = 3000;
      description = "Grafana port";
    };
  };

  config = mkIf config.services-config.monitoring.enable {
    # ============================================================================
    # PROMETHEUS - Metrics Collection
    # ============================================================================
    services.prometheus = {
      enable = true;
      port = config.services-config.monitoring.prometheus.port;

      # Retention (default 15 days)
      retentionTime = "30d";

      # Exporters for system metrics
      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = [
            "systemd"
            "cpu"
            "diskstats"
            "filesystem"
            "loadavg"
            "meminfo"
            "netdev"
            "processes"
          ];
        };
      };

      # Scrape configurations
      scrapeConfigs = [
        # Prometheus itself
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services-config.monitoring.prometheus.port}" ];
            }
          ];
        }

        # Node exporter (system metrics)
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:9100" ];
            }
          ];
        }

        # Loki
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services-config.monitoring.loki.port}" ];
            }
          ];
        }

        # Grafana
        {
          job_name = "grafana";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services-config.monitoring.grafana.port}" ];
            }
          ];
        }
      ];
    };

    # ============================================================================
    # LOKI - Log Aggregation
    # ============================================================================
    services.loki = {
      enable = true;

      configuration = {
        server.http_listen_port = config.services-config.monitoring.loki.port;

        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
        };

        schema_config = {
          configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
          filesystem.directory = "/var/lib/loki/chunks";
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          retention_period = "30d";
        };

        table_manager = {
          retention_deletes_enabled = true;
          retention_period = "30d";
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
        };
      };
    };

    # Promtail - Ship systemd logs to Loki
    services.promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions.filename = "/var/lib/promtail/positions.yaml";

        clients = [
          {
            url = "http://localhost:${toString config.services-config.monitoring.loki.port}/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          # Systemd journal
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal_priority_keyword" ];
                target_label = "level";
              }
            ];
          }

          # System logs
          {
            job_name = "syslog";
            static_configs = [
              {
                targets = [ "localhost" ];
                labels = {
                  job = "syslog";
                  host = config.networking.hostName;
                  __path__ = "/var/log/messages";
                };
              }
            ];
          }
        ];
      };
    };

    # Fix promtail namespace error (conflicts with impermanence bind mounts)
    systemd.services.promtail.serviceConfig = {
      PrivateTmp = lib.mkForce false;
      ProtectSystem = lib.mkForce false;
      ProtectHome = lib.mkForce false;
      ReadWritePaths = [ "/var/lib/promtail" ];
    };

    # ============================================================================
    # GRAFANA - Visualization
    # ============================================================================
    services.grafana = {
      enable = true;

      settings = {
        server = {
          domain = config.services-config.monitoring.domain;
          http_port = config.services-config.monitoring.grafana.port;
          http_addr = "0.0.0.0";
        };

        analytics.reporting_enabled = false;

        # Default admin credentials (change after first login!)
        security = {
          admin_user = "admin";
          admin_password = "admin";
        };
      };

      provision = {
        enable = true;

        # Data sources
        datasources.settings.datasources = [
          # Prometheus
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:${toString config.services-config.monitoring.prometheus.port}";
            isDefault = true;
            jsonData = {
              timeInterval = "30s";
            };
          }

          # Loki
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://localhost:${toString config.services-config.monitoring.loki.port}";
            jsonData = {
              maxLines = 1000;
            };
          }
        ];

        # Default dashboards
        dashboards.settings.providers = [
          {
            name = "Default";
            options.path = "/var/lib/grafana/dashboards";
          }
        ];
      };
    };

    # Create dashboard directory
    systemd.tmpfiles.rules = [
      "d /var/lib/grafana/dashboards 0755 grafana grafana -"
    ];

    # ============================================================================
    # FIREWALL
    # ============================================================================
    networking.firewall.allowedTCPPorts = [
      config.services-config.monitoring.prometheus.port # Prometheus
      config.services-config.monitoring.loki.port # Loki
      config.services-config.monitoring.grafana.port # Grafana
      9100 # Node exporter
      9080 # Promtail
    ];

    # Packages
    environment.systemPackages = with pkgs; [
      prometheus # Contains promtool
      grafana # Grafana CLI
    ];

    # Ensure monitoring data is persisted
    environment.persistence."/persist" =
      mkIf (config.services-config.monitoring.enable && config.system-config.impermanence.enable)
        {
          directories = [
            "/var/lib/prometheus2"
            "/var/lib/loki"
            "/var/lib/grafana"
            "/var/lib/promtail"
          ];
        };
  };
}
