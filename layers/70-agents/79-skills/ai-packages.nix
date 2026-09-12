# Tier: 79-skills
# Module: ai-packages.nix
# Purpose: System-wide package collection for AI CLI utilities, PyTorch/Python helpers, and tool binaries.
# Option Path: layers.layer-79.skills.ai-packages
# Enabling Host Tags: ai-agent, development, workstation
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
in
{
  options.layers.layer-79.skills.ai-packages = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable unified AI system packages catalog";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra custom AI packages to add to system environment";
    };

    enableCodingAgents = mkOption {
      type = types.bool;
      default = true;
      description = "Enable CLI coding agents (claude-code, opencode, goose-cli, jules, pi, ccusage)";
    };

    enableServerTools = mkOption {
      type = types.bool;
      default = false;
      description = "Enable AI server tools (ollama, espeak-ng, pipx)";
    };
  };

  options.services.llm-agents = {
    enable = mkEnableOption "Agentic AI-related services (legacy compatibility alias)";
  };

  config =
    let
      cfg = config.layers.layer-79.skills.ai-packages;
      legacyAiServicesCfg = config.services.ai-services;
      legacyLlmAgentsCfg = config.services.llm-agents;
    in
    mkMerge [
      (mkIf (cfg.enable || legacyAiServicesCfg.enable or false || legacyLlmAgentsCfg.enable or false) {
        environment.systemPackages =
          with pkgs;
          [
            fabric-ai
            go-hass-agent
            ramalama
            # bluemail
            librechat
            nextjs-ollama-llm-ui
            skills
            beads
            openshell
            gemini-cli
            # jan
            cherry-studio
            lmstudio
            python314Packages.pydantic-graph
          ]
          ++ cfg.packages
          ++ optionals cfg.enableCodingAgents (
            filter (p: p != null) [
              (pkgs.agentsploit or null)
              (llmPkgs.claude-code or pkgs.claude-code or null)
              (llmPkgs.goose-cli or null)
              (llmPkgs.opencode or pkgs.opencode or null)
              (llmPkgs.pi or null)
              (llmPkgs.ccusage or null)
              (llmPkgs.beads or null)
            ]
          )
          ++ optionals cfg.enableServerTools [
            ollama
            espeak-ng
            pipx
          ];

        environment.persistence."/persist" =
          mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              users.t0psh31f = {
                directories = [
                  ".config/cherry-studio"
                  ".config/lmstudio"
                ];
              };
            };

        networking.firewall.allowedTCPPorts = [ 3004 ];
      })
      {
        services.hyprwhspr-rs.enable = mkDefault true;
      }
    ];
}
