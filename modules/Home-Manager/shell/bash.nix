{
  config,
  lib,
  pkgs,
  ...
}: {
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
    '';
  };
}
