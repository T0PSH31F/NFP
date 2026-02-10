{ pkgs, ... }:

{
  # Core tools: loaded on all systems, regardless of tags
  environment.systemPackages = with pkgs; [
    # Essentials
    bubblewrap
    imagemagick
    img2pdf
    poppler-utils
    qpdf
    unrar

    # Monitoring
    btop
    htop
    iftop
    iotop

    # Network Tools
    curl
    wget

    # System Basics
    git
    lsof
    pciutils
    psmisc
    tmux
    usbutils
    vim
    which

    # System/Disk Tools
    aria2
    btrfs-progs
    exfatprogs
    gparted
    ntfs3g
    parted
    sops

    # Utilities
    fd
    file
    jq
    p7zip
    ripgrep
    tree
    unzip
    zip
  ];

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
  programs.starship.enable = true;
}
