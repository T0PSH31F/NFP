# flake-parts/features/home/cli/default.nix
{ config, lib, ... }:

let
  cfg = config.programs.cli-environment;
in
{
  imports = [
    ./theming/matugen.nix
    ./shells/common.nix
    ./shells/zsh.nix
    ./shells/bash.nix
    ./editors/helix.nix
    ./editors/fallbacks.nix
    ./file-managers/yazi.nix
    ./file-managers/alternatives.nix
    ./multiplexers/zellij.nix
    ./multiplexers/tmux.nix
    ./tools/modern-utils.nix
    ./tools/git.nix
    ./tools/fzf.nix
    ./tools/nix-tools.nix
    ./tools/system-utils.nix
    ./integrations/yazelix-style.nix
    ./integrations/keybindings.nix
    ./prompt/starship.nix
  ];

  options.programs.cli-environment = {
    enable = lib.mkEnableOption "Complete CLI/TUI environment";

    theming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable dynamic theming for CLI tools";
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
      default = true;
      description = "Enable Helix + Yazi + Zellij integration";
    };

    modernTools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable modern CLI tool replacements (bat, eza, ripgrep, etc.)";
    };

    nixTools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Nix-specific CLI tools";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.cli-environment.theming.matugen.enable = cfg.theming.enable;
  };
}
