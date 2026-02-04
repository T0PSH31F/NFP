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
  ];
}
