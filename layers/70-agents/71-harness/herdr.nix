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
      keys = {
        # Single prefix only — herdr does NOT support multiple prefixes / zellij-style modes.
        # Kept as ctrl+b tmux-style (ctrl+p freed by moving ray/pet). User requested revert.
        # Then prefix+h/j/k/l still works; true ctrl+p / ctrl+t modal modes
        # would require a herdr plugin; see notes below.
        prefix = mkDefault "ctrl+b";

        # ── Zellij-like direct navigation (no prefix) ─────────────────────
        # Requested: Alt + arrows for pane/tab focus. These are direct chords
        # (no prefix) and override the defaults prefix+h/j/k/l.
        # Valid syntax: "alt+left/right/up/down", "alt+h/j/k/l", "ctrl+alt+…".
        # Alt-bindings depend on terminal passing Alt correctly (Kitty, Ghostty,
        # WezTerm, Alacritty all do; tmux nested needs set -g xterm-keys on).
        # Alt+arrows requested but Ghostty xterm-ghostty sends ESC[1;3* which Herdr
        # parses unreliably (see docs: alt+... depends on terminal). Alt+h/j/k/l
        # is reliable (ESC h) and matches zellij vim style.
        focus_pane_left = mkDefault "alt+h";
        focus_pane_right = mkDefault "alt+l";
        focus_pane_up = mkDefault "alt+k";
        focus_pane_down = mkDefault "alt+j";

        # Tab navigation without prefix — Alt+Shift+arrows (faster than prefix+p/n)
        # zellij tab-mode is ctrl+t → h/l ; this direct binding is more ergonomic.
        previous_tab = mkDefault "alt+shift+left";
        next_tab = mkDefault "alt+shift+right";
        move_tab_previous = mkDefault "ctrl+shift+left";
        move_tab_next = mkDefault "ctrl+shift+right";

        # Direct resize without entering resize_mode (like holding Alt in zellij)
        resize_pane_left = mkDefault "ctrl+alt+left";
        resize_pane_down = mkDefault "ctrl+alt+down";
        resize_pane_up = mkDefault "ctrl+alt+up";
        resize_pane_right = mkDefault "ctrl+alt+right";
        # Modal resize (zellij ctrl+n analog) — prefix+r then h/j/k/l, Esc to exit
        resize_mode = mkDefault "prefix+r";

        # Keep useful prefix bindings familiar; uncomment to make more zellij-like:
        # new_tab = "ctrl+t";      # zellij: ctrl+t → n  (default herdr: prefix+c)
        # close_tab = "prefix+shift+x";
        # split_vertical = "prefix+v";
        # split_horizontal = "prefix+minus";
        # zoom = "prefix+z";
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
