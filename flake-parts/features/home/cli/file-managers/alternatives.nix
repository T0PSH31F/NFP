# flake-parts/features/home/cli/file-managers/alternatives.nix
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
      ranger
      lf
      fff
    ];
  };
}
