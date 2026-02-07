{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./core.nix
    ./shell.nix
    ./vscode.nix
    ./desktop.nix
    ./dev.nix
    ./pentest.nix
    ./gaming.nix
  ];
}
