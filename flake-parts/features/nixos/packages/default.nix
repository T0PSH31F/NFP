# flake-parts/features/nixos/packages/default.nix
{ ... }:
{
  imports = [
    ./base.nix
    ./desktop.nix
    ./dev.nix
    ./pentest.nix
    ./media.nix
    ./ai.nix
  ];
}
