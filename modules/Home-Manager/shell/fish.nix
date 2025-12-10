{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "eza -la";
      ls = "eza";
      l = "eza -lah";
      tree = "eza --tree";
      g = "git";
      lg = "lazygit";
      cat = "bat";
      grep = "rg";
      find = "fd";
    };

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      starship init fish | source
      zoxide init fish | source
    '';

    plugins = [
      # Enable plugins via home-manager if available or manual list
    ];
  };
}
