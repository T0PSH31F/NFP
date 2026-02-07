# flake-parts/features/home/cli/tools/git.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "T0PSH31F";
      userEmail = "wrighterik77@gmail.com";

      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          # Fallback if matugen is disabled
          syntax-theme = lib.mkIf (!cfg.theming.enable) "Catppuccin-mocha";
        };
      };

      includes = lib.mkIf cfg.theming.enable [
        { path = "~/.config/delta/matugen-theme.gitconfig"; }
      ];

      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "hx";
        delta = lib.mkIf cfg.theming.enable {
          features = "matugen";
        };
      };
    };

    home.packages = with pkgs; [
      lazygit
      gitui
      gh
    ];
  };
}
