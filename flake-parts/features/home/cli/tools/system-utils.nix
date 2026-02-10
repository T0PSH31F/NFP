# flake-parts/features/home/cli/tools/system-utils.nix
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
      bottom
      fastfetch
      gping
      htop
      lsof
      pciutils
      psmisc
      tree
      usbutils

      # Image tools
      chafa
      imagemagick

      # CLI Fun & Utilities
      blahaj
      charasay
      figlet
      fortune-kind
      gum
      lolcat
      neo-cowsay
      neofetch # classic neofetch
      terminal-parrot
      toilet
    ];
  };
}
