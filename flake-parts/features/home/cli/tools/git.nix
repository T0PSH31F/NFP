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
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        # Fallback if matugen is disabled
        syntax-theme = lib.mkIf (!cfg.theming.enable) "Catppuccin-mocha";
      };
    };

    programs.git = {
      enable = true;
      includes =
        (lib.optionals cfg.theming.enable [
          { path = "~/.config/delta/matugen-theme.gitconfig"; }
        ])
        ++ [
          { path = config.sops.templates."git-config".path; }
        ];

      settings = {
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
