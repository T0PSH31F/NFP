# flake-parts/system/default.nix
# Core system modules - foundational configuration for all machines
{
  imports = [
    ./base.nix
    ./nix-settings.nix
    ./networking.nix
    ./nix-tools.nix
    ./clan-lib.nix
    ./fonts.nix
    ./overlays.nix
    ./stability.nix
    ./core-programs.nix
  ];
}
