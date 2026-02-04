{ pkgs, ... }:

{
  # Core tools: loaded on all systems, regardless of tags
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tmux
    btop

    pciutils
    usbutils
    psmisc
    lsof
    file
    which
    tree

    ripgrep
    fd
    jq

    unzip
    zip
    p7zip

    iotop
    iftop
    
    # System Utilities
    aria2
    gparted
    ntfs3g
    sops
    parted
    exfatprogs
    btrfs-progs

    # Essentials
    imagemagick
    img2pdf
    poppler-utils
    qpdf
    unrar
    bubblewrap
    sonic-cursor
  ];

  # Enable nix-ld for running non-NixOS binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];
  programs.starship.enable = true;
}
