{
  pkgs,
  ...
}:
{
  # ============================================================================
  # SYSTEM CORE CONFIGURATION
  # ============================================================================

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 2; # Aggressive limit to prevent /boot bloat
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.compressor = "zstd";

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

  services.tailscale.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Speed up builds and slim down system by disabling documentation
  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
  };

  # ============================================================================
  # PACKAGES & TOOLS (Minimal System-level)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Boot/System essentials
    vim
    wget
    curl
    git
    pciutils
    usbutils

    # Container runtime for services
    docker
    docker-compose
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
      # User requested Nerd Fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.gohufont

      inter # Lighter replacement for Google Fonts meta-package
      powerline-symbols
      twemoji-color-font
      material-design-icons
      source-code-pro
      source-serif-pro
      source-sans-pro
      creep
      pixel-code
      tamzen
      tamsyn
      font-awesome
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "pixel-code"
          "Source Serif Pro"
        ];

        sansSerif = [
          "Inter"
          "FiraCode Nerd Font"
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
