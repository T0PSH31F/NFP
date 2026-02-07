{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core system utilities
    coreutils
    util-linux
    procps

    # File management
    file
    tree
    fd
    ripgrep

    # Network tools
    curl
    wget
    rsync

    # Text editors
    vim
    nano

    # System monitoring
    htop
    btop

    # Archive tools
    unzip
    zip
    gnutar

    # Development basics
    git

    # Security
    gnupg
    age
  ];
}
