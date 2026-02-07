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
      gping
      bottom
      htop
      fastfetch
      neofetch # classic neofetch
      pciutils
      usbutils
      lsof
      tree
      psmisc

      # Image tools (needed for fzf preview)
      imagemagick
      chafa

      # CLI Fun & Utilities
      gum
      lolcat
      figlet
      toilet
      blahaj
      terminal-parrot
      neo-cowsay
      charasay
      fortune-kind
    ];
  };
}
