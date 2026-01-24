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
    # --- Core Essentials ---
    curl
    wget
    git
    gh # GitHub CLI
    age # Encryption
    sops # Secret management
    usbutils
    pciutils
    binutils
    file
    zip
    unzip
    unzrip # Parallel unzip
    ouch # Modern compression tool
    toybox

    # --- CLI Utilities & Modern Replacements ---
    bat # cat with wings
    eza # better ls
    fd # better find
    ripgrep # better grep
    fzf # fuzzy finder
    zoxide # better cd
    jq # JSON processor
    fx # JSON viewer
    sd # better sed
    procs # better ps
    duf # better df
    ncdu # better du
    htop
    btop
    glances # system monitor
    bandwhich # network monitor
    ctop # container monitor
    lsix # thumbnails in terminal
    tealdeer # tldr pages
    hyperfine # benchmarking
    difftastic # structural diff
    rm-improved # rip

    # --- Development Tools ---
    gnumake
    gcc
    go
    python3
    nodejs
    typescript
    poetry # python env
    uv # faster python
    devenv # developer environments
    distrobox # containers
    buildah # container builds
    dive # image explorer
    sqlite
    pgcli # postgres client
    visidata # data tables CLI
    sqlitebrowser # GUI
    dbeaver-bin # GUI
    pgadmin4 # GUI
    graphviz
    gpufetch
    cpufetch

    # --- System & Maintenance ---
    baobab # disk usage GUI
    remmina # remote desktop
    ddrescue # data recovery
    ddrescueview # recovery viewer
    ocrmypdf # OCR for PDFs
    lshw
    lm_sensors
    mtr # network traceroute
    prettyping
    screenkey # show keypresses
    font-manager

    # --- Nix Ecosystem ---
    alejandra # nix formatter
    nixfmt-rfc-style
    deadnix # find dead code
    statix # nix lints
    nix-top
    inputs.nix-search-tv.packages.${pkgs.system}.default
    television # required for nix-search-tv
    inputs.nixai.packages.${pkgs.system}.default

    # --- Graphics & Multimedia ---
    feh # image viewer
    imv # image viewer
    swayimg
    mpv # media player
    vlc
    kodi
    ffmpeg
    imagemagick
    img2pdf
    yt-dlp
    pavucontrol # audio control
    spicetify-cli # handled by module below usually

    # --- Desktop Productivity ---
    obsidian # knowledge base
    libreoffice
    thunderbird # email
    signal-desktop # messaging
    kotatogram-desktop # telegram
    caprine-bin # messenger
    element-desktop # matrix
    vesktop # discord
    vencord # discord
    nextcloud-client
    bitwarden-desktop
    zeal # documentation
    zathura # PDF
    calibre # eBooks
    foliate # eBook reader
    librum # Library manager
    koreader # eBook reader

    # --- Terminal Emulators & Multiplexers ---
    ghostty
    kitty
    alacritty
    foot
    wezterm
    warp-terminal
    zellij
    tmux

    # --- Fun & Aesthetics ---
    fastfetch
    neofetch
    asciinema # terminal recorder
    cmatrix
    cbonsai
    sl # steam locomotive
    fortune
    toilet
    figlet
    neo-cowsay
    lavat
    blahaj # essential
    inputs.awww.packages.${pkgs.system}.awww

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
    papirus-icon-theme
    dracula-icon-theme
    kora-icon-theme
    candy-icons
    sweet-folders
    adwaita-icon-theme
    bibata-cursors
    capitaine-cursors
    rose-pine-hyprcursor
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    pywalfox-native
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
