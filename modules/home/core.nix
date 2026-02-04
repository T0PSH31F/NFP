{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  # Note: ZSH and shell tools are configured in shell.nix

  # Basic tools in user profile
  home.packages = with pkgs; [
    # Yazelix dependencies
    nushell
    devenv
  ];

  # Basic git config
  programs.git = {
    enable = true;
    settings.user.name = "T0PSH31F";
    settings.user.email = ".com";
  };
}
