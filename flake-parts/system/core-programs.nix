# flake-parts/system/core-programs.nix
{ pkgs, ... }:
{
  # Enable nix-ld for running non-NixOS binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    curl
    expat
    fuse3
    icu
    nss
    openssl
    stdenv.cc.cc.lib
    zlib
  ];

  # Starship prompt
  programs.starship.enable = true;

  # Additional core utilities not in system/base.nix
  environment.systemPackages = with pkgs; [
    # Essentials
    bubblewrap
    imagemagick
    img2pdf
    poppler-utils
    qpdf
    unrar

    # System Utilities
    file
    iftop
    iotop
    lsof
    psmisc
    which

    # System/Disk tools
    aria2
    btrfs-progs
    exfatprogs
    gparted
    ntfs3g
    parted
    sops
  ];
}
