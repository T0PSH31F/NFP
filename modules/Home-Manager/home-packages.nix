{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
  ];

  home.packages = with pkgs; [
    # --- Core Essentials ---
    age # Encryption
    binutils
    curl
    file
    gh # GitHub CLI
    git
    ouch # Modern compression tool
    pciutils
    sops # Secret management
    unzip
    unzrip # Parallel unzip
    usbutils
    wget
    zip

    # --- CLI Utilities & Modern Replacements ---
    bandwhich # network monitor
    bat # cat with wings
    btop # the mac-daddy of tops
    ctop # container monitor
    difftastic # structural diff
    duf # better df
    eza # better ls
    fd # better find
    fx # JSON viewer
    fzf # fuzzy finder
    glances # system monitor
    gotree # gt nice tree-view in terminal
    hyperfine # benchmarking
    jq # JSON processor
    lsd
    lsix # thumbnails in terminal
    ncdu # better du
    procs # better ps
    ripgrep # better grep
    rm-improved # rip
    sd # better sed
    tealdeer # tldr pages
    w3m # cli web-browser
    zoxide # better cd

    # --- Development Tools ---
    buildah # container builds
    cpufetch
    dbeaver-bin # GUI
    devenv # developer environments
    distrobox # containers
    dive # image explorer
    gcc
    gnumake
    go
    gpufetch
    graphviz
    nodejs
    pgadmin4 # GUI
    pgcli # postgres client
    poetry # python env
    python3
    sqlite
    sqlitebrowser # GUI
    typescript
    uv # faster python
    visidata # data tables CLI

    # --- System & Maintenance ---
    baobab # disk usage GUI
    ddrescue # data recovery
    ddrescueview # recovery viewer
    font-manager
    lm_sensors
    lshw
    mtr # network traceroute
    ocrmypdf # OCR for PDFs
    prettyping
    remmina # remote desktop
    screenkey # show keypresses

    # --- Nix Ecosystem ---
    alejandra # nix formatter
    deadnix # find dead code
    inputs.nixai.packages.${pkgs.system}.default
    nix-search-tv
    nix-top
    nixfmt
    statix # nix lints
    television

    # --- Graphics & Multimedia ---
    feh # image viewer
    ffmpeg
    imagemagick
    img2pdf
    imv # image viewer
    kodi
    pavucontrol # audio control
    spicetify-cli # handled by module below usually
    swayimg
    vlc
    yt-dlp

    # --- Desktop Productivity ---
    bitwarden-desktop
    calibre # eBooks
    caprine-bin # messenger
    element-desktop # matrix
    exegol4
    foliate # eBook reader
    kasasa # Snip and pin useful information to a small floating window
    # NOTICE! best configured with a keybind/shorcut needs setup!
    koreader # eBook reader
    kotatogram-desktop # telegram
    libreoffice
    librum # Library manager
    nextcloud-client
    obsidian # knowledge base
    signal-desktop # messaging
    silverbullet
    skate
    thunderbird # email
    vencord # discord
    vesktop # discord
    windsend-rs # Quickly and securely sync clipboard, transfer files and directories between devices
    yt-dlp # video downloader
    zathura # PDF
    zeal # documentation

    # --- Terminal Emulators & Multiplexers ---
    alacritty
    foot
    ghostty
    kitty
    tmux
    warp-terminal
    wezterm
    zellij

    # --- Fun & Aesthetics ---
    asciiquarium-transparent
    ascii-image-converter
    asciinema # terminal recorder
    blahaj # essential
    cbonsai
    cmatrix
    fastfetch
    figlet
    fortune
    lavat
    lolcat
    neo-cowsay
    neofetch
    sl # steam locomotive
    toilet

    # --- Custom Shell Scripts ---
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

    # --- System Themes (Home-Manager Preference) ---
    adwaita-icon-theme
    bibata-cursors
    candy-icons
    capitaine-cursors
    dracula-icon-theme
    # kora-icon-theme # Conflicts with BeautyLine - using BeautyLine from gtk.nix
    libsForQt5.qt5ct
    pywalfox-native
    qt6Packages.qt6ct
    hyprcursor
    rose-pine-hyprcursor
    sweet-folders
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
      colorScheme = "rosepine"; # Options: base, nord-dark, nord-light, etc.

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
