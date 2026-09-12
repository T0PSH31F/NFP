{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-20.services.config.monitoring = {
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
      default = 3008;
      description = "Grafana port";
    };
  };
  config = mkIf config.layers.layer-20.services.config.monitoring.enable {
    clan.core.vars.generators.grafana = {
      files."secret-key" = {
        secret = true;
        owner = "grafana";
        group = "grafana";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -hex 24 | tr -d '\n' > "$out/secret-key"
      '';
    };
    # Grafana admin password from sops
    sops.secrets.grafana_admin_password = {
      sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
      owner = "grafana";
      group = "grafana";
    };
    # ============================================================================
    # PROMETHEUS - Metrics Collection
    # ============================================================================
    services.prometheus = {
      enable = true;
      port = config.layers.layer-20.services.config.monitoring.prometheus.port;
      retentionTime = "30d";
      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = [
            "systemd"
            "cpu"
            "diskstats"
            "filesystem"
            "btrfs"
            "loadavg"
            "meminfo"
            "netdev"
            "processes"
          ];
        };
        postgres = {
          enable = true;
          port = 9187;
        };
        wireguard = {
          enable = true;
          port = 9586;
        };
        blackbox = {
          enable = true;
          configFile = pkgs.writeText "blackbox.yml" (
            builtins.toJSON {
              modules.http_2xx = {
                prober = "http";
                http.valid_status_codes = [ 200 ];
              };
            }
          );
        };
      };
      rules = [
        (builtins.toJSON {
          groups = [
            {
              name = "service-alerts";
              rules = [
                {
                  alert = "ServiceDown";
                  expr = "up == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Instance {{ $labels.instance }} down";
                    description = "Service {{ $labels.job }} target {{ $labels.instance }} is down.";
                  };
                }
              ];
            }
          ];
        })
      ];
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [
                "localhost:${toString config.layers.layer-20.services.config.monitoring.prometheus.port}"
              ];
            }
          ];
        }
        {
          job_name = "node";
          static_configs = [ { targets = [ "localhost:9100" ]; } ];
        }
        {
          job_name = "postgres";
          static_configs = [ { targets = [ "localhost:9187" ]; } ];
        }
        {
          job_name = "wireguard";
          static_configs = [ { targets = [ "localhost:9586" ]; } ];
        }
        {
          job_name = "langfuse";
          static_configs = [ { targets = [ "localhost:9898" ]; } ];
        }
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [ "localhost:${toString config.layers.layer-20.services.config.monitoring.loki.port}" ];
            }
          ];
        }
        {
          job_name = "grafana";
          static_configs = [
            {
              targets = [
                "localhost:${toString config.layers.layer-20.services.config.monitoring.grafana.port}"
              ];
            }
          ];
        }
        # Caddy metrics
        (mkIf (config.services.caddy.enable or false) {
          job_name = "caddy";
          metrics_path = "/metrics";
          static_configs = [ { targets = [ "127.0.0.1:2019" ]; } ];
        })
        # Matrix Synapse metrics
        (mkIf (config.services.matrix-synapse.enable or false) {
          job_name = "matrix-synapse";
          metrics_path = "/_synapse/metrics";
          static_configs = [ { targets = [ "127.0.0.1:8008" ]; } ];
        })
        # n8n metrics
        (mkIf (config.services.n8n.enable or false) {
          job_name = "n8n";
          metrics_path = "/metrics";
          static_configs = [ { targets = [ "127.0.0.1:5678" ]; } ];
        })
        # Kong AI Gateway metrics
        (mkIf (config.services.ai-services.kong-gateway.enable or false) {
          job_name = "kong";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.ai-services.kong-gateway.proxyPort}" ];
            }
          ];
        })
        # LangGraph metrics
        (mkIf (config.services.ai-services.langgraph.enable or false) {
          job_name = "langgraph";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.ai-services.langgraph.port}" ];
            }
          ];
        })
        # Exportarr - Sonarr / Radarr / Lidarr / Readarr / Bazarr / Prowlarr
        {
          job_name = "exportarr-sonarr";
          static_configs = [ { targets = [ "127.0.0.1:9707" ]; } ];
        }
        {
          job_name = "exportarr-radarr";
          static_configs = [ { targets = [ "127.0.0.1:9708" ]; } ];
        }
        {
          job_name = "exportarr-lidarr";
          static_configs = [ { targets = [ "127.0.0.1:9709" ]; } ];
        }
        {
          job_name = "exportarr-readarr";
          static_configs = [ { targets = [ "127.0.0.1:9710" ]; } ];
        }
        {
          job_name = "exportarr-bazarr";
          static_configs = [ { targets = [ "127.0.0.1:9711" ]; } ];
        }
        {
          job_name = "exportarr-prowlarr";
          static_configs = [ { targets = [ "127.0.0.1:9712" ]; } ];
        }
        # qBittorrent exporter
        {
          job_name = "qbittorrent";
          static_configs = [ { targets = [ "127.0.0.1:8095" ]; } ];
        }
        # Cloudflare exporter
        {
          job_name = "cloudflare";
          static_configs = [ { targets = [ "127.0.0.1:9199" ]; } ];
        }
        # Restic exporter
        {
          job_name = "restic";
          static_configs = [ { targets = [ "127.0.0.1:9753" ]; } ];
        }
        # Smokeping prober
        {
          job_name = "smokeping";
          static_configs = [ { targets = [ "127.0.0.1:9374" ]; } ];
        }
        # Tailscale exporter
        {
          job_name = "tailscale";
          static_configs = [ { targets = [ "127.0.0.1:9095" ]; } ];
        }
        # Hermes API health
        {
          job_name = "blackbox-hermes";
          metrics_path = "/probe";
          params.module = [ "http_2xx" ];
          static_configs = [
            {
              targets = [
                "http://127.0.0.1:8642/health"
                "http://127.0.0.1:8010/health"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              replacement = "127.0.0.1:9115";
              target_label = "__address__";
            }
          ];
        }
      ];
    };

    # Enable ntfy-sh and alertmanager-ntfy bridge
    layers.layer-20.services.config.ntfy-sh.enable = true;
    services.alertmanager-ntfy.enable = true;

    # Include notification and exporter packages
    environment.systemPackages = with pkgs; [
      ntfy-sh
      prometheus
      prometheus-node-exporter
    ];

    # Custom Exporter for Langfuse metrics
    systemd.services.langfuse-exporter = {
      description = "Langfuse Metrics Exporter for Prometheus";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${pkgs.writeText "langfuse-exporter.py" ''
          import http.server
          import urllib.request
          import json

          LANGFUSE_URL = "http://127.0.0.1:3005/api/public/metrics"
          PORT = 9898

          class ExporterHandler(http.server.BaseHTTPRequestHandler):
              def do_GET(self):
                  if self.path == '/metrics':
                      traces_count = 0
                      total_tokens = 0
                      total_cost = 0.0
                      status_up = 0
                      try:
                          req = urllib.request.Request(LANGFUSE_URL, headers={"User-Agent": "Langfuse-Exporter/1.0"})
                          with urllib.request.urlopen(req, timeout=5) as response:
                              if response.status == 200:
                                  status_up = 1
                                  data = json.loads(response.read().decode('utf-8'))
                                  traces_count = data.get("count", data.get("traces", 0))
                                  total_tokens = data.get("tokens", data.get("total_tokens", 0))
                                  total_cost = data.get("cost", data.get("total_cost", 0.0))
                      except Exception:
                          status_up = 0

                      output = (
                          f"# HELP langfuse_up Reachability of Langfuse metrics API\n"
                          f"# TYPE langfuse_up gauge\n"
                          f"langfuse_up {status_up}\n"
                          f"# HELP langfuse_traces_total Total trace count\n"
                          f"# TYPE langfuse_traces_total gauge\n"
                          f"langfuse_traces_total {traces_count}\n"
                          f"# HELP langfuse_tokens_total Total tokens\n"
                          f"# TYPE langfuse_tokens_total gauge\n"
                          f"langfuse_tokens_total {total_tokens}\n"
                          f"# HELP langfuse_cost_dollars Total cost in USD\n"
                          f"# TYPE langfuse_cost_dollars gauge\n"
                          f"langfuse_cost_dollars {total_cost}\n"
                      )
                      self.send_response(200)
                      self.send_header('Content-Type', 'text/plain; version=0.0.4')
                      self.end_headers()
                      self.wfile.write(output.encode('utf-8'))
                  else:
                      self.send_response(404)
                      self.end_headers()

          if __name__ == '__main__':
              server = http.server.HTTPServer(('127.0.0.1', PORT), ExporterHandler)
              server.serve_forever()
        ''}";
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
      };
    };
    # ============================================================================
    # ALLOY - Log Shipper (journald → Loki) — Promtail successor
    # ============================================================================
    services.alloy = {
      enable = true;
      configPath = "/etc/alloy";
    };

    environment.etc."alloy/config.alloy".text = ''
      logging {
        level = "warn"
      }
      loki.source.journal "hermes"  {
        max_age = "12h"
        forward_to = [loki.relabel.journal.receiver]
        labels = {
          job     = "systemd-journal",
          host    = "${config.networking.hostName}",
        }
      }
      loki.relabel "journal" {
        forward_to = [loki.write.default.receiver]
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
        rule {
          source_labels = ["__journal__hostname"]
          target_label  = "hostname"
        }
      }
      loki.write "default" {
        endpoint {
          url = "http://127.0.0.1:${toString config.layers.layer-20.services.config.monitoring.loki.port}/loki/api/v1/push"
        }
      }
    '';

    # Fix DynamicUser + ConfigurationDirectory conflict with impermanence
    systemd.services.alloy.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "alloy";
      Group = "alloy";
      ConfigurationDirectory = lib.mkForce "alloy";
    };

    users.users.alloy = {
      isSystemUser = true;
      group = "alloy";
      uid = 985;
      description = "Grafana Alloy Daemon";
    };
    users.groups.alloy = { };
    # ============================================================================
    # LOKI - Log Aggregation
    # ============================================================================
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = config.layers.layer-20.services.config.monitoring.loki.port;
        auth_enabled = false;
        common = {
          ring = {
            instance_interface_names = [
              "lo"
              "wlp0s20f3"
              "tailscale0"
            ];
            kvstore.store = "inmemory";
          };
        };
        memberlist.bind_addr = [ "127.0.0.1" ];
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
        schema_config.configs = [
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
    # ============================================================================
    # GRAFANA - Visualization
    # ============================================================================
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = config.layers.layer-20.services.config.monitoring.grafana.port;
          domain = config.layers.layer-20.services.config.monitoring.domain;
          root_url = "http://%(domain)s:%(http_port)s/";
        };
        security = {
          admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
          secret_key = "$__file{${config.clan.core.vars.generators.grafana.files."secret-key".path}}";
        };
      };
      provision.datasources = {
        settings.apiVersion = 1;
        settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.layers.layer-20.services.config.monitoring.prometheus.port}";
            isDefault = true;
            editable = true;
          }
          {
            name = "Loki";
            type = "loki";
            uid = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.layers.layer-20.services.config.monitoring.loki.port}";
            editable = true;
          }
        ];
      };
      provision.dashboards = {
        settings = {
          apiVersion = 1;
          providers = [
            {
              name = "hermes-dashboards";
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = false;
              updateIntervalSeconds = 30;
              allowUiUpdates = true;
              options.path = pkgs.symlinkJoin {
                name = "grafana-dashboards";
                paths = [ ./dashboards ];
              };
            }
          ];
        };
      };
    };
    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        "/var/lib/prometheus"
        "/var/lib/loki"
        "/var/lib/grafana"
      ];
    };
  };
}
