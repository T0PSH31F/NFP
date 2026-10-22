{
  pkgs,
  lib,
  config,
  inputs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.sops-nix.nixosModules.sops
    # Import theme modules to allow consistent styling
    ../../30-environments/37-boot
    ../../10-system/11-foundation/fonts.nix
  ];

  sops.secrets."user-password-t0psh31f" = {
    sopsFile = ../vars/shared/user-password-t0psh31f/user-password-hash/secret;
    format = "json";
    key = "data";
  };

  # ISO metadata
  isoImage = {
    isoName = "noctalia-installer-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = "NOCTALIA_INSTALLER";
    squashfsCompression = "zstd -Xcompression-level 15";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Themes - match z0r0 for consistency
  themes = {
    sugar-dark = {
      enable = true;
      background = "${
        ./../../../layers/00-cyberia/02-assets/sddm_background/the-world-of-one-piece_800.gif
      }";
    };
    plymouth-hellonavi.enable = true;
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Include desktop environment components
  services.xserver.enable = true;
  # SDDM is already enabled by themes.sugar-dark.enable
  programs.hyprland.enable = true;

  # Network tools
  networking = {
    wireless.enable = lib.mkForce false;
    networkmanager.enable = true;
  };

  # Pentest tools suite
  environment.systemPackages = with pkgs; [
    # Desktop
    kitty
    firefox

    # Network scanning
    nmap
    masscan
    rustscan

    # Wireless
    aircrack-ng
    wifite2
    reaver
    bully

    # Password cracking
    hashcat
    john
    hydra

    # Web security
    burpsuite
    sqlmap
    nikto
    wpscan
    dirb

    # Exploitation
    metasploit
    exploitdb

    # Forensics
    # autopsy # Can be large/heavy, omitting or use specific nixpkgs if needed
    sleuthkit
    volatility3

    # Sniffing
    wireshark
    tcpdump
    ettercap

    # Utilities
    netcat
    socat
    proxychains
    tor

    # System tools
    vim
    git
    curl
    wget
    htop
    tree
    tmux

    # Disk tools
    gparted
    parted
    btrfs-progs
    cryptsetup

    # NixOS tools
    nixos-install-tools
  ];

  # Auto-login to installer user
  services.displayManager.autoLogin = {
    enable = true;
    user = "t0psh31f";
  };
  services.displayManager.defaultSession = "hyprland";

  # Installer user setup
  users.users.t0psh31f = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    hashedPasswordFile = config.sops.secrets."user-password-t0psh31f".path;
  };

  # Allow unfree packages (for some pentest tools)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
