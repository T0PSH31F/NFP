{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
  matugenEnabled = config.layers.layer-50.cli.theming.matugen.enable or false;
in
{
  home =
    _:
    lib.mkIf cfg.enable {
      programs = {
        delta = {
          enable = true;
          enableGitIntegration = true;
          options = {
            navigate = true;
            line-numbers = true;
            syntax-theme = lib.mkIf (!cfg.theming.enable) "Catppuccin-mocha";
          };
        };

        git = {
          enable = true;
          # NOTE: the sops-templated git-config include (name/email) lives in
          # layers/10-system/13-users/t0psh31f.nix, alongside the template
          # definition itself. It cannot be set here: this "home" block is
          # pre-evaluated by mkDendriticModule using the outer NixOS config,
          # which has no `sops.templates` of its own (that only exists in the
          # real home-manager submodule scope where the template is defined).
          includes = lib.optionals matugenEnabled [
            { path = "~/.config/delta/matugen-theme.gitconfig"; }
          ];

          settings = {
            init.defaultBranch = "main";
            core.editor = "hx";
            delta = lib.mkIf matugenEnabled { features = "matugen"; };
            credential.helper = "store --file ~/.config/git/credentials";
          };
        };

        lazygit = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = true;
        };
      };

      home.packages = with pkgs; [
        github-mcp-server
        git-credential-manager
        git-big-picture
        github-to-sops
        github-desktop
        github-runner
        gitmoji-cli
        git-secrets
        git-hound
        gitwatch
        gitleaks
        gitui
        gh
      ];
    };
}
