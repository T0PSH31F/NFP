# Tier: 71-harness
# Module: crush.nix
# Purpose: Crush CLI agent integration (Charm-style TUI coding assistant).
# Option Path: layers.layer-71.harness.crush
# Enabling Host Tags: ai-agent, development, workstation
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? config,
  ...
}:
with lib;
let
  sys = pkgs.stdenv.hostPlatform.system;
  llmPkgs = inputs.llm-agents.packages.${sys} or { };
  crushPkg = llmPkgs.crush or pkgs.crush or null;
in
{
  options.layers.layer-71.harness.crush = {
    enable = mkEnableOption "Crush CLI coding assistant harness";

    package = mkOption {
      type = types.nullOr types.package;
      default = crushPkg;
      description = "Crush package derivation";
    };
  };

  home =
    let
      cfg = config.layers.layer-71.harness.crush;
    in
    lib.mkIf cfg.enable {
      home.packages = lib.optional (cfg.package != null) cfg.package;

      xdg.configFile."crush/config.json".text = builtins.toJSON {
        options = {
          model = "claude-sonnet-4";
        };
      };
    };
}
