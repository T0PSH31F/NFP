# flake-parts/features/home/cli/tools/nix-tools.nix
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
  config = lib.mkIf (cfg.enable && cfg.nixTools.enable) {
    home.packages = with pkgs; [
      nil
      nixfmt
      statix
      deadnix
      nix-tree
      nix-search-tv
      nh
    ];
  };
}
