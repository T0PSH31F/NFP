# Provider and Router Secrets for NFP LLM Stack
# Maps provider API keys from the central secrets file to per-service env files.
{
  config,
  lib,
  ...
}:
with lib;
let
  secretsFile = ../../00-cyberia/03-treasure/secrets/external_services.yaml;

  # Helper: declare a sops secret and return its path
  mkSecret = _name: {
    sopsFile = secretsFile;
    owner = "root";
    group = "root";
    mode = "0400";
  };
in
{
  config =
    mkIf
      (
        config.services.ai-services.omniroute.enable
        || config.services.ai-services.freellmapi.enable
        || config.services.ai-services.freellmpool.enable
      )
      {
        sops = {
          # ── Provider API keys ────────────────────────────────────────────
          secrets = {
            # OpenRouter
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

            # ExtremeRouter & OmniRoute keys
            extremerouter_api_key = mkSecret "extremerouter_api_key";
            omniroute_api_key = mkSecret "omniroute_api_key";
            freellmapi_encryption_key = mkSecret "freellmapi_encryption_key";
          };

          # ── Templates for downstream services ────────────────────
          templates = {
            # ── Environment file for OmniRoute ─────────────────────────────
            "omniroute-env" = lib.mkIf config.services.ai-services.omniroute.enable {
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
            "freellmapi-env" = lib.mkIf config.services.ai-services.freellmapi.enable {
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
            "freellmpool-env" = lib.mkIf config.services.ai-services.freellmpool.enable {
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
          };
        };
      };
}
