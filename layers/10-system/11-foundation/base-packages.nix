# flake-parts/features/nixos/packages/base.nix
{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Archive tools
    gnutar
    p7zip
    file-roller
    unrar
    unzip
    zip

    # Core system utilities
    coreutils
    fd
    file
    gotree
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
    git # (Installed via gitFull in dev-packages or other suites)

    # Disk management
    btrfs-assistant
    btrfs-progs
    exfatprogs
    gparted
    parted

    # Document & Image utilities
    calibre
    imagemagick
    img2pdf
    poppler-utils
    qpdf
    python3Packages.weasyprint
    # texlive.combined schemes deprecated (removal in 27.05) — use texliveSmall
    texliveSmall
    wkhtmltopdf

    # Isolation
    bubblewrap

    # Network tools
    aria2
    curl
    rsync
    sshfs
    wget

    # Security & Secrets
    age
    gnupg
    sops

    # Fleet management
    inputs.clan-core.packages.${pkgs.stdenv.hostPlatform.system}.clan-cli
  ];

  programs.starship.enable = true;
}
