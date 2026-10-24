# Sops secrets for Kong AI Gateway stack
# Maps provider API keys from the central secrets file to per-service env files.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config =
    let
      cfg = config.services.ai-services.kong-gateway;
      secretsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;

      # Helper: declare a sops secret and return its path
      mkSecret = _name: {
        sopsFile = secretsFile;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # Helper for consumer keys readable by CLI harnesses in `users` group
      mkConsumerSecret = _name: {
        sopsFile = mkDefault secretsFile;
        owner = mkDefault "root";
        group = mkDefault "users";
        mode = mkDefault "0440";
      };
    in
    mkIf cfg.enable {
      sops = {
        # ── Provider API keys ────────────────────────────────────────────
        secrets = {
          # OpenRouter (3 keys for rotation)
          openrouter_api_key_1 = mkSecret "openrouter_api_key_1";
          openrouter_api_key_2 = mkSecret "openrouter_api_key_2";
          openrouter_api_key_3 = mkSecret "openrouter_api_key_3";

          # Frontier providers
          anthropic_api_key = mkSecret "anthropic_api_key";
          gemini_api_key_lovelain = mkSecret "gemini_api_key_lovelain";
          gemini_api_key_we77 = mkSecret "gemini_api_key_we77";
          nous_api_key = mkSecret "nous_api_key";

          # Cheap/free providers
          groq_api_key = mkSecret "groq_api_key";
          cerebras_api_key = mkSecret "cerebras_api_key";
          github_models_api = mkSecret "github_models_api";
          nvidia_api_key = mkSecret "nvidia_api_key";

          # Kong consumer API keys (generated per consumer in sops, readable by users group)
          kong_key_hermes = mkConsumerSecret "kong_key_hermes";
          kong_key_hermes_voice = mkConsumerSecret "kong_key_hermes_voice";
          kong_key_voice = mkConsumerSecret "kong_key_voice";
          kong_key_pi = mkConsumerSecret "kong_key_pi";
          kong_key_opencode = mkConsumerSecret "kong_key_opencode";
          kong_key_claude_code = mkConsumerSecret "kong_key_claude_code";
          kong_key_codex = mkConsumerSecret "kong_key_codex";
          kong_key_cursor = mkConsumerSecret "kong_key_cursor";
          kong_key_deerflow = mkConsumerSecret "kong_key_deerflow";
          kong_key_polyfloor = mkConsumerSecret "kong_key_polyfloor";

          # ExtremeRouter, OmniRoute & FreeLLMAPI keys
          extremerouter_api_key = mkSecret "extremerouter_api_key";
          omniroute_api_key = mkSecret "omniroute_api_key";
          freellmapi_encryption_key = mkSecret "freellmapi_encryption_key";
        };

        # ── Templates for Kong & downstream services ────────────────────
        templates = {
          "kong-env" = {
            content = ''
              # Provider keys — injected by sops-nix at activation time
              OPENROUTER_API_KEY_1=${config.sops.placeholder.openrouter_api_key_1}
              OPENROUTER_API_KEY_2=${config.sops.placeholder.openrouter_api_key_2}
              OPENROUTER_API_KEY_3=${config.sops.placeholder.openrouter_api_key_3}
              ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
              GEMINI_API_KEY_LOVELAIN=${config.sops.placeholder.gemini_api_key_lovelain}
              GEMINI_API_KEY_WE77=${config.sops.placeholder.gemini_api_key_we77}
              NOUS_API_KEY=${config.sops.placeholder.nous_api_key}
              GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
              CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
              GITHUB_MODELS_API=${config.sops.placeholder.github_models_api}
              NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}

              # Kong consumer keys (agents authenticate with these)
              KONG_KEY_HERMES=${config.sops.placeholder.kong_key_hermes}
              KONG_KEY_HERMES_VOICE=${config.sops.placeholder.kong_key_hermes_voice}
              KONG_KEY_VOICE=${config.sops.placeholder.kong_key_voice}
              KONG_KEY_PI=${config.sops.placeholder.kong_key_pi}
              KONG_KEY_OPENCODE=${config.sops.placeholder.kong_key_opencode}
              KONG_KEY_CLAUDE_CODE=${config.sops.placeholder.kong_key_claude_code}
              KONG_KEY_CODEX=${config.sops.placeholder.kong_key_codex}
              KONG_KEY_CURSOR=${config.sops.placeholder.kong_key_cursor}
              KONG_KEY_DEERFLOW=${config.sops.placeholder.kong_key_deerflow}
              KONG_KEY_POLYFLOOR=${config.sops.placeholder.kong_key_polyfloor}
            '';
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── Kong consumers file (real API keys, sops-rendered) ─────────
          templates."kong-consumers" = {
            content = builtins.toJSON {
              _format_version = "3.0";
              consumers = map (consumer: {
                username = consumer;
                keyauth_credentials = [
                  {
                    key =
                      let
                        keyName = "kong_key_${replaceStrings [ "-" ] [ "_" ] consumer}";
                      in
                      if (hasAttr keyName config.sops.placeholder) then
                        config.sops.placeholder.${keyName}
                      else
                        "${config.sops.placeholder.kong_key_hermes}-${consumer}";
                  }
                ];
              }) cfg.consumers;
            };
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── ExtremeRouter upstream auth (request-transformer plugin) ────
          # Uses remove + replace + add so the Kong consumer key never leaks
          # or prevents the upstream router Bearer key from being injected.
          templates."kong-extremerouter-auth" = {
            content = builtins.toJSON {
              _format_version = "3.0";
              plugins = [
                {
                  name = "request-transformer";
                  service = "extremerouter-llm";
                  config = {
                    remove = {
                      headers = [
                        "apikey"
                        "x-api-key"
                      ];
                    };
                    replace = {
                      headers = [
                        "Authorization: Bearer ${config.sops.placeholder.extremerouter_api_key}"
                      ];
                    };
                    add = {
                      headers = [
                        "Authorization: Bearer ${config.sops.placeholder.extremerouter_api_key}"
                      ];
                    };
                  };
                }
              ];
            };
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── Jev Tier Router upstream auth (request-transformer plugin) ──
          templates."kong-jev-auth" = {
            content = builtins.toJSON {
              _format_version = "3.0";
              plugins = [
                {
                  name = "request-transformer";
                  service = "jev-llm";
                  config = {
                    remove = {
                      headers = [
                        "apikey"
                        "x-api-key"
                      ];
                    };
                    replace = {
                      headers = [
                        "Authorization: Bearer ${config.sops.placeholder.extremerouter_api_key}"
                      ];
                    };
                    add = {
                      headers = [
                        "Authorization: Bearer ${config.sops.placeholder.extremerouter_api_key}"
                      ];
                    };
                  };
                }
              ];
            };
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── OmniRoute upstream auth (request-transformer plugin) ─────────
          templates."kong-omniroute-auth" = {
            content = builtins.toJSON {
              _format_version = "3.0";
              plugins = [
                {
                  name = "request-transformer";
                  service = "omniroute-llm";
                  config = {
                    remove = {
                      headers = [
                        "apikey"
                        "x-api-key"
                      ];
                    };
                    replace = {
                      headers = [
                        "Authorization: Bearer ${
                          config.sops.placeholder.omniroute_api_key or config.sops.placeholder.extremerouter_api_key
                        }"
                      ];
                    };
                    add = {
                      headers = [
                        "Authorization: Bearer ${
                          config.sops.placeholder.omniroute_api_key or config.sops.placeholder.extremerouter_api_key
                        }"
                      ];
                    };
                  };
                }
              ];
            };
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── Environment file for ExtremeRouter ──────────────────────────
          templates."extremerouter-env" = {
            content = ''
              # ExtremeRouter persistent signing & API key secrets (managed by sops-nix)
              JWT_SECRET=${config.sops.placeholder.extremerouter_api_key}
              API_KEY_SECRET=${config.sops.placeholder.extremerouter_api_key}
              EXTREMEROUTER_API_KEY=${config.sops.placeholder.extremerouter_api_key}
              REQUIRE_API_KEY=true
            '';
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── Environment file for OmniRoute ─────────────────────────────
          templates."omniroute-env" = lib.mkIf config.services.ai-services.omniroute.enable {
            content = ''
              # OmniRoute provider keys and transferred ExtremeRouter secrets
              ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
              GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key_we77}
              OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key_1}
              GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
              CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
              GITHUB_MODELS_API=${config.sops.placeholder.github_models_api}
              NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
              NOUS_API_KEY=${config.sops.placeholder.nous_api_key}
              EXTREMEROUTER_API_KEY=${config.sops.placeholder.extremerouter_api_key}
              OMNIROUTE_API_KEY=${config.sops.placeholder.omniroute_api_key}
              API_KEY=${config.sops.placeholder.extremerouter_api_key}
              JWT_SECRET=${config.sops.placeholder.extremerouter_api_key}
            '';
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # ── Environment file for FreeLLMAPI ─────────────────────────────
          templates."freellmapi-env" = lib.mkIf config.services.ai-services.freellmapi.enable {
            content = ''
              # FreeLLMAPI provider keys & sops-managed encryption key
              ENCRYPTION_KEY=${config.sops.placeholder.freellmapi_encryption_key}
              OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key_1}
              GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
              CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
              GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key_we77}
              GITHUB_MODELS_API_KEY=${config.sops.placeholder.github_models_api}
              NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
            '';
            owner = "freellmapi";
            group = "freellmapi";
            mode = "0400";
          };

          # ── Environment file for freellmpool ─────────────────────────
          templates."freellmpool-env" = lib.mkIf config.services.ai-services.freellmpool.enable {
            content = ''
              # freellmpool provider keys — extend as needed
              GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
              CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
              GITHUB_TOKEN=${config.sops.placeholder.github_models_api}
              NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
              OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key_1}
            '';
            owner = "freellmpool";
            group = "freellmpool";
            mode = "0400";
          };

          # ── Environment file for LangGraph ───────────────────────────────
          templates."langgraph-env" =
            lib.mkIf (config.services.ai-services.langgraph.enable && builtins.pathExists /var/lib/langgraph)
              {
                content = ''
                  # LangGraph → Kong connection
                  OPENAI_BASE_URL=http://127.0.0.1:${toString cfg.proxyPort}/llm/v1
                  OPENAI_API_KEY=${config.sops.placeholder.kong_key_hermes}
                '';
                owner = "langgraph";
                group = "langgraph";
                mode = "0400";
              };
        };
      };
    };
}
