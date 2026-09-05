# Tier: 71-harness
# Module: claude-code.nix
# Purpose: Anthropic Claude Code terminal agent harness wrapper.
# Option Path: layers.layer-70.agent.claude-code
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
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
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? claude-code) pkgs.claude-code;
    };

  home =
    let
      cfg = config.layers.layer-71.harness.claude-code;
    in
    lib.mkIf cfg.enable {
      home.packages = lib.optional (
        pkgs ? vscode-extension-anthropic-claude-code
      ) pkgs.vscode-extension-anthropic-claude-code;

      xdg.configFile."claude/settings.json".text = builtins.toJSON {
        hasCompletedOnboarding = true;
        env = {
          ANTHROPIC_BASE_URL = "http://127.0.0.1:20128/v1";
        };
      };
    };
}
