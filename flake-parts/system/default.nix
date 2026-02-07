# flake-parts/system/default.nix
# Core system modules - foundational configuration for all machines
{
  imports = [
    ./base.nix
    ./nix-settings.nix
    ./networking.nix
  ];
}
