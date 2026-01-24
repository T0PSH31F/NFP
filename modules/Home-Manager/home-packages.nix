{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
  ];

  home.packages = with pkgs; [
    age # encryption tool
    asciinema # record the terminal
    baobab # disk usage utility
    blahaj
    buildah # build OCI images (alternative to docker build)
    ctop # top-like interface for container metrics
    cpufetch
    curl
    dbeaver-bin # GUI for many SQL databases https://dbeaver.io/about/
    ddrescue # data recovery tool (I also use it to burn an ISO to a USB flash drive)
    ddrescueview # Graphical viewer for GNU ddrescue mapfiles
    difftastic # syntax-aware diff
    distrobox # Wrapper around podman or docker to create and start containers
    dive # explore the layers of a container image
    exif # read and manipulate EXIF data in digital photographs
    fd
    ffmpeg
    file # show the type of files
    filebot
    flameshot # Powerful yet simple to use screenshot software
    flyctl # Fly.io CLI
    fx # JSON viewer
    gh # GitHub CLI
    #gimp # image editor
    glow # terminal markdown viewer
    gnumake # GNU Make (build tool)
    go
    # Graphics & GUI
    font-manager
    bitwarden-desktop
    pavucontrol
    signal-desktop
    obsidian
    vencord
    mpv
    zathura
    swayimg
    imv
    nextcloud-client

    # Icons & Cursors (System Preference)
    papirus-icon-theme
    dracula-icon-theme
    kora-icon-theme
    candy-icons
    sweet-folders
    adwaita-icon-theme
    bibata-cursors
    capitaine-cursors
    rose-pine-hyprcursor

    # CLI Utilities (Refactored from base.nix and packages.nix)
    htop
    tree
    zip
    unzip
    alejandra
    nil
    nixfmt
    deadnix
    statix
    bat
    ripgrep
    fzf
    jq
    ps_mem
    smem
    fd
    zoxide
    fastfetch
    neofetch
    duf
    glances
    bandwhich
    zellij
    gum
    # Inputs packages
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
    inputs.nixai.packages.${pkgs.stdenv.hostPlatform.system}.default
    graphviz
    gpufetch
    hyperfine # command-line benchmarking tool
    #inkscape # vector graphics editor
    libreoffice # a variant of openoffice.org
    lm_sensors # tools for reading hardware sensors
    lshw # detailed information on the hardware configuration of the machine
    lsix # shows thumbnails in terminal using sixel graphics
    metasploit # Metasploit framework
    monolith # save a web page as a single HTML file
    mtr # network diagnostics tool (basically traceroute + ping)
    ncdu # disk usage utility
    neofetch
    ocrmypdf # adds an OCR text layer to scanned PDF files, allowing them to be searched (e.g. with ripgrep-all)
    ouch # compress/decompress files and directories
    obsidian # knowledge base
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    pgadmin4
    pgcli # Command-line interface for PostgreSQL
    prettyping # a nicer ping
    procs # a better `ps`
    pstree # show the set of running processes as a tree
    pywalfox-native
    remmina # remote desktop client
    rm-improved
    rofi # application launcher & window switcher
    screenkey # shows keypresses on screen
    sd # sed alternative
    (writeShellApplication {
      name = "show-nixos-org";
      runtimeInputs = [
        curl
        w3m
      ];
      text = ''
        curl -s 'https://nixos.org' | w3m -dump -T text/html
      '';
    })
    #simplescreenrecorder # screen recorder gui
    sqlite
    sqlitebrowser
    tealdeer # TLDR pages for commands
    thunderbird # email client
    toybox
    unzrip # unzip replacement with parallel decompression
    usbutils # tools for working with USB devices, such as lsusb
    visidata # CLI for Exploratory Data Analysis
    w3m # text-based web browser
    wget
    yarr # Yet another rss reader
    yt-dlp
    zeal # offline documentation browser

    # Anime/Media streaming CLI tools from justchokingaround
    # NOTE: Temporarily disabled due to html-xml-utils build failure in nixpkgs
    # inputs.lobster.packages.${pkgs.system}.default # Anime streaming CLI
    # inputs.jerry.packages.${pkgs.system}.default # Anime streaming CLI (alternative)

    # Nix package search with fzf/television integration
    inputs.nix-search-tv.packages.${pkgs.system}.default
    television # Required for nix-search-tv television integration

    # Terminal emulators
    alacritty # Open GL terminal emulator
    foot # GPU-accelerated terminal emulator
    ghostty
    kitty # GPU-based terminal emulator
    warp-terminal # GPU-accelerated terminal emulator
    wezterm

    # CLI tools and utilities
    cbonsai
    cmatrix
    eza # fork of exa, a better `ls`
    lsd # modern ls alternative
    fortune
    gotree
    sl
    toilet # print large text from a string
    figlet # print large text from a string
    neo-cowsay
    neohtop
    pricehist
    viu # Available in nixpkgs
    zfxtop
    # superfile - may need to be packaged or built from source

    # Document readers and viewers
    calibre
    foliate # Simple and modern GTK eBook reader
    librum
    koreader
    # calibre-web - typically a service
    zathura
    zellij

    # Media players
    kodi
    vlc
    # mpv # configured via programs.mpv in mpv.nix
    feh
    # spotify # provided by spicetify below

    # Messaging and communication
    kotatogram-desktop # Telegram client
    caprine-bin # Facebook Messenger
    equibop
    element-desktop # Matrix client
    betterdiscord-installer # Discord
    betterdiscordctl
    vesktop
    fastfetch
  ];

  # Spicetify configuration
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      # Dribbblish theme
      theme = spicePkgs.themes.dribbblish;
      colorScheme = "nord-dark"; # Options: base, nord-dark, nord-light, etc.

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle # shuffle+
        keyboardShortcut
        fullAppDisplay
      ];
    };

  # Lazygit configuration
  programs.lazygit = {
    enable = true;
  };
}
