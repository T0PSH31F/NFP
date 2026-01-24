{
  pkgs,
  ...
}:
{
  # ============================================================================
  # SYSTEM CORE CONFIGURATION
  # ============================================================================

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Locale & Time
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        22 # Web/SSH
        5432
        6333
        6334
        8000
        8080
        8081 # AI Services
        8008
        8448
        9000 # Matrix
        29317
        29318
        29328 # Mautrix Bridges
        29319
        29320
        29327
        29330
        29334
        29335
        29336 # More Bridges
        8123
        2283
        8083 # HA, Immich, Calibre
        27036
        27037
        6379 # Steam, Redis
      ];
      allowedUDPPorts = [
        443 # QUIC
        27031
        27036 # Steam
        5353 # mDNS
      ];
      trustedInterfaces = [
        "tailscale0"
        "docker0"
        "podman0"
      ];
      allowPing = true;
    };
  };
  services.tailscale.enable = true;

  # ============================================================================
  # PACKAGES & TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Core Tools
    git
    vim
    wget
    curl
    htop
    tree
    zip
    unzip

    # Nix Tools
    alejandra
    nil
    nixfmt
    deadnix
    statix

    # CLI Utilities
    bat
    eza
    ripgrep
    fd
    fzf
    jq

    # Media
    feh

    # Font Manager
    font-manager
    bitwarden-desktop

    # Icon and Cursor Themes
    arashi
    papirus-icon-theme
    fairywren
    rose-pine-icon-theme
    dracula-icon-theme
    kora-icon-theme
    candy-icons
    sweet-folders
    kanagawa-icon-theme
    adwaita-icon-theme
    paper-icon-theme
    beauty-line-icon-theme
    nixos-icons
    reversal-icon-theme
    gnome-icon-theme
    bibata-cursors
    capitaine-cursors
    rose-pine-hyprcursor
    hyprviz
    waytrogen
    aircrack-ng
    macchanger
    ps_mem
    smem
  ];

  # Flatpak Support
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # ============================================================================
  # FONTS
  # ============================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.gohufont
      nerd-fonts.iosevka
      nerd-fonts.meslo-lg
      nerd-fonts.caskaydia-cove
      nerd-fonts.sauce-code-pro
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.victor-mono
      nerd-fonts.roboto-mono
      nerd-fonts.inconsolata
      nerd-fonts.dejavu-sans-mono
      powerline-fonts
      powerline-symbols
      twemoji-color-font
      material-design-icons
      material-icons
      material-symbols
      creep
      pixel-code
      tamzen
      tamsyn
      scientifica
      source-code-pro
      source-sans-pro
      source-serif-pro
      font-awesome
      font-awesome_5
      font-awesome_6
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "pixel-code"
          "Source Serif Pro"
        ];

        sansSerif = [
          "nerd-fonts.fira-code"
          "Source Sans Pro"
        ];

        monospace = [
          "JetBrainsMono Nerd Font"
          "FiraCode Nerd Font"
          "Source Code Pro"
        ];

        emoji = [
          "material-design-icons"
          "material-icons"
          "material-symbols"
          "powerline-symbols"
          "twemoji-color-font"
        ];

      };
    };
  };
}
