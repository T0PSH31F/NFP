{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # ============================================================================
  # SYSTEM CORE CONFIGURATION
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10; # Increased for more rollback room
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.blacklistedKernelModules = [
    "8250"
    "8250_pci"
    "serial_core"
  ];

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
    btop
    curl
    fd
    git
    gotree
    htop
    jq
    p7zip
    pciutils
    ripgrep
    tmux
    tree
    unzip
    usbutils
    vim
    wget
    zip

    # Container runtime for services
    docker
    docker-compose
  ];

  programs.zsh.enable = true;

  # Fallback root password - change immediately after first login with `passwd`
  users.users.root.hashedPassword = "$6$VRNKFZO5ZSa8uxSa$LFncLEfnLcQrIvOFJba89yRqxxavrJtuaDrO1O6Ods3uG8csVxCUpiHMQN1cwxgO/hIERux6PTAJIDYwdj77S/";
}
