{
  config,
  lib,
  mkDendriticModule,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  imports = [
    ./51-shells
    ./52-editors
    ./53-tools
    ./54-multiplexers
    ./55-prompt
    ./56-file-managers
    ./57-services
    ./58-theming
    ./59-integrations
    ./packages-dev.nix
  ];

  options.layers.layer-50.cli = {
    enable = lib.mkEnableOption "Complete CLI/TUI environment" // {
      default = true;
    };

    theming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable dynamic theming for CLI tools";
      };
      theme = lib.mkOption {
        type = lib.types.enum [
          "Catppuccin Lavender"
          "Cherry Blossom"
          "Cyberpunk"
          "Everdeer"
          "Everforest"
          "GitHub Dark"
          "Gruber Darker"
          "GruvboxAlt"
          "Hexa34C"
          "Lilac AMOLED"
          "Miasma"
          "Monochrome"
          "NaySayer"
          "Noctalia legacy"
          "Oasis Abyss"
          "Occult Umbral"
          "One"
          "Osaka jade"
          "Oxide"
          "Oxocarbon"
          "Peche"
          "Tokyo Night Moon"
          "Tokyo Night"
          "Vesper"
          "tokyo-night"
        ];
        default = "tokyo-night";
        description = "Static theme to use in headless mode";
      };
    };

    shells = {
      zsh.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Zsh with full Powerlevel10k configuration";
      };
      bash.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Bash configuration";
      };
    };

    yazelixIntegration.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Helix + Yazi + Zellij integration (deprecated — use zellij.yazelix.* flags instead)";
    };

    zellij = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Zellij terminal multiplexer";
      };
      yazelix = {
        bars.enable = lib.mkEnableOption "Yazelix Zellij bars (top + bottom, CPU/RAM, AI token usage)";
        orchestrator.enable = lib.mkEnableOption "Yazelix pane orchestrator (Alt+y toggleable sidebars)";
        popup.enable = lib.mkEnableOption "Yazelix popup runner (Alt+g floating windows)";
        cursors.enable = lib.mkEnableOption "Yazelix cursor themes for Ghostty";
        screen.enable = lib.mkEnableOption "Yazelix terminal welcome screen animations";
      };
    };

    modernTools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable modern CLI tool replacements (bat, eza, ripgrep, etc.)";
    };

    nixToolsHM.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Nix-specific CLI tools (Home Manager side)";
    };

    pythonTools.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Python and related tools (uv, etc.)";
    };

    terminal-toys = {
      enable = lib.mkEnableOption "Fun terminal toys (cmatrix, cbonsai, etc.)";
    };

    headless = lib.mkEnableOption "Headless/VPS environment optimizations";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.t0psh31f = {
      imports = [ ../80-lib/81-helpers/hm-bridge.nix ];
      config = {
        programs.cli-environment = {
          enable = true;
          theming.enable = cfg.theming.enable;
          inherit (cfg) headless;
        };
      };
    };

    # Matugen disabled — Noctalia owns all runtime theming (wallpaper → Material You colors)
    # Matugen templates conflicted with Noctalia's own template system for the same apps
    layers.layer-50.cli.theming.matugen.enable = lib.mkDefault false;
  };
}
