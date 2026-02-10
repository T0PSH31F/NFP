# flake-parts/features/home/cli/default.nix
{ config, lib, ... }:

let
  cfg = config.programs.cli-environment;
in
{
  imports = [
    ./editors/fallbacks.nix
    ./editors/helix.nix
    ./file-managers/alternatives.nix
    ./file-managers/yazi.nix
    ./integrations/keybindings.nix
    ./integrations/yazelix-style.nix
    ./multiplexers/tmux.nix
    ./multiplexers/zellij.nix
    ./prompt/starship.nix
    ./shells/bash.nix
    ./shells/common.nix
    ./shells/zsh.nix
    ./theming/matugen.nix
    ./tools/fzf.nix
    ./tools/git.nix
    ./tools/gpg.nix
    ./tools/modern-utils.nix
    ./tools/nix-tools.nix
    ./tools/system-utils.nix
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
