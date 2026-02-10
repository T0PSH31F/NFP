# flake-parts/features/nixos/packages/base.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Archive tools
    gnutar
    p7zip
    unrar
    unzip
    zip

    # Core system utilities
    coreutils
    fd
    file
    jq
    lsof
    pciutils
    procps
    psmisc
    ripgrep
    starship
    tmux
    tree
    usbutils
    util-linux
    which

    # Development basics
    git

    # Disk management
    btrfs-progs
    exfatprogs
    gparted
    ntfs3g
    parted

    # Document & Image utilities
    imagemagick
    img2pdf
    poppler-utils
    qpdf

    # Isolation
    bubblewrap

    # Network tools
    aria2
    curl
    rsync
    wget

    # Security & Secrets
    age
    gnupg
    sops

    # System monitoring
    btop
    htop
    iftop
    iotop

    # Text editors
    nano
    vim
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
