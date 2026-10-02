# Tier: 79-skills
# Module: nix-skills.nix
# Purpose: Portable Nix, NixOS and Home Manager skills for AI coding agents.
# Option Path: layers.layer-79.skills.nix-skills
# Enabling Host Tags: ai-agent, development, workstation
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.layer-79.skills.nix-skills;
in
{
  options.layers.layer-79.skills.nix-skills = {
    enable = lib.mkEnableOption "nix-skills — portable Nix, NixOS and Home Manager skills for AI coding agents";

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Selected nix-skills to install. Empty list installs default full collection.";
    };

    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Target agents to install skills for (e.g. claude, opencode, gemini, etc.).";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.t0psh31f = {
      imports = [
        inputs.nix-skills.homeManagerModules.default
      ];
      programs.nix-skills = {
        enable = true;
        skills = lib.mkIf (cfg.skills != [ ]) cfg.skills;
        agents = lib.mkIf (cfg.agents != [ ]) cfg.agents;
      };
    };
  };
}
