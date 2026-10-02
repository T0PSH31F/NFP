# Foundation Tier Entry Point — core system modules for all machines
{
  imports = [
    ./base.nix
    ./builders.nix
    ./caches.nix
    ./clan-lib.nix
    ./fonts.nix
    ./networking.nix
    ./nix-settings.nix
    ./nix-tools.nix
    ./overlays.nix
    ./base-packages.nix
    ./meta.nix
    ./manifest.nix
    ./layer-registry.nix
  ];
}
