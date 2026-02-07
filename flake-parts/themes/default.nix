# flake-parts/themes/default.nix
# Visual themes for bootloader, display manager, and Plymouth
{
  imports = [
    ./sddm-lain.nix
    ./sddm-lainframe.nix
    ./sddm-sel.nix
    ./grub-lain.nix
    ./plymouth-hellonavi.nix
    ./plymouth-matrix.nix
  ];
}
