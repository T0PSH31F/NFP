{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.command = "";
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidget.command = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidget.options = [
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
