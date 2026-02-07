# flake-parts/features/home/cli/editors/fallbacks.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vim
      nano
    ];
  };
}
