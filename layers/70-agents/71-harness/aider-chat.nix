# Tier: 71-harness
# Module: aider-chat.nix
# Purpose: Aider AI pair programming terminal harness wrapper with NFP router & auto-commit options.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://nami:8090/v1 (ExtremeRouter)
#   kong-omni:     http://nami:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://nami:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://nami:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Note: Single-endpoint harness; endpoint switchable via routerEndpoint or OPENAI_API_BASE env aliases.
# Option Path: programs.aider-chat (and layers.layer-71.harness.aider-chat)
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:

with lib;

let
  cfg = config.layers.layer-71.harness.aider-chat;
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
in
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "aider-chat" ] [ "layers" "layer-71" "harness" "aider-chat" ])
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "aider-chat" ]
      [ "layers" "layer-71" "harness" "aider-chat" ]
    )
  ];

  options.layers.layer-71.harness.aider-chat = {
    enable = mkEnableOption "Aider AI pair programming terminal tool";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.aider-chat or null;
      description = "Package to use for Aider chat tool";
    };

    defaultModel = mkOption {
      type = types.str;
      default = "openai/mimo-v2.5-pro";
      description = "Default model specifier for Aider";
    };

    routerEndpoint = mkOption {
      type = types.str;
      default = "http://nami:8090/v1";
      description = "NFP LLM router OpenAI-compatible gateway endpoint (default: kong-er at http://nami:8090/v1)";
    };

    autoCommits = mkOption {
      type = types.bool;
      default = true;
      description = "Auto-commit git changes with conventional commit messages";
    };

    architect = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Architect mode (duo reasoning/editor model strategy)";
    };

    darkTheme = mkOption {
      type = types.bool;
      default = true;
      description = "Use dark terminal color theme";
    };

    lintCmd = mkOption {
      type = types.nullOr types.str;
      default = "nix fmt";
      description = "Lint / auto-formatting command executed after AI edits";
    };

    gui = mkOption {
      type = types.bool;
      default = false;
      description = "Launch browser-based GUI interface for Aider";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = optional (cfg.package != null) cfg.package;

    environment.sessionVariables = {
      OPENAI_API_BASE = cfg.routerEndpoint;
      OPENAI_BASE_URL_KONG_ER = "http://nami:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = "http://nami:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = "http://nami:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = "http://nami:8090/llm/frontier/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
      AIDER_MODEL = cfg.defaultModel;
    };

    home-manager.users.${user} = { pkgs, ... }: {
      config = {
        xdg.configFile."aider/aider.conf.yml".text = ''
          model: ${cfg.defaultModel}
          openai-api-base: ${cfg.routerEndpoint}
          auto-commits: ${if cfg.autoCommits then "true" else "false"}
          architect: ${if cfg.architect then "true" else "false"}
          dark-mode: ${if cfg.darkTheme then "true" else "false"}
          ${optionalString (cfg.lintCmd != null) "auto-lint: true\nlint-cmd: ${cfg.lintCmd}"}
          gui: ${if cfg.gui then "true" else "false"}
        '';
      };
    };
  };
}
