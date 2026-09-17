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
    in
    mkIf cfg.enable {
      # ── Provider API keys ────────────────────────────────────────────
      sops.secrets = {
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

        # Kong consumer API keys (generated per consumer in sops)
        kong_key_hermes = mkSecret "kong_key_hermes";
        kong_key_opencode = mkSecret "kong_key_opencode";
        kong_key_claude_code = mkSecret "kong_key_claude_code";
        kong_key_codex = mkSecret "kong_key_codex";
        kong_key_cursor = mkSecret "kong_key_cursor";
        kong_key_deerflow = mkSecret "kong_key_deerflow";
        kong_key_polyfloor = mkSecret "kong_key_polyfloor";

        # ExtremeRouter & OmniRoute remote API keys
        extremerouter_api_key = mkSecret "extremerouter_api_key";
        omniroute_api_key = mkSecret "omniroute_api_key";
      };

      # ── Environment file template for Kong ──────────────────────────
      sops.templates."kong-env" = {
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
      sops.templates."kong-consumers" = {
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
                    "nfp-${consumer}-key-placeholder";
              }
            ];
          }) cfg.consumers;
        };
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # ── ExtremeRouter upstream auth (request-transformer plugin) ────
      sops.templates."kong-extremerouter-auth" = {
        content = builtins.toJSON {
          _format_version = "3.0";
          plugins = [
            {
              name = "request-transformer";
              service = "extremerouter-llm";
              config = {
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
      sops.templates."kong-omniroute-auth" = {
        content = builtins.toJSON {
          _format_version = "3.0";
          plugins = [
            {
              name = "request-transformer";
              service = "omniroute-llm";
              config = {
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

      # ── Environment file for FreeLLMAPI ─────────────────────────────
      sops.templates."freellmapi-env" = lib.mkIf config.services.ai-services.freellmapi.enable {
        content = ''
          # FreeLLMAPI provider keys
          OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key_1}
          GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
          CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
          GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key_lovelain}
          GITHUB_MODELS_API_KEY=${config.sops.placeholder.github_models_api}
          NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
        '';
        owner = "freellmapi";
        group = "freellmapi";
        mode = "0400";
      };

      # ── Environment file for freellmpool ─────────────────────────
      sops.templates."freellmpool-env" = lib.mkIf config.services.ai-services.freellmpool.enable {
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
      sops.templates."langgraph-env" =
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
}
