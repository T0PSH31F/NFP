# flake-parts/features/home/cli/tools/fzf.nix
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; elif file --mime-type {} | grep -q \"image/\"; then chafa -f iterm -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} {}; else bat -n --color=always --line-range :500 {}; fi'"
      ];
    };

    # Source Matugen theme if enabled
    programs.zsh.initContent = lib.mkIf (cfg.shells.zsh.enable && cfg.theming.enable) ''
      # Source FZF matugen theme
      [ -f ~/.config/fzf/matugen.conf ] && source ~/.config/fzf/matugen.conf
    '';

    programs.bash.initExtra = lib.mkIf (cfg.shells.bash.enable && cfg.theming.enable) ''
      # Source FZF matugen theme
      [ -f ~/.config/fzf/matugen.conf ] && source ~/.config/fzf/matugen.conf
    '';
  };
}
