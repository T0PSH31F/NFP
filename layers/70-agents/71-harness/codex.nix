# Tier: 71-harness
# Module: codex.nix
# Purpose: OpenAI Codex CLI terminal harness tool.
# Option Path: layers.layer-70.agent.codex
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
      [ "layers" "layer-70" "agent" "codex" ]
      [ "layers" "layer-71" "harness" "codex" ]
    )
  ];

  options.layers.layer-71.harness.codex = {
    enable = lib.mkEnableOption "OpenAI Codex coding agent";
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.codex;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.optional (pkgs ? codex) pkgs.codex;
    };

  home =
    let
      cfg = config.layers.layer-71.harness.codex;
    in
    lib.mkIf cfg.enable {
      xdg.configFile."deepseek/config.toml".text = ''
        [providers.openai]
        base_url = "http://127.0.0.1:20128/v1"
      '';
    };
}
