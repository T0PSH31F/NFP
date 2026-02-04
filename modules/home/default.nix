{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./core.nix
    ./desktop.nix
    ./dev.nix
    ./pentest.nix
    ./gaming.nix
  ];
}
