{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Base Desktop Backends
    ./hyprland.nix
    ./niri.nix

    # Desktop Shells / Environments
    ./Noctalia/default.nix
    ./Dankmaterialshell/default.nix
    ./Caelestia-shell/default.nix
    ./Omarchy/default.nix
    ./End-4/illogical-impulse.nix
  ];
}
