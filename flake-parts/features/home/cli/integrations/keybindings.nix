# flake-parts/features/home/cli/integrations/keybindings.nix
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
    # Cross-tool keybinding coordination

    # fzf-powered directory navigation (Ctrl+F)
    # fzf-powered file opening in helix (Ctrl+E)

    programs.zsh.initContent = lib.mkIf cfg.shells.zsh.enable ''
      # fzf-powered directory navigation
      fzf-cd() {
        local dir
        dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=1 --icons {}')
        if [[ -n "$dir" ]]; then
          cd "$dir"
          zle reset-prompt
        fi
      }
      zle -N fzf-cd
      bindkey '^F' fzf-cd

      # fzf-powered file opening in helix
      fzf-edit() {
        local file
        file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {}')
        if [[ -n "$file" ]]; then
          hx "$file"
        fi
      }
      zle -N fzf-edit
      bindkey '^E' fzf-edit
    '';

    # Note: Bash fzf bindings are handled by programs.fzf.enableBashIntegration
  };
}
