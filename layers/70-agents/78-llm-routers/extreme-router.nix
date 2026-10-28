# Tier: 78-llm-routers
# Module: extreme-router.nix
# Purpose: ExtremeRouter OCI container proxy — 154+ LLM providers with web UI & /v1/* API.
# Polyfloor (76-orchestrators) can point services.polyfloor.routerEndpoint here
# (http://127.0.0.1:<port>/v1) and enumerate models via GET /v1/models.
# Option Path: layers.layer-78.llm-routers.extreme-router
# Enabling Host Tags: ai-router, ai-agent, workstation
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "extreme-router" "enable" ]
      [ "layers" "layer-78" "llm-routers" "extreme-router" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "extreme-router" "port" ]
      [ "layers" "layer-78" "llm-routers" "extreme-router" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "extreme-router" "enable" ]
      [ "layers" "layer-78" "llm-routers" "extreme-router" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "extreme-router" "port" ]
      [ "layers" "layer-78" "llm-routers" "extreme-router" "port" ]
    )
  ];

  options.layers.layer-78.llm-routers.extreme-router = {
    enable = mkEnableOption "ExtremeRouter — AI gateway with 154+ providers and RTK token savings";

    port = mkOption {
      type = types.port;
      default = 20128;
      description = "ExtremeRouter web UI and API port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/extreme-router";
      description = "Persistent data directory for ExtremeRouter";
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/rsalmn/extremerouter@sha256:b710a8164939b64aebbbc3bff863a361e10367dd7b556f5159e0d81fe6b2fb3f";
      description = "Docker image for ExtremeRouter";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file for ExtremeRouter secrets (JWT_SECRET, API_KEY_SECRET, etc.)";
    };

    requireApiKey = mkOption {
      type = types.bool;
      default = true;
      description = "Require API key authentication on all /v1/* and /api/* requests";
    };

    tosAvoidProviders = mkOption {
      type = types.listOf types.str;
      default = [
        "felo-web"
        "freebuff-web"
        "perplexity-web"
        "puter"
        "v0-vercel-web"
        "veoaifree-web"
      ];
      description = "Web-cookie / ToS-risky providers flagged as tos:avoid (excluded from sensitive prompts)";
    };

    enableRtk = mkOption {
      type = types.bool;
      default = true;
      description = "Enable RTK token saving optimization";
    };

    enableHeadroom = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Headroom context token compression";
    };

    trustedProviders = mkOption {
      type = types.listOf types.str;
      default = [
        "ollama"
        "anthropic"
        "openrouter"
        "gemini"
        "groq"
        "mistral"
        "nvidia"
        "xiaomi-tokenplan"
      ];
      description = "Trusted API/local providers eligible for sensitive prompts";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables for ExtremeRouter";
    };
  };

  config =
    let
      cfg = config.layers.layer-78.llm-routers.extreme-router;
      secretsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;
      effectiveEnvFile =
        if cfg.environmentFile != null then
          cfg.environmentFile
        else
          config.sops.templates."extremerouter-secrets-env".path;
    in
    mkMerge [
      {
        nfp.services.extreme-router = {
          enable = config.layers.layer-78.llm-routers.extreme-router.enable;
          host = "z0r0";
          port = 20128;
          homepage = {
            enable = true;
            category = "luffy";
            order = 20;
            title = "ExtremeRouter";
            subtitle = "154-Provider AI Gateway";
            icon = "extreme-router";
            metric = {
              mode = "health-only";
            };
          };
          healthcheck = {
            enable = true;
            path = "/api/health";
            expectedStatus = 200;
          };
        };
      }
      (mkIf cfg.enable {
        assertions = [
          {
            assertion =
              !(config.fileSystems."/" ? fsType && config.fileSystems."/".fsType == "tmpfs")
              || (config.layers.layer-10.system.config.impermanence.enable or false);
            message = "services.ai-services.extreme-router requires impermanence to be enabled (config.layers.layer-10.system.config.impermanence.enable = true) on machines with tmpfs root to prevent API key loss on reboot.";
          }
        ];

        # Sops secret & environment template for persistent JWT_SECRET and API_KEY_SECRET
        sops.secrets.extremerouter_api_key = {
          sopsFile = secretsFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        sops.templates."extremerouter-secrets-env" = {
          content = ''
            JWT_SECRET=${config.sops.placeholder.extremerouter_api_key}
            API_KEY_SECRET=${config.sops.placeholder.extremerouter_api_key}
            EXTREMEROUTER_API_KEY=${config.sops.placeholder.extremerouter_api_key}
            REQUIRE_API_KEY=${boolToString cfg.requireApiKey}
          '';
          owner = "root";
          group = "root";
          mode = "0400";
        };

        # Create data directory with restricted permissions (0750, UID 1000) instead of 0777
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 1000 1000 -"
        ];

        # Declarative provider policy metadata & ExtremeRouter cascade combo definition
        environment.etc = {
          "extreme-router/provider-policy.json".text = builtins.toJSON {
            inherit (cfg) requireApiKey;
            inherit (cfg) tosAvoidProviders;
            inherit (cfg) trustedProviders;
            labels = builtins.listToAttrs (
              map (p: {
                name = p;
                value = [
                  "web-cookie"
                  "tos:avoid"
                ];
              }) cfg.tosAvoidProviders
            );
          };

          "extreme-router/combos.json".text = builtins.toJSON {
            "cascade/agent" = {
              kind = "cascade";
              tiers = {
                "0" = [ "ollama/qwen3.5:9b" ];
                "1" = [
                  "opencode/deepseek-v4"
                  "google/gemini-2.5-flash"
                  "openrouter/free"
                ];
                "2" = [
                  "hermes/claude-sonnet-4.5"
                  "google/gemini-2.5-pro"
                ];
              };
              models = [
                "ollama/qwen3.5:9b"
                "opencode/deepseek-v4"
                "google/gemini-2.5-flash"
                "openrouter/free"
                "hermes/claude-sonnet-4.5"
                "google/gemini-2.5-pro"
              ];
            };
          };
        };

        # OCI container via podman (non-root UID 1000:1000)
        virtualisation.oci-containers.containers.extreme-router = {
          inherit (cfg) image;
          ports = [
            "${toString cfg.port}:20128"
          ];
          environment = {
            NODE_ENV = "production";
            PORT = "20128";
            HOSTNAME = "0.0.0.0";
            DATA_DIR = "/app/data";
            NEXT_PUBLIC_BASE_URL = "http://localhost:${toString cfg.port}";
            REQUIRE_API_KEY = boolToString cfg.requireApiKey;
            TOS_AVOID_PROVIDERS = concatStringsSep "," cfg.tosAvoidProviders;
            ENABLE_RTK = boolToString cfg.enableRtk;
            ENABLE_HEADROOM = boolToString cfg.enableHeadroom;
            CASCADE_AGENT_MODELS = "ollama/qwen3.5:9b,opencode/deepseek-v4,google/gemini-2.5-flash,openrouter/free,hermes/claude-sonnet-4.5,google/gemini-2.5-pro";
          }
          // cfg.extraEnvironment;
          volumes = [
            "${cfg.dataDir}:/app/data"
          ];
          environmentFiles = [ effectiveEnvFile ];
          extraOptions = [
            "--health-cmd=node -e \"fetch('http://127.0.0.1:20128/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))\""
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-start-period=60s"
            "--health-retries=3"
            "--memory=1g"
            "--pids-limit=512"
            "--security-opt=no-new-privileges:true"
          ];
          autoStart = true;
        };

        # Firewall: open port on tailscale0 interface ONLY (loopback is allowed by default)
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ cfg.port ];

        # MITM proxy root CA certificate trust
        security.pki.certificateFiles = lib.optional (builtins.pathExists "${cfg.dataDir}/ca.crt") "${cfg.dataDir}/ca.crt";

        # Impermanence persistence support
        environment.persistence."/persist" =
          mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              directories = [
                {
                  directory = cfg.dataDir;
                  user = "1000";
                  group = "1000";
                  mode = "0750";
                }
              ];
            };
      })
    ];
}
