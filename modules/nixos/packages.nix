{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs = {
    overlays = [
      inputs.anifetch.overlays.anifetch
    ];
  };

  environment.systemPackages = with pkgs; [
    # AI Tools - will be configured as services where applicable
    # Development tools
    antigravity-fhs
    aria2
    bandwhich # display network utilization by process, connection and remote IP/hostname
    bat # cat(1) clone with syntax highlighting and Git integration
    binutils # tools for manipulating binaries (nm, objdump, strip, etc...)
    btop # interactive process viewer
    cmake # build tool
    curl # command-line tool for transferring data with URL syntax
    # dbeaver # database browser (currently undefined)
    devenv # Fast, Declarative, Reproducible, and Composable Developer Environments
    docker-compose # define and run multi-container applications with Docker
    duf # disk usage utility
    #exodus # Crypto currency wallet
    eza # fork of exa, a better `ls`
    fd # a better `find`
    feh # image viewer
    figlet # print large text from a string
    fzf # fuzzy finder
    gedit # text editor
    ghostty # terminal emulator
    git # distributed version control system
    git-credential-manager # Git credential manager
    gitFull # git + graphical tools like gitk (see https://nixos.wiki/wiki/Git)
    gitg # git GUI
    glances # system monitoring tool
    gpgme
    gnupg # GNU Privacy Guard
    gotree # tree-like view
    gpa # Graphical user interface for the GnuPG
    gparted # partition editor
    grayjay # n application to stream and download content from various sources
    neohtop # interactive process viewer
    hyprviz # hyprland configuration GUI editor
    hyprmon # hyprland monitor
    rose-pine-hyprcursor # hyprland cursor theme
    hyprsysteminfo # hyprland system info
    hyprpolkitagent # hyprland polkit agent
    hdrop # hyprland retractable workspace pager
    imv # image viewer
    imagemagick # Software suite to create, edit, compose, or convert bitmap images
    img2pdf # Convert images to PDF via direct JPEG inclusion
    jq # command-line JSON processor
    keychain # keychain manager
    kiro-fhs # AI-Agent enabled workflow IDE
    kotatogram-desktop # Telegram client (currently undefined)
    lavat # cli toy lava lamp animation
    libgcc # GNU Compiler Collection
    libnotify # send desktop notifications to a notification daemon
    logitech-udev-rules # Logitech Unifying receiver udev rules
    mongodb-compass # MongoDB GUI
    motrix # torrent downloader
    mpd # music player daemon
    neovim # advanced text editor
    nextcloud-client # Nextcloud client
    nmap # tool for network discovery and security auditing
    ntfs3g # FUSE-based NTFS driver
    obsidian # knowledge base
    p7zip # 7z, 7za, 7zr
    perf # Linux tools to profile with performance counters
    pinentry-curses # GnuPG's interface to passphrase input
    pinentry-all # GnuPG's interface to passphrase input
    pgadmin4 # PostgreSQL GUI
    poetry # Python dependency management and packaging
    poppler-utils # Rendering library and utilities for PDF files (e.g. pdfunite)
    popsicle # Multiple USB File Flasher. I was looking for Balena Etcher and found this: https://github.com/NixOS/nixpkgs/issues/371992#issuecomment-2576548039
    qpdf # library and set of programs that inspect and manipulate the structure of PDF files
    # railway # CLI for Railway (Paas) (commented out - undefined)
    ripgrep # grep alternative
    signal-desktop # Private, simple, and secure messenger
    skopeo # CLI for various operations on container images and image repositories
    solaar # Solaar is a daemon and a GTK+ application to control Logitech Unifying receivers
    sops # editor for encrypting/decrypting JSON, YAML, ini, etc
    # sshd # SSH server (use services.openssh.enable instead)
    transmission_4 # BitTorrent client
    typescript # TypeScript compiler
    unrar # Unrar tool
    unzip # Unzip tool
    uv # python package manager
    xpipe
    vencord # Discord client
    vim # text editor
    waytrogen
    wget # command-line tool for transferring data with URL syntax
    winetricks # script to install DLLs needed to work around problems in Wine
    wineWowPackages.stable # https://nixos.wiki/wiki/Wine
    zathura # PDF viewer
    zellij
    zoxide # cd replacement
    zip # zip tool

    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
    # inputs.lobster.packages.${system}.lobster  # Temporarily disabled - html-xml-utils build failure
    # inputs.jerry.packages.${system}.jerry  # Temporarily disabled - html-xml-utils build failure
    inputs.nixai.packages.${system}.default
    # inputs.anifetch.packages.${pkgs.system}.default
    anifetch
    fastfetch
    neofetch

    # Wireless Pentesting & Security
    aircrack-ng
    hcxdumptool
    hcxtools
    hashcat
    wireshark
    wireshark-cli # provides tshark
    bettercap
    kismet

    # TUI Tools (Charm)
    gum # "Bubble tea" utils
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
