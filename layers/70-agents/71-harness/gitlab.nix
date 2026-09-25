# Tier: 71-harness
# Module: gitlab.nix
# Purpose: Declarative GitLab CLI, glab-tui, and GitLab Duo AI agent integration.
# Option Path: layers.layer-71.harness.gitlab
# Enabling Host Tags: ai-agent, development, workstation
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-71.harness.gitlab;
in
{
  options.layers.layer-71.harness.gitlab = {
    enable = mkEnableOption "GitLab CLI, glab-tui, and GitLab Duo AI assistant";
  };

  home = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.glab
      pkgs.gitlab-duo
    ]
    ++ lib.optional (pkgs ? glab-tui) pkgs.glab-tui;

    home.shellAliases = {
      gl = "glab";
      gld = "gitlab-duo";
    };

    programs.zsh.initContent = ''
      # GitLab CLI completions
      if command -v glab &>/dev/null; then
        eval "$(glab completion -s zsh)"
      fi
    '';

    programs.bash.initExtra = ''
      # GitLab CLI completions
      if command -v glab &>/dev/null; then
        eval "$(glab completion -s bash)"
      fi
    '';
  };
}
