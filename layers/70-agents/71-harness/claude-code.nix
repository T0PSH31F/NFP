# Tier: 71-harness
# Module: claude-code.nix
# Purpose: Anthropic Claude Code terminal agent harness wrapper.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://sanji.nfp.nix:8090/v1 (ExtremeRouter via Kong)
#   kong-omni:     http://sanji.nfp.nix:8090/omni/v1 (OmniRoute via Kong)
#   kong-free:     http://sanji.nfp.nix:8090/llm/free/v1 (FreeLLMPool via Kong)
#   kong-frontier: http://sanji.nfp.nix:8090/llm/frontier/v1 (Manifest via Kong)
#   extreme-direct: http://z0r0.nfp.nix:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.claude-code
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "claude-code" ]
      [ "layers" "layer-71" "harness" "claude-code" ]
    )
  ];

  options.layers.layer-71.harness.claude-code = {
    enable = lib.mkEnableOption "Anthropic Claude Code agentic coding tool";
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.claude-code;
      routerBase = "http://127.0.0.1:20128";
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      claudePkg = llmPkgs.claude-code or pkgs.claude-code or null;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (claudePkg != null) claudePkg;
      environment.sessionVariables = {
        ANTHROPIC_BASE_URL = lib.mkDefault "${routerBase}/v1";
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        ANTHROPIC_BASE_URL_EXTREME_DIRECT = "http://z0r0.nfp.nix:20128/v1";
      };
    };

  home =
    { osConfig, ... }:
    let
      cfg = osConfig.layers.layer-71.harness.claude-code;
      routerBase = "http://127.0.0.1:20128";
      claudeSettings = builtins.toJSON {
        hasCompletedOnboarding = true;
        apiKeyHelper = "cat /run/secrets/extremerouter_api_key 2>/dev/null || printf '%s' \"$ANTHROPIC_AUTH_TOKEN\"";
        env = {
          ANTHROPIC_BASE_URL = "${routerBase}/v1";
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        };
      };
      claudeInstructions = ''
        # NFP Claude Code — Mandatory Operating & Voice Notification Directives

        1. **Mandatory Voice Notifications (ALWAYS ACTIVE)**:
           - For every task completion, milestone update, or alert, trigger a concise 1-2 sentence GLaDOS voice notification in the background:
             `/home/t0psh31f/.local/bin/glados-tts-cli "<concise update in GLaDOS voice>" >/dev/null 2>&1 &`
        2. **Multi-Agent Communication & Shared Todo (`~/Notes/EverOS/todo.md`)**:
           - Read the shared multi-agent todo board via `nfp-todo list` (or MCP tool `todo_list`).
           - Update only your fenced section (`## Claude`) via `nfp-todo --agent claude add|toggle` and claim `@claude` tasks from `## Erik` via `nfp-todo --agent claude claim`.
           - Delegate durable background tasks to Pi (`127.0.0.1:8089/v1/delegate` or `@pi` tag) or Hermes (`127.0.0.1:8085`).
      '';
    in
    lib.mkIf cfg.enable {
      home = {
        packages = lib.optional (
          pkgs ? vscode-extension-anthropic-claude-code
        ) pkgs.vscode-extension-anthropic-claude-code;

        file = {
          ".claude/settings.json".text = claudeSettings;
          ".claude/CLAUDE.md".text = claudeInstructions;
        };
      };

      xdg.configFile = {
        "claude/settings.json".text = claudeSettings;
        "claude/CLAUDE.md".text = claudeInstructions;
      };
    };
}
