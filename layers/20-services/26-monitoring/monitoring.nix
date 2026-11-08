{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.monitoring;
  localHost = config.networking.hostName;
  isServer = cfg.enable && cfg.role == "server";
  baseDomain =
    config.layers.meta.tailnetDomain or config.services.headscale-server.baseDomain or "nfp.nix";
  fleetHosts = [
    "luffy"
    "z0r0"
    "sanji"
  ];
in
{
  options.layers.layer-20.services.config.monitoring = {
    enable = mkEnableOption "Comprehensive monitoring stack with Prometheus, Loki, and Grafana";
    role = mkOption {
      type = types.enum [
        "server"
        "agent"
      ];
      default = if localHost == "luffy" then "server" else "agent";
      description = ''
        server: runs the single central Prometheus/Loki/Grafana stack (luffy).
        agent: only exports node metrics (scraped by the server) and ships the journal to the server's Loki.
      '';
    };
    serverHost = mkOption {
      type = types.str;
      default = "luffy";
      description = "Fleet host that runs the central monitoring stack";
    };
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain for Grafana access";
    };
    backend = mkOption {
      type = types.enum [
        "prometheus"
        "victoriametrics"
      ];
      default = "victoriametrics";
      description = "Metrics storage backend: victoriametrics (recommended, ultra-low RAM) or prometheus";
    };
    victoriametrics.port = mkOption {
      type = types.port;
      default = 8428;
      description = "VictoriaMetrics single-node port";
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
    fleetNodeTargets = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra node-exporter targets (host:port) scraped by this Prometheus (fleet monitoring)";
    };
  };

  config = mkMerge [
    # Every node exports host metrics; the central server scrapes them over the tailnet.
    {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
          "cpu"
          "diskstats"
          "filesystem"
          "btrfs"
          "loadavg"
          "meminfo"
          "netdev"
        ];
        # eval results written by scripts/run_evals.py land here
        extraFlags = [ "--collector.textfile.directory=/var/lib/node-exporter-textfile" ];
      };
      systemd.tmpfiles.rules = [ "d /var/lib/node-exporter-textfile 0775 root root -" ];
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9100 ];
    }

    # Journal shipping (agents push to the server's Loki, the server pushes locally).
    (mkIf cfg.enable {
      layers.layer-20.services.config.telemetry.enable = lib.mkDefault true;
      services.alloy = {
        enable = true;
        configPath = "/etc/alloy";
      };
      systemd.services.alloy.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "alloy";
        Group = "alloy";
        ConfigurationDirectory = lib.mkForce "alloy";
      };
      users = {
        users.alloy = {
          isSystemUser = true;
          group = "alloy";
          uid = 985;
          description = "Grafana Alloy Daemon";
        };
        groups.alloy = { };
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
            host    = "${localHost}",
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
            url = "http://${
              if isServer then "127.0.0.1" else "${cfg.serverHost}.${baseDomain}"
            }:${toString cfg.loki.port}/loki/api/v1/push"
          }
        }
      '';
    })

    (mkIf isServer (
      let
        enabledServices = filterAttrs (_name: svc: svc.enable) (config.nfp.services or { });
        httpServices = filterAttrs (
          _name: svc: svc.healthcheck.enable && svc.healthcheck.skipReason == null
        ) enabledServices;

        # AI services without a native /metrics endpoint: probe their health URLs.
        # Loopback-bound services run on the server, so they are probed locally.
        aiProbes = {
          hermes-gateway = {
            host = "luffy";
            port = 8642;
            path = "/health";
          };
          brain-service = {
            host = "luffy";
            port = 8010;
            path = "/health";
          };
          pi-durable-daemon = {
            host = "luffy";
            port = 8089;
            path = "/health";
          };
          omniroute = {
            host = "luffy";
            port = 20129;
            path = "/";
            module = "http_alive";
          };
          extreme-router = {
            host = "z0r0";
            port = 20128;
            path = "/v1/models";
            module = "http_alive";
          };
        };
        aiProbeScrapeConfigs = mapAttrsToList (name: p: {
          job_name = "blackbox-ai-${name}";
          metrics_path = "/probe";
          params.module = [ (p.module or "http_2xx") ];
          static_configs = [
            {
              targets = [
                "http://${
                  if p.host == localHost then "127.0.0.1" else "${p.host}.${baseDomain}"
                }:${toString p.port}${p.path}"
              ];
              labels = {
                service = name;
                machine = p.host;
                tier = "ai";
              };
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
        }) aiProbes;

        contractBlackboxScrapeConfigs = mapAttrsToList (
          name: svc:
          let
            isLocal = svc.host == localHost;
            targetUrl =
              if isLocal then
                "http://${svc.bind}:${toString svc.port}${svc.healthcheck.path}"
              else if svc.tls != "none" then
                "http://${svc.tailnetName}.${baseDomain}${svc.healthcheck.path}"
              else
                "http://${svc.host}.${baseDomain}:${toString svc.port}${svc.healthcheck.path}";
          in
          {
            job_name = "blackbox-${name}";
            metrics_path = "/probe";
            params.module = [ "http_2xx" ];
            static_configs = [
              {
                targets = [ targetUrl ];
                labels = {
                  service = name;
                  machine = svc.host;
                };
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
        ) httpServices;

        alertRuleGroups = [
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
              {
                alert = "ServiceProbeFailed";
                expr = "probe_success == 0";
                for = "5m";
                labels = {
                  severity = "critical";
                };
                annotations = {
                  summary = "Blackbox probe failed for {{ $labels.service }}";
                  description = "Service {{ $labels.service }} target {{ $labels.instance }} probe failed.";
                };
              }
              {
                alert = "FleetHealthcheckStalled";
                expr = "node_systemd_unit_state{name=\"fleet-healthcheck.service\", state=\"active\"} == 0";
                for = "15m";
                labels = {
                  severity = "warning";
                };
                annotations = {
                  summary = "Fleet healthcheck runner stalled or inactive";
                  description = "fleet-healthcheck.service on {{ $labels.instance }} is not active.";
                };
              }
              {
                alert = "JevEngineDown";
                expr = "jev_engine_up == 0";
                for = "2m";
                labels = {
                  severity = "critical";
                };
                annotations = {
                  summary = "Jev Decision Engine down";
                  description = "Jev Decision Engine daemon on {{ $labels.instance }} is unreachable.";
                };
              }
              {
                alert = "DecisionConfidenceAnomaly";
                expr = "rate(jev_decision_confidence_score_sum[10m]) / rate(jev_decision_confidence_score_count[10m]) < 0.60";
                for = "10m";
                labels = {
                  severity = "warning";
                };
                annotations = {
                  summary = "Jev decision confidence anomaly";
                  description = "Average Jev decision confidence dropped below 0.60 over 10 minutes.";
                };
              }
              {
                alert = "HotEnterpriseLeadDetected";
                expr = "increase(jev_decisions_total{workflow=\"lead_triage\"}[5m]) > 0";
                labels = {
                  severity = "critical";
                };
                annotations = {
                  summary = "High-priority enterprise lead triaged";
                  description = "New enterprise lead evaluated and staged by Jev System-1.";
                };
              }
              {
                alert = "SecurityMaliciousEmailDetected";
                expr = "increase(jev_decisions_total{workflow=\"email_triage\"}[5m]) > 0";
                labels = {
                  severity = "warning";
                };
                annotations = {
                  summary = "Security alert from Jev email triage";
                  description = "Jev email triage flagged security or action-required email.";
                };
              }
            ];
          }
        ];

        allScrapeConfigs = [
          {
            job_name = if cfg.backend == "victoriametrics" then "victoriametrics" else "prometheus";
            static_configs = [
              {
                targets = [
                  "localhost:${
                    toString (
                      if cfg.backend == "victoriametrics" then
                        cfg.victoriametrics.port
                      else
                        config.layers.layer-20.services.config.monitoring.prometheus.port
                    )
                  }"
                ];
              }
            ];
          }
          {
            job_name = "node";
            static_configs = [ { targets = [ "localhost:9100" ]; } ];
          }
          {
            job_name = "node-fleet";
            static_configs = [
              {
                targets =
                  map (h: "${h}.${baseDomain}:9100") (filter (h: h != localHost) fleetHosts) ++ cfg.fleetNodeTargets;
              }
            ];
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
                targets = [
                  "localhost:${toString config.layers.layer-20.services.config.monitoring.loki.port}"
                ];
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
          # LangGraph metrics
          (mkIf (config.services.ai-services.langgraph.enable or false) {
            job_name = "langgraph";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.ai-services.langgraph.port}"
                ];
              }
            ];
          })
          # Jev System-1 decision & telemetry exporter
          {
            job_name = "jev";
            metrics_path = "/metrics";
            static_configs = [ { targets = [ "127.0.0.1:20132" ]; } ];
          }
        ]
        ++ contractBlackboxScrapeConfigs
        ++ aiProbeScrapeConfigs;

      in
      {
        nfp.services = {
          prometheus = {
            enable = true;
            host = config.networking.hostName;
            bind = "127.0.0.1";
            port = if cfg.backend == "victoriametrics" then cfg.victoriametrics.port else cfg.prometheus.port;
            tailnetName = "prometheus";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/-/healthy";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "usopp";
              order = 10;
              title = if cfg.backend == "victoriametrics" then "VictoriaMetrics" else "Prometheus";
              subtitle =
                if cfg.backend == "victoriametrics" then "Ultra-Low RAM TSDB Radar" else "Tactical Metric Radar";
              icon = if cfg.backend == "victoriametrics" then "victoriametrics" else "prometheus";
              metric = {
                mode = "native-api";
                adapter = "prometheus";
                fields = [
                  "targetsUp"
                  "targetsTotal"
                  "alertsActive"
                ];
              };
            };
          };

          grafana = {
            enable = true;
            host = config.networking.hostName;
            bind = "0.0.0.0";
            port = config.layers.layer-20.services.config.monitoring.grafana.port;
            tailnetName = "grafana";
            tls = "none";
            healthcheck = {
              enable = true;
              path = "/api/health";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "usopp";
              order = 20;
              title = "Grafana";
              subtitle = "Tactical Command Views";
              icon = "grafana";
              metric = {
                mode = "health-only";
              };
            };
          };

          loki = {
            enable = true;
            host = config.networking.hostName;
            bind = "127.0.0.1";
            port = config.layers.layer-20.services.config.monitoring.loki.port;
            tailnetName = "loki";
            tls = "none";
            healthcheck = {
              enable = true;
              path = "/ready";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "usopp";
              order = 22;
              title = "Loki Logs";
              subtitle = "Grafana Explore Log Viewer";
              icon = "loki";
              dashboardUrl = "http://${config.networking.hostName}.${
                config.layers.meta.tailnetDomain or "nfp.nix"
              }:${toString config.layers.layer-20.services.config.monitoring.grafana.port}/explore";
              metric = {
                mode = "health-only";
              };
            };
          };
        };

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
        # SERVICES - Prometheus, Alertmanager, Alloy, Loki, Grafana
        # ============================================================================
        services = {
          prometheus = {
            enable = cfg.backend == "prometheus";
            port = config.layers.layer-20.services.config.monitoring.prometheus.port;
            retentionTime = "30d";
            exporters = {
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
                    # Authenticated/API-only services: any non-5xx answer means the process is alive.
                    modules.http_alive = {
                      prober = "http";
                      http.valid_status_codes = [
                        200
                        204
                        301
                        302
                        307
                        401
                        403
                        404
                      ];
                    };
                  }
                );
              };
            };
            rules = [
              (builtins.toJSON {
                groups = alertRuleGroups;
              })
            ];
            scrapeConfigs = mkIf (cfg.backend == "prometheus") allScrapeConfigs;
          };

          victoriametrics = mkIf (cfg.backend == "victoriametrics") {
            enable = true;
            listenAddress = "127.0.0.1:${toString cfg.victoriametrics.port}";
            retentionPeriod = "30d";
            prometheusConfig.scrape_configs = allScrapeConfigs;
          };

          vmalert.instances.main = mkIf (cfg.backend == "victoriametrics") {
            enable = true;
            settings = {
              "datasource.url" = "http://127.0.0.1:${toString cfg.victoriametrics.port}";
              "notifier.url" = [ "http://127.0.0.1:9093" ];
              rule = [
                (pkgs.writeText "vmalert-rules.json" (
                  builtins.toJSON {
                    groups = alertRuleGroups;
                  }
                ))
              ];
            };
          };

          alertmanager-ntfy.enable = true;

          # ============================================================================
          # LOKI - Log Aggregation
          # ============================================================================
          loki = {
            enable = true;
            configuration = {
              server.http_listen_port = config.layers.layer-20.services.config.monitoring.loki.port;
              auth_enabled = false;
              common = {
                # Pin instance address so memberlist-kv init does not depend on
                # live NICs (NetworkManager/tailscaled are down during switch and
                # no non-loopback address is found → start-limit-hit).
                instance_addr = "127.0.0.1";
                ring = {
                  instance_interface_names = [
                    "lo"
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
          grafana = {
            enable = true;
            settings = {
              dashboards.default_home_dashboard_path = "${./dashboards/fleet-status.json}";
              server = {
                http_addr = "0.0.0.0";
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
                  url =
                    if cfg.backend == "victoriametrics" then
                      "http://127.0.0.1:${toString cfg.victoriametrics.port}"
                    else
                      "http://127.0.0.1:${toString config.layers.layer-20.services.config.monitoring.prometheus.port}";
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
        };

        # Enable ntfy-sh and alertmanager-ntfy bridge
        layers.layer-20.services.config.ntfy-sh.enable = true;

        # Agents push logs to Loki and operators reach Prometheus/Grafana over the tailnet
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
          cfg.loki.port
          (if cfg.backend == "victoriametrics" then cfg.victoriametrics.port else cfg.prometheus.port)
          cfg.grafana.port
        ];

        # Custom Exporter for Langfuse metrics & Alloy service config
        systemd.services = {
          langfuse-exporter = {
            description = "Langfuse Metrics Exporter for Prometheus";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network.target"
              "postgresql.service"
            ];
            serviceConfig = {
              ExecStart = "${pkgs.python3}/bin/python3 ${pkgs.writeText "langfuse-exporter.py" ''
                import http.server
                import urllib.request
                import subprocess
                import json
                import os

                LANGFUSE_URL = "http://127.0.0.1:3005/api/public/health"
                PORT = 9898
                PSQL_BIN = "${pkgs.postgresql}/bin/psql"

                class ExporterHandler(http.server.BaseHTTPRequestHandler):
                    def do_GET(self):
                        if self.path == '/metrics':
                            traces_count = 0
                            total_tokens = 0
                            total_cost = 0.0
                            observations_count = 0
                            status_up = 0
                            try:
                                req = urllib.request.Request(LANGFUSE_URL, headers={"User-Agent": "Langfuse-Exporter/1.0"})
                                with urllib.request.urlopen(req, timeout=4) as response:
                                    if response.status == 200:
                                        status_up = 1
                            except Exception:
                                status_up = 0

                            if os.path.exists(PSQL_BIN):
                                try:
                                    cmd = [
                                        PSQL_BIN,
                                        "-q", "-X",
                                        "-h", "127.0.0.1",
                                        "-U", "postgres",
                                        "-d", "langfuse",
                                        "-t", "-A", "-F", ",",
                                        "-c", "SELECT count(*) FROM traces; SELECT count(*), coalesce(sum(total_tokens), 0), coalesce(sum(calculated_total_cost), 0) FROM observations;"
                                    ]
                                    env = os.environ.copy()
                                    env["PGOPTIONS"] = "--client-min-messages=error"
                                    res = subprocess.run(cmd, capture_output=True, text=True, timeout=5, env=env)
                                    if res.returncode == 0:
                                        lines = [l.strip() for l in res.stdout.strip().splitlines() if l.strip()]
                                        if len(lines) >= 2:
                                            traces_count = int(lines[0])
                                            parts = lines[1].split(',')
                                            observations_count = int(parts[0])
                                            total_tokens = int(float(parts[1]))
                                            total_cost = float(parts[2])
                                except Exception:
                                    pass

                            output = (
                                f"# HELP langfuse_up Reachability of Langfuse health API\n"
                                f"# TYPE langfuse_up gauge\n"
                                f"langfuse_up {status_up}\n"
                                f"# HELP langfuse_traces_total Total trace count\n"
                                f"# TYPE langfuse_traces_total gauge\n"
                                f"langfuse_traces_total {traces_count}\n"
                                f"# HELP langfuse_observations_total Total observation count\n"
                                f"# TYPE langfuse_observations_total gauge\n"
                                f"langfuse_observations_total {observations_count}\n"
                                f"# HELP langfuse_tokens_total Total tokens consumed\n"
                                f"# TYPE langfuse_tokens_total gauge\n"
                                f"langfuse_tokens_total {total_tokens}\n"
                                f"# HELP langfuse_cost_dollars Total calculated cost in USD\n"
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
              DynamicUser = false;
              User = "postgres";
            };
          };
        };

        # ============================================================================
        # Environment - Packages, Persistence
        # ============================================================================
        environment = {
          # Include notification and exporter packages
          systemPackages = with pkgs; [
            ntfy-sh
            prometheus
            prometheus-node-exporter
            victoriametrics
          ];

          # Ensure data is persisted
          persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
            directories = [
              "/var/lib/prometheus"
              "/var/lib/loki"
              "/var/lib/grafana"
            ];
          };
        };
      }
    ))
  ];
}
