# flake-parts/themes/default.nix
# Visual themes for bootloader, display manager, and Plymouth
{ ... }:
{
  imports = [
    # Commented out themes requested to be removed/cleaned up
    # ./sddm-lain.nix
    # ./sddm-lainframe.nix
    ./grub-lain.nix
    ./plymouth-hellonavi.nix
    ./plymouth-matrix.nix
    ./sddm-sel.nix
    ./sddm-sugar-dark.nix
  ];
}
