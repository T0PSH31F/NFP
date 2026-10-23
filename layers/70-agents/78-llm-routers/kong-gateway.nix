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
          # Jev Tier Router — streaming decision-only pre-flight router
          (optional cfg.routers.jev.enable {
            name = "jev-llm";
            url = "http://${cfg.routers.jev.host}:${toString cfg.routers.jev.port}";
            read_timeout = 180000;
            write_timeout = 180000;
            connect_timeout = 5000;
            tags = [
              "llm"
              "jev"
            ];
          })
          # Manifest — frontier model routing
          ++ (optional cfg.routers.manifest.enable {
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
          # OmniRoute LLM router
          ++ (optional cfg.routers.omniroute.enable {
            name = "omniroute-llm";
            url = "http://${cfg.routers.omniroute.host}:${toString cfg.routers.omniroute.port}";
            tags = [
              "llm"
              "coding"
              "omni"
            ];
          })
          # ExtremeRouter LLM router
          ++ (optional cfg.routers.extreme-router.enable {
            name = "extremerouter-llm";
            url = "http://${cfg.routers.extreme-router.host}:${toString cfg.routers.extreme-router.port}";
            read_timeout = 180000;
            write_timeout = 180000;
            connect_timeout = 10000;
            tags = [
              "llm"
              "coding"
              "extreme"
            ];
          });

        # ── Routes ───────────────────────────────────────────────────
        # Two schemes coexist:
        #  1. OpenAI/Anthropic-native `/v1/*` paths — strip_path=false so the full
        #     `/v1/*` path is forwarded upstream verbatim.
        #  2. Explicit `/er/*`, `/omni/*`, `/jev/*`, and `/llm/{pool}/v1/*` paths —
        #     strip_path=true strips the prefix so the upstream still sees `/v1/*`.
        routes =
          let
            chatService = if cfg.routers.jev.enable then "jev-llm" else "extremerouter-llm";
          in
          [
            # ★ Primary — chat completions → Jev Tier Router (if enabled) or ExtremeRouter
            {
              name = "v1-chat";
              service = chatService;
              paths = [ "/v1/chat/completions" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
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
            # Primary — legacy completions → ExtremeRouter
            {
              name = "v1-completions";
              service = chatService;
              paths = [ "/v1/completions" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [ "llm" ];
            }
            # Primary — Anthropic Messages API → Jev Tier Router or ExtremeRouter
            {
              name = "v1-messages";
              service = chatService;
              paths = [ "/v1/messages" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "anthropic"
              ];
            }
            # Primary — Anthropic token counting → ExtremeRouter
            {
              name = "v1-messages-count-tokens";
              service = "extremerouter-llm";
              paths = [ "/v1/messages/count_tokens" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "anthropic"
              ];
            }
            # Primary — OpenAI Responses API (Codex CLI) → Jev Tier Router or ExtremeRouter
            {
              name = "v1-responses";
              service = chatService;
              paths = [ "/v1/responses" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "responses"
              ];
            }
            # Primary — OpenAI Audio Speech (TTS) → ExtremeRouter
            {
              name = "v1-audio-speech";
              service = "extremerouter-llm";
              paths = [ "/v1/audio/speech" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "audio"
              ];
            }
            # Primary — OpenAI Audio Transcriptions (STT) → ExtremeRouter
            {
              name = "v1-audio-transcriptions";
              service = "extremerouter-llm";
              paths = [ "/v1/audio/transcriptions" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "audio"
              ];
            }
            # Primary — OpenAI Images Generations → ExtremeRouter
            {
              name = "v1-images-generations";
              service = "extremerouter-llm";
              paths = [ "/v1/images/generations" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "images"
              ];
            }
            # Primary — embeddings → ExtremeRouter
            {
              name = "v1-embeddings";
              service = "extremerouter-llm";
              paths = [ "/v1/embeddings" ];
              methods = [
                "POST"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [ "llm" ];
            }
            # Primary — model discovery → ExtremeRouter
            {
              name = "v1-models";
              service = "extremerouter-llm";
              paths = [ "/v1/models" ];
              methods = [
                "GET"
                "OPTIONS"
              ];
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
            # Primary — v1 root -> ExtremeRouter
            {
              name = "v1-root";
              service = "extremerouter-llm";
              paths = [ "/v1" ];
              methods = [
                "GET"
                "OPTIONS"
              ];
              strip_path = false;
              protocols = [
                "http"
                "https"
              ];
              tags = [ "llm" ];
            }
            # Explicit ExtremeRouter route (/er/v1/* -> extremerouter-llm)
            {
              name = "er-v1";
              service = "extremerouter-llm";
              paths = [ "/er" ];
              methods = [
                "GET"
                "POST"
                "OPTIONS"
              ];
              strip_path = true;
              protocols = [
                "http"
                "https"
              ];
              tags = [
                "llm"
                "extreme"
              ];
            }
            # Explicit Jev Tier Router route (/jev/v1/* -> jev-llm)
          ]
          ++ (optional cfg.routers.jev.enable {
            name = "jev-v1";
            service = "jev-llm";
            paths = [ "/jev" ];
            methods = [
              "GET"
              "POST"
              "OPTIONS"
            ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "jev"
            ];
          })
          ++ (optional cfg.routers.omniroute.enable {
            # Explicit OmniRoute route (/omni/v1/* -> omniroute-llm)
            name = "omni-v1";
            service = "omniroute-llm";
            paths = [ "/omni" ];
            methods = [
              "GET"
              "POST"
              "OPTIONS"
            ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "omni"
            ];
          })
          ++ [
            # Legacy pool split — chat via FreeLLMAPI
            {
              name = "llm-chat";
              service = "freellmapi-llm";
              paths = [ "/llm" ];
              methods = [
                "GET"
                "POST"
                "OPTIONS"
              ];
              strip_path = true;
              protocols = [
                "http"
                "https"
              ];
              tags = [ "llm" ];
            }
          ]
          ++ (optional cfg.routers.manifest.enable {
            # Frontier traffic → Manifest
            name = "llm-frontier";
            service = "manifest-llm";
            paths = [ "/llm/frontier" ];
            methods = [
              "GET"
              "POST"
              "OPTIONS"
            ];
            strip_path = true;
            protocols = [
              "http"
              "https"
            ];
            tags = [
              "llm"
              "frontier"
            ];
          })
          ++ [
            # Coding traffic → ExtremeRouter
            {
              name = "llm-coding";
              service = "extremerouter-llm";
              paths = [ "/llm/coding" ];
              methods = [
                "GET"
                "POST"
                "OPTIONS"
              ];
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
              paths = [ "/llm/free" ];
              methods = [
                "GET"
                "POST"
                "OPTIONS"
              ];
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
            # Legacy model discovery → ExtremeRouter
            {
              name = "llm-models";
              service = "extremerouter-llm";
              paths = [ "/llm/v1/models" ];
              methods = [
                "GET"
                "OPTIONS"
              ];
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
                "OPTIONS"
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
                  name = "key-auth";
                  enabled = false;
                }
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
          (optional cfg.routers.jev.enable {
            name = "jev-upstream";
            targets = [
              {
                target = "${cfg.routers.jev.host}:${toString cfg.routers.jev.port}";
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
          ++ (optional cfg.routers.manifest.enable {
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
                http_path = "/api/ping";
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
                http_path = "/v1/models";
                healthy = {
                  interval = 10;
                };
                unhealthy = {
                  interval = 5;
                };
              };
            };
          })
          ++ (optional cfg.routers.omniroute.enable {
            name = "omniroute-upstream";
            targets = [
              {
                target = "${cfg.routers.omniroute.host}:${toString cfg.routers.omniroute.port}";
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
          ++ (optional cfg.routers.extreme-router.enable {
            name = "extremerouter-upstream";
            targets = [
              {
                target = "${cfg.routers.extreme-router.host}:${toString cfg.routers.extreme-router.port}";
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
          # Pre-function (access phase, runs before key-auth):
          # Normalizes `Authorization: Bearer <token>` and `x-api-key: <token>`
          # into `apikey: <token>` and clears the original header so key-auth
          # validates OpenAI and Anthropic SDK clients and never leaks consumer
          # tokens upstream.
          {
            name = "pre-function";
            config = {
              access = [
                ''
                  local uri = ngx.var.uri
                  if uri and string.sub(uri, 1, 7) == "/v1/v1/" then
                    ngx.req.set_uri("/v1/" .. string.sub(uri, 8), false)
                  end
                  local auth = kong.request.get_header("Authorization")
                  if auth then
                    local m = string.match(auth, "^[Bb]earer%s+(.+)$")
                    if m then
                      kong.service.request.set_header("apikey", m)
                      kong.service.request.clear_header("Authorization")
                    end
                  end
                  local xkey = kong.request.get_header("x-api-key")
                  if xkey and xkey ~= "" then
                    if not kong.request.get_header("apikey") then
                      kong.service.request.set_header("apikey", xkey)
                    end
                    kong.service.request.clear_header("x-api-key")
                  end
                ''
              ];
            };
            tags = [ "auth-normalize" ];
          }
          # Auth — key-auth on all LLM routes
          {
            name = "key-auth";
            config = {
              key_names = [
                "apikey"
                "x-api-key"
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
          # Rate limiting — per consumer (not global)
          {
            name = "rate-limiting";
            config = {
              minute = 120;
              hour = 2000;
              limit_by = "consumer";
              policy = "local";
              fault_tolerant = true;
            };
            tags = [ "rate-limit" ];
          }
          # Dedicated rate limit for low-latency voice consumers
          {
            name = "rate-limiting";
            consumer = "voice";
            config = {
              minute = 300;
              hour = 6000;
              limit_by = "consumer";
              policy = "local";
              fault_tolerant = true;
            };
            tags = [
              "rate-limit"
              "voice"
            ];
          }
          {
            name = "rate-limiting";
            consumer = "hermes-voice";
            config = {
              minute = 300;
              hour = 6000;
              limit_by = "consumer";
              policy = "local";
              fault_tolerant = true;
            };
            tags = [
              "rate-limit"
              "voice"
            ];
          }
          # Request size limiting
          {
            name = "request-size-limiting";
            config = {
              allowed_payload_size = 25;
              size_unit = "megabytes";
            };
            tags = [ "security" ];
          }
          # CORS for trusted browser-based agents
          {
            name = "cors";
            config = {
              origins = cfg.corsOrigins;
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
                "x-api-key"
                "anthropic-version"
                "anthropic-beta"
                "OpenAI-Beta"
              ];
              exposed_headers = [
                "X-Auth-Token"
                "X-Jev-Decision"
                "X-Jev-Routed-Tier"
              ];
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
      default = "docker.io/library/kong:3.9.1";
      description = "Pinned Kong OSS Docker image tag";
    };

    corsOrigins = mkOption {
      type = types.listOf types.str;
      default = [
        "http://localhost"
        "http://127.0.0.1"
        "http://*.nfp.nix"
        "https://*.nfp.nix"
        "https://*.lovelain.duckdns.org"
      ];
      description = "Allowed CORS origins for browser-based agent UIs";
    };

    # ── Upstream router endpoints ──────────────────────────────────
    routers = {
      jev = {
        enable = mkEnableOption "Route chat/messages/responses through Jev Tier Router before ExtremeRouter";
        host = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Jev Tier Router host";
        };
        port = mkOption {
          type = types.port;
          default = 20127;
          description = "Jev Tier Router port";
        };
      };
      manifest = {
        enable = mkEnableOption "Route traffic to Manifest" // {
          default = false;
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
          default = 3001;
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

      omniroute = {
        enable = mkEnableOption "Route traffic to OmniRoute" // {
          default = false;
        };
        host = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "OmniRoute host IP or hostname";
        };
        port = mkOption {
          type = types.port;
          default = 20129;
          description = "OmniRoute port (default 20129)";
        };
      };

      extreme-router = {
        enable = mkEnableOption "Route traffic to ExtremeRouter" // {
          default = true;
        };
        host = mkOption {
          type = types.str;
          default = "100.64.0.1";
          description = "ExtremeRouter host Tailnet IP or FQDN";
        };
        port = mkOption {
          type = types.port;
          default = 20128;
          description = "ExtremeRouter port";
        };
      };
    };

    # ── Consumers (clients with API keys) ──────────────────────────
    consumers = mkOption {
      type = types.listOf types.str;
      default = [
        "hermes"
        "hermes-voice"
        "voice"
        "pi"
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
    mkMerge [
      {
        nfp.services.kong-gateway = {
          enable = config.services.ai-services.kong-gateway.enable;
          host = config.networking.hostName;
          port = 8090;
          homepage = {
            enable = true;
            category = "luffy";
            order = 40;
            title = "Kong Gateway";
            subtitle = "Unified LLM Multiplexer";
            icon = "kong";
            metric = {
              mode = "health-only";
            };
          };
          healthcheck = {
            enable = true;
            path = "/health";
            expectedStatus = [ 200 ];
          };
        };
      }
      (mkIf cfg.enable {
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
                FILES=("${kongYml}")
                for f in "${config.sops.templates."kong-consumers".path}" "${
                  config.sops.templates."kong-extremerouter-auth".path
                }" ${optionalString cfg.routers.omniroute.enable ''"${config.sops.templates."kong-omniroute-auth".path}"''} ${optionalString cfg.routers.jev.enable ''"${config.sops.templates."kong-jev-auth".path}"''}; do
                  if [ -n "$f" ] && [ -f "$f" ]; then
                    FILES+=("$f")
                  fi
                done
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
                ' "''${FILES[@]}" > ${cfg.dataDir}/declarative.json
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
            # DNS resolver for host networking (systemd-resolved + tailnet)
            KONG_DNS_RESOLVER = "127.0.0.53,100.100.100.100,1.1.1.1";
            KONG_DNS_HOSTS = "host.docker.internal,z0r0.nfp.nix,sanji.nfp.nix,luffy.nfp.nix";
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
      })
    ];
}
