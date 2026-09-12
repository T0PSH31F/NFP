# Tier: 71-harness
# Module: herdr.nix
# Purpose: Herdr terminal workspace manager for AI coding agents (numtide/llm-agents).
# Option Path: programs.herdr
# Enabling Host Tags: ai-agent, development, workstation
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
  cfg = config.programs.herdr;
  primaryUser = osConfig.layers.meta.primaryUser or "t0psh31f";
  sys = pkgs.stdenv.hostPlatform.system;
  llmPkgs = inputs.llm-agents.packages.${sys} or { };
  herdrPackage = pkgs.herdr or llmPkgs.herdr or null;

  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "herdr-config.toml" cfg.settings;

  # Helper script to launch workspaces for opencode, hermes, and antigravity-cli
  herdr-setup-workspaces = pkgs.writeShellScriptBin "herdr-setup-workspaces" ''
    set -euo pipefail

    echo "==> Initializing Herdr agent workspaces..."

    # Ensure Herdr server is running or start persistent session
    if ! ${cfg.package}/bin/herdr status server >/dev/null 2>&1; then
      echo "Starting Herdr background server..."
    fi

    # Create workspace: OpenCode
    echo "Configuring workspace: opencode"
    ${cfg.package}/bin/herdr workspace create --label "opencode" --no-focus || true

    # Create workspace: Hermes Agent
    echo "Configuring workspace: hermes"
    ${cfg.package}/bin/herdr workspace create --label "hermes" --no-focus || true

    # Create workspace: Antigravity CLI
    echo "Configuring workspace: antigravity-cli"
    ${cfg.package}/bin/herdr workspace create --label "antigravity-cli" --no-focus || true

    echo "==> Herdr workspaces (opencode, hermes, antigravity-cli) ready."
  '';
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-71" "harness" "herdr" "enable" ]
      [ "programs" "herdr" "enable" ]
    )
    (lib.mkAliasOptionModule
      [ "services" "ai-services" "herdr" "enable" ]
      [ "programs" "herdr" "enable" ]
    )
  ];

  options.programs.herdr = {
    enable = mkEnableOption "Herdr — terminal workspace manager for AI coding agents";

    package = mkOption {
      type = types.nullOr types.package;
      default = herdrPackage;
      description = "The herdr package to use";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "Configuration settings written to /etc/herdr/config.toml & user environment";
    };
  };

  config = mkIf cfg.enable {
    programs.herdr.settings = {
      theme = {
        name = mkDefault "catppuccin";
      };
      terminal = {
        new_cwd = mkDefault "follow";
        kitty_graphics = mkDefault true;
      };
      ui = {
        pane_borders = mkDefault "auto";
        pane_outer_borders = mkDefault true;
        pane_scrollbars = mkDefault true;
        pane_gaps = mkDefault true;
        hide_tab_bar_when_single_tab = mkDefault false;
        tab_bar_position = mkDefault "top";
        window_title = mkDefault "{hostname}: {workspace}";
      };
      session = {
        resume_agents_on_restore = mkDefault true;
      };
    };

    environment.systemPackages = mkIf (cfg.package != null) [
      cfg.package
      herdr-setup-workspaces
    ];

    # Write global configuration file
    environment.etc."herdr/config.toml".source = configFile;
    environment.etc."xdg/herdr/config.toml".source = configFile;

    # Impermanence persistence
    environment.persistence."/persist" =
      mkIf (osConfig.layers.layer-10.system.config.impermanence.enable or false)
        {
          users.${primaryUser}.directories = [
            ".config/herdr"
            ".local/share/herdr"
          ];
        };
  };
}
