# Tier: 71-harness
# Module: dsh.nix
# Purpose: Dendritic Shell (DSH) AI terminal shell environment integration.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://nami:8090/v1 (ExtremeRouter)
#   kong-omni:     http://nami:8090/omni/v1 (OmniRoute - TODO: when merged)
#   kong-free:     http://nami:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://nami:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-71.harness.dsh
# Enabling Host Tags: ai-agent, desktop, workstation
# RAM Footprint: light (<300MB)
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
  cfg = osConfig.layers.layer-71.harness.dsh or osConfig.layers.layer-70.agent.dsh or { };
  primaryUser = osConfig.layers.meta.primaryUser or "t0psh31f";
  sys = pkgs.stdenv.hostPlatform.system;
  llmPkgs = inputs.llm-agents.packages.${sys} or { };

  # Package choice: We prefer llmPkgs.dsh, falling back to dsh-nix's package or pkgs.dsh
  dshPackage = llmPkgs.dsh or inputs.dsh-nix.packages.${sys}.dsh or pkgs.dsh or null;

  profileSubmodule = types.submodule {
    options = {
      plugins = mkOption {
        type = types.listOf types.anything;
        default = [ ];
        description = "List of plugin packages or strings for this dsh profile";
      };
    };
  };
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "layers" "layer-70" "agent" "dsh" "enable" ]
      [ "layers" "layer-71" "harness" "dsh" "enable" ]
    )
  ];

  options.layers.layer-71.harness.dsh = {
    enable = mkEnableOption "DeepSeek Harness (dsh) agent CLI";

    package = mkOption {
      type = types.nullOr types.package;
      default = dshPackage;
      description = "The dsh package to use";
    };

    profiles = mkOption {
      type = types.attrsOf profileSubmodule;
      default = {
        web = {
          plugins = [
            "@deepseek-ai/dsh-base"
            "@deepseek-ai/dsh-web-app"
          ];
        };
        headless = {
          plugins = [
            "@deepseek-ai/dsh-base"
            "@deepseek-ai/dsh-headless"
          ];
        };
      };
      description = "Declarative dsh profiles. Default includes web and headless profiles.";
    };

    webService = {
      enable = mkEnableOption "dsh web UI user systemd service (dsh --profile web web)";
      port = mkOption {
        type = types.port;
        default = 3007;
        description = "Local port for dsh web service";
      };
    };
  };

  nixos = mkIf (cfg.enable or false) {
    environment.systemPackages = mkIf (cfg.package != null) [ cfg.package ];

    environment.sessionVariables = {
      OPENAI_BASE_URL = "http://nami:8090/v1";
      OPENAI_BASE_URL_KONG_ER = "http://nami:8090/v1";
      OPENAI_BASE_URL_KONG_OMNI = "http://nami:8090/omni/v1";
      OPENAI_BASE_URL_KONG_FREE = "http://nami:8090/llm/free/v1";
      OPENAI_BASE_URL_KONG_FRONTIER = "http://nami:8090/llm/frontier/v1";
      OPENAI_BASE_URL_EXTREME_DIRECT = "http://127.0.0.1:20128/v1";
    };

    # Impermanence: Store manages profile composition (via dsh-nix); ~/.dsh persists runtime state and config
    environment.persistence."/persist" =
      mkIf (osConfig.layers.layer-10.system.config.impermanence.enable or false)
        {
          users.${primaryUser}.directories = [
            ".dsh"
          ];
        };
  };

  home =
    { ... }:
    {
      imports = [
        inputs.dsh-nix.homeManagerModules.dsh
      ];

      config = mkIf (cfg.enable or false) {
        programs.dsh = {
          enable = true;
          inherit (cfg) package;
          profiles = mapAttrs (_n: v: { inherit (v) plugins; }) cfg.profiles;
        };

        systemd.user.services.dsh-web = mkIf (cfg.webService.enable or false) {
          Unit = {
            Description = "DeepSeek Harness (dsh) Web UI Service";
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe cfg.package} --profile web web --port ${toString cfg.webService.port}";
            Restart = "always";
            RestartSec = 5;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
    };
}
