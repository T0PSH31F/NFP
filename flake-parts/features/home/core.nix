{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  # Note: CLI environment is now configured in ./cli

  # Basic tools in user profile
  home.packages = with pkgs; [
    # Core utilities
    devenv # Keep devenv for dev environments
  ];
}
