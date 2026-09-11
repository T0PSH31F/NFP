# Tier: 78-llm-routers
# Module: kong-gateway.nix
# Purpose: Kong API Gateway — central authenticated LLM proxy, plugin engine, & consumer secret gateway.
# Option Path: services.ai-services.kong-gateway
# Enabling Host Tags: ai-router, homelab, server
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  # ── Declarative Kong config (structural only) ─────────────────────
  # Services, routes, upstreams, and global plugins. Consumer API keys are
  # rendered separately by the sops template "kong-consumers" and mounted
  # alongside — Kong merges both via colon-separated KONG_DECLARATIVE_CONFIG.
  mkKongYml =
    cfg:
    pkgs.writeText "kong-base.yml" (
      builtins.toJSON {
        _format_version = "3.0";
        _transform = true;

        # ── Services (upstream LLM routers) ──────────────────────────
        services =
          # Manifest — frontier model routing
          (optional cfg.routers.manifest.enable {
            name = "manifest-llm";
            url = "http://127.0.0.1:${toString cfg.routers.manifest.port}";
            tags = [
              "llm"
              "frontier"
            ];
          })
          # FreeLLMAPI — free+paid aggregated pool
          ++ (optional cfg.routers.freellmapi.enable {
            name = "freellmapi-llm";
            url = "http://127.0.0.1:${toString cfg.routers.freellmapi.port}";
            tags = [
              "llm"
              "free-first"
            ];
          })
          # freellmpool — pure free-tier pool
          ++ (optional cfg.routers.freellmpool.enable {
            name = "freellmpool-llm";
            url = "http://127.0.0.1:${toString cfg.routers.freellmpool.port}";
            tags = [
              "llm"
              "free-only"
            ];
          })
          # Coding router — mutually exclusive (omniroute or extreme-router)
          ++ (optional (cfg.routers.codingRouter == "omniroute") {
            name = "omniroute-llm";
            url = "http://127.0.0.1:${toString cfg.routers.omniroute.port}";
            tags = [
              "llm"
              "coding"
            ];
          })
          ++ (optional (cfg.routers.codingRouter == "extreme-router") {
            name = "extremerouter-llm";
            url = "http://127.0.0.1:${toString cfg.routers.extreme-router.port}";
            tags = [
              "llm"
              "coding"
              "extreme"
            ];
          });

        # ── Routes ───────────────────────────────────────────────────
        # Two schemes coexist:
        #  1. OpenAI-native `/v1/*` paths (what Hermes/OpenCode call, since their
        #     base_url ends in `/v1`) — strip_path=false so the full `/v1/*` path
        #     is forwarded upstream verbatim.
        #  2. Legacy `/llm/{pool}/v1/*` pool-split paths — strip_path=true strips
        #     the `/llm/{pool}` prefix so the upstream still sees `/v1/*`.
        routes = [
          # ★ Primary — chat completions → coding router (ExtremeRouter)
          {
            name = "v1-chat";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/v1/chat/completions" ];
            methods = [ "POST" ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "coding"
            ];
          }
          # Primary — legacy completions → coding router
          {
            name = "v1-completions";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/v1/completions" ];
            methods = [ "POST" ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "llm" ];
          }
          # Primary — embeddings → coding router
          {
            name = "v1-embeddings";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/v1/embeddings" ];
            methods = [ "POST" ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "llm" ];
          }
          # Primary — model discovery → coding router (ExtremeRouter or OmniRoute)
          # OpenCode/Hermes call /v1/models to enumerate available models.
          # Polyfloor (76-orchestrators/polyfloor.nix) also enumerates this via
          # GET {routerEndpoint}/models (services.polyfloor.routerEndpoint),
          # grouping results into free|fast|reasoning|frontier for its UI.
          {
            name = "v1-models";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/v1/models" ];
            methods = [ "GET" ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "models"
            ];
          }
          # Legacy pool split — chat via FreeLLMAPI
          {
            name = "llm-chat";
            service = "freellmapi-llm";
            paths = [ "/llm/v1/chat/completions" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "llm" ];
          }
          {
            name = "llm-completions";
            service = "freellmapi-llm";
            paths = [ "/llm/v1/completions" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "llm" ];
          }
          {
            name = "llm-embeddings";
            service = "freellmapi-llm";
            paths = [ "/llm/v1/embeddings" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "llm" ];
          }
          # Frontier traffic → Manifest
          {
            name = "llm-frontier";
            service = "manifest-llm";
            paths = [ "/llm/frontier/v1/chat/completions" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "frontier"
            ];
          }
          # Coding traffic → OmniRoute or ExtremeRouter (mutually exclusive)
          {
            name = "llm-coding";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/llm/coding/v1/chat/completions" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "coding"
            ];
          }
          # Free pool → freellmpool
          {
            name = "llm-free";
            service = "freellmpool-llm";
            paths = [ "/llm/free/v1/chat/completions" ];
            methods = [ "POST" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "free"
            ];
          }
          # Legacy model discovery → coding router
          {
            name = "llm-models";
            service =
              if cfg.routers.codingRouter == "extreme-router" then "extremerouter-llm" else "omniroute-llm";
            paths = [ "/llm/v1/models" ];
            methods = [ "GET" ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "models"
            ];
          }
          # MCP gateway
          {
            name = "mcp-gateway";
            service = "freellmapi-llm";
            paths = [ "/mcp" ];
            methods = [
              "GET"
              "POST"
            ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            tags = [ "mcp" ];
          }
          # Health check
          {
            name = "health";
            paths = [ "/health" ];
            methods = [ "GET" ];
            strip_path = false;
            protocols = [
              "http"
              "https"
            ];
            plugins = [
              {
                name = "request-termination";
                config = {
                  status_code = 200;
                  content_type = "application/json";
                  body = ''{"status":"ok","gateway":"kong"}'';
                };
              }
            ];
            tags = [ "infra" ];
          }
        ];

        # ── Upstreams (for load balancing) ────────────────────────────
        upstreams =
          (optional cfg.routers.manifest.enable {
            name = "manifest-upstream";
            targets = [
              {
                target = "127.0.0.1:${toString cfg.routers.manifest.port}";
                weight = 100;
              }
            ];
            healthchecks = {
              active = {
                type = "http";
                http_path = "/api/v1/health";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          })
          ++ (optional cfg.routers.freellmapi.enable {
            name = "freellmapi-upstream";
            targets = [
              {
                target = "127.0.0.1:${toString cfg.routers.freellmapi.port}";
                weight = 100;
              }
            ];
            healthchecks = {
              active = {
                type = "http";
                http_path = "/health";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          })
          ++ (optional cfg.routers.freellmpool.enable {
            name = "freellmpool-upstream";
            targets = [
              {
                target = "127.0.0.1:${toString cfg.routers.freellmpool.port}";
                weight = 100;
              }
            ];
            healthchecks = {
              active = {
                type = "http";
                http_path = "/health";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          })
          ++ (optional (cfg.routers.codingRouter == "omniroute") {
            name = "omniroute-upstream";
            targets = [
              {
                target = "127.0.0.1:${toString cfg.routers.omniroute.port}";
                weight = 100;
              }
            ];
            healthchecks = {
              active = {
                type = "http";
                http_path = "/api/health";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          })
          ++ (optional (cfg.routers.codingRouter == "extreme-router") {
            name = "extremerouter-upstream";
            targets = [
              {
                target = "127.0.0.1:${toString cfg.routers.extreme-router.port}";
                weight = 100;
              }
            ];
            healthchecks = {
              active = {
                type = "http";
                http_path = "/api/health";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          });

        # ── Consumers (API key holders) ───────────────────────────────
        # Consumer keys are rendered by a separate sops template file and
        # merged at container start — they can't live in the Nix store.
        # See kong-consumers.yml (sops template) and the merge-init script.
        consumers = [ ];

        # ── Global plugins ────────────────────────────────────────────
        plugins = [
          # Auth — key-auth on all LLM routes
          {
            name = "key-auth";
            config = {
              key_names = [
                "apikey"
                "Authorization"
              ];
              hide_credentials = true;
            };
            tags = [ "auth" ];
          }
          # Prometheus metrics
          {
            name = "prometheus";
            config = {
              per_consumer = true;
              status_code_metrics = true;
              latency_metrics = true;
              bandwidth_metrics = true;
              upstream_health_metrics = true;
            };
            tags = [ "observability" ];
          }
          # Rate limiting
          {
            name = "rate-limiting";
            config = {
              minute = 120;
              hour = 2000;
              policy = "local";
              fault_tolerant = true;
            };
            tags = [ "rate-limit" ];
          }
          # Request size limiting
          {
            name = "request-size-limiting";
            config = {
              allowed_payload_size = 10;
              size_unit = "megabytes";
            };
            tags = [ "security" ];
          }
          # CORS for browser-based agents
          {
            name = "cors";
            config = {
              origins = [ "*" ];
              methods = [
                "GET"
                "POST"
                "OPTIONS"
              ];
              headers = [
                "Accept"
                "Authorization"
                "Content-Type"
                "apikey"
              ];
              exposed_headers = [ "X-Auth-Token" ];
              credentials = true;
              max_age = 3600;
            };
            tags = [ "cors" ];
          }
        ];
      }
    );
in
{
  options.services.ai-services.kong-gateway = {
    enable = mkEnableOption "Kong AI Gateway — unified LLM/API gateway";

    proxyPort = mkOption {
      type = types.port;
      default = 8090;
      description = "Kong proxy port (API traffic)";
    };

    proxySslPort = mkOption {
      type = types.port;
      default = 8443;
      description = "Kong proxy SSL port";
    };

    adminPort = mkOption {
      type = types.port;
      default = 8091;
      description = "Kong Admin API port";
    };

    adminSslPort = mkOption {
      type = types.port;
      default = 8445;
      description = "Kong Admin API SSL port";
    };

    managerPort = mkOption {
      type = types.port;
      default = 8093;
      description = "Kong Manager GUI port";
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/kong/kong-gateway:latest";
      description = "Kong Docker image";
    };

    # ── Upstream router endpoints ──────────────────────────────────
    routers = {
      manifest = {
        enable = mkEnableOption "Route traffic to Manifest" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 2099;
        };
      };
      freellmapi = {
        enable = mkEnableOption "Route traffic to FreeLLMAPI" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 3003;
        };
      };
      freellmpool = {
        enable = mkEnableOption "Route traffic to freellmpool" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 8083;
        };
      };

      # Coding router — mutually exclusive. Only one can be active.
      codingRouter = mkOption {
        type = types.enum [
          "omniroute"
          "extreme-router"
        ];
        default = "extreme-router";
        description = ''
          Which coding LLM router to use for /llm/coding/* traffic.
          - "omniroute": OmniRoute (231+ providers, 17 combo strategies)
          - "extreme-router": ExtremeRouter (154+ providers, RTK savings, quota tracking, 49 free providers)
          Only one can be active at a time — Kong routes accordingly.
        '';
      };

      omniroute = {
        port = mkOption {
          type = types.port;
          default = 20128;
        };
      };
      extreme-router = {
        port = mkOption {
          type = types.port;
          default = 20128;
        };
      };
    };

    # ── Consumers (clients with API keys) ──────────────────────────
    consumers = mkOption {
      type = types.listOf types.str;
      default = [
        "hermes"
        "opencode"
        "claude-code"
        "codex"
        "cursor"
        "deerflow"
        "polyfloor"
        "paperclip"
        "opencompany"
        "dsh"
      ];
      description = "List of consumer usernames. Each gets a keyauth credential.";
    };

    # ── Environment file for provider keys ──────────────────────────
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to env file with provider API keys";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/kong";
      description = "Kong data directory (logs, config)";
    };
  };

  config =
    let
      cfg = config.services.ai-services.kong-gateway;
      kongYml = mkKongYml cfg;
    in
    mkIf cfg.enable {
      # ── Data directory ────────────────────────────────────────────
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 root root -"
        "d ${cfg.dataDir}/logs 0755 root root -"
      ];

      # ── Persist data across reboots ────────────────────────────────
      environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
        directories = [ cfg.dataDir ];
      };

      # ── Kong container ────────────────────────────────────────────
      # DB-less mode with merged declarative config file:
      # ExecStartPre merges structural kongYml + sops-rendered consumers into /var/lib/kong/declarative.json
      systemd.services.podman-kong = {
        serviceConfig = {
          MemoryMax = "1G";
          MemoryHigh = "800M";
          ExecStartPre = [
            "+${pkgs.writeShellScript "kong-merge-declarative-config" ''
              set -euo pipefail
              mkdir -p ${cfg.dataDir}
              # Base structural config first; consumer keys and the ExtremeRouter
              # upstream auth header are sops-rendered fragments merged alongside.
              # deep_merge concatenates Kong's declarative array keys (services,
              # routes, upstreams, plugins, consumers) instead of overwriting them,
              # which plain jq `*` would do.
              ${pkgs.jq}/bin/jq -s '
                def deep_merge($a; $b):
                  if ($a | type) == "object" and ($b | type) == "object" then
                    reduce ($b | keys_unsorted[]) as $k (
                      $a;
                      if (.[$k] | type) == "array" and ($b[$k] | type) == "array" then
                        .[$k] = (.[$k] + $b[$k])
                      elif has($k) and (.[$k] | type) == "object" and ($b[$k] | type) == "object" then
                        .[$k] = deep_merge(.[$k]; $b[$k])
                      else
                        .[$k] = $b[$k]
                      end
                    )
                  else
                    $b
                  end;
                reduce .[] as $item ({}; deep_merge(.; $item))
              ' ${kongYml} "${config.sops.templates."kong-consumers".path}" "${
                config.sops.templates."kong-extremerouter-auth".path
              }" > ${cfg.dataDir}/declarative.json
              chmod 0644 ${cfg.dataDir}/declarative.json
            ''}"
          ];
        };
      };

      virtualisation.oci-containers.containers.kong = {
        inherit (cfg) image;
        ports = [
          "${toString cfg.proxyPort}:8000"
          "${toString cfg.proxySslPort}:8443"
          "127.0.0.1:${toString cfg.adminPort}:8001"
          "127.0.0.1:${toString cfg.adminSslPort}:8444"
          "127.0.0.1:${toString cfg.managerPort}:8002"
        ];
        environment = {
          KONG_DATABASE = "off";
          KONG_DECLARATIVE_CONFIG = "/etc/kong/declarative.json";
          KONG_PROXY_LISTEN = "0.0.0.0:${toString cfg.proxyPort}";
          KONG_PROXY_LISTEN_SSL = "0.0.0.0:${toString cfg.proxySslPort}";
          KONG_ADMIN_LISTEN = "127.0.0.1:${toString cfg.adminPort}";
          KONG_ADMIN_LISTEN_SSL = "127.0.0.1:${toString cfg.adminSslPort}";
          KONG_MANAGER_LISTEN = "127.0.0.1:${toString cfg.managerPort}";
          KONG_ADMIN_GUI_LISTEN = "127.0.0.1:${toString cfg.managerPort}";
          KONG_ADMIN_GUI_URL = "http://127.0.0.1:${toString cfg.managerPort}";
          KONG_ADMIN_API_URI = "http://127.0.0.1:${toString cfg.adminPort}";
          KONG_LOG_LEVEL = "info";
          KONG_PROXY_ACCESS_LOG = "/dev/stdout";
          KONG_ADMIN_ACCESS_LOG = "/dev/stdout";
          KONG_PROXY_ERROR_LOG = "/dev/stderr";
          KONG_ADMIN_ERROR_LOG = "/dev/stderr";
          KONG_PLUGINS = "bundled";
          KONG_NGINX_WORKER_PROCESSES = "2";
          KONG_NGINX_EVENTS_WORKER_CONNECTIONS = "1024";
          # DNS resolver for container networking
          KONG_DNS_RESOLVER = "127.0.0.11";
          KONG_DNS_HOSTS = "host.docker.internal";
        };
        volumes = [
          "${cfg.dataDir}/declarative.json:/etc/kong/declarative.json:ro"
          # Logs go to stdout/stderr — no volume mount needed
        ];
        extraOptions = [
          "--network=host"
          "--add-host=host.docker.internal:host-gateway"
          "--health-cmd=kong health"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
        environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
      };

      # ── Firewall ──────────────────────────────────────────────────
      networking.firewall.allowedTCPPorts = [
        cfg.proxyPort
        cfg.proxySslPort
      ];

      # ── CLI helpers ──────────────────────────────────────────────────
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "kong-ctl" ''
          DATA_DIR="${cfg.dataDir}"
          case "''${1:-help}" in
            status)
              podman exec kong kong status 2>/dev/null || echo "Kong container not running"
              ;;
            health)
              podman exec kong kong health 2>/dev/null || echo "Kong container not running"
              ;;
            reload)
              podman exec kong kong reload 2>/dev/null || echo "Kong container not running"
              ;;
            logs)
              podman logs -f kong
              ;;
            admin)
              shift
              curl -s "http://127.0.0.1:${toString cfg.adminPort}/$@" | ${pkgs.jq}/bin/jq .
              ;;
            *)
              echo "Usage: kong-ctl {status|health|reload|logs|admin <path>}"
              echo "  admin examples:"
              echo "    kong-ctl admin services"
              echo "    kong-ctl admin routes"
              echo "    kong-ctl admin consumers"
              echo "    kong-ctl admin plugins"
              echo "    kong-ctl admin upstreams"
              ;;
          esac
        '')
        (pkgs.writeShellApplication {
          name = "kong-admin";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
          ];
          text = ''
            ADMIN_URL="http://127.0.0.1:${toString cfg.adminPort}"
            case "''${1:-help}" in
              services|routes|consumers|plugins|upstreams|certificates|snis)
                curl -s "$ADMIN_URL/''${1}" | jq .
                ;;
              *)
                curl -s "$ADMIN_URL/$1" | jq .
                ;;
            esac
          '';
        })
      ];
    };
}
