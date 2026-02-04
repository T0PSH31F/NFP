{
  config,
  pkgs,
  lib,
  ...
}:
{

  programs.home-manager.enable = true;

  # Shell / prompt
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Basic tools in user profile
  home.packages = with pkgs; [
    starship
    eza
    bat
    fzf
    ripgrep
    fd
    jq
  ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Basic git config
  programs.git = {
    enable = true;
    userName = "Erik";
    userEmail = "you@example.com";
  };
}
