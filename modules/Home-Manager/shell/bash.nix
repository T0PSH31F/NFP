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

      # Anifetch MOTD - Display Lain GIF ONLY
      _anifetch_motd() {
        local lain_gif="$HOME/.background/Giffees/Lain/oldScreen.gif"
        if command -v anifetch &> /dev/null && [[ -f "$lain_gif" ]]; then
          # Display Lain GIF with anifetch (40 width, 20 height, 1 repeat)
          anifetch "$lain_gif" -r 1 -W 40 -H 20 -c "--symbols wide --fg-only" 2>/dev/null || true
        fi
      }
      # Only show MOTD for interactive shells, not in tmux/screen, and not in VSCode terminal
      if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "$STY" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
        _anifetch_motd
      fi
    '';
  };
}
