{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "eza -la";
      ls = "eza";
      l = "eza -lah";
      tree = "eza --tree";
      ".." = "cd ..";
      "..." = "cd ../..";
      g = "git";
      lg = "lazygit";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # NixOS
      rebuild = "sudo nixos-rebuild switch --flake .";
      update = "nix flake update";
      clean = "nix-collect-garbage -d";

      # Nix package search with fzf (nix-search-tv)
      ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
    };

    initExtra = ''
      # Initialize starship prompt
      eval "$(starship init bash)"

      # Initialize zoxide
      eval "$(zoxide init bash)"

      # FZF bindings
      source ${pkgs.fzf}/share/fzf/key-bindings.bash
      source ${pkgs.fzf}/share/fzf/completion.bash

      if [ -n "$IN_NIX_SHELL" ]; then
        export PS1="[nix-shell] $PS1"
      fi

      # Anifetch MOTD - Display system info with neofetch/anifetch
      _anifetch_motd() {
        if command -v anifetch &> /dev/null; then
          anifetch 2>/dev/null || neofetch 2>/dev/null || true
        elif command -v neofetch &> /dev/null; then
          neofetch 2>/dev/null || true
        fi
      }
      # Only show MOTD for interactive shells, not in tmux/screen, and not in VSCode terminal
      if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "$STY" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
        _anifetch_motd
      fi
    '';
  };
}
