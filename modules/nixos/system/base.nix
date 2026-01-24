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

  services.tailscale.enable = true;

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
