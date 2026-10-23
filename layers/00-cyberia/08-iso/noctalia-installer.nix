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
    ../../10-system/11-foundation/fonts.nix
  ];

  # ISO metadata
  image.fileName = "noctalia-recovery-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage = {
    volumeID = "NOCTALIA_RECOVERY";
    squashfsCompression = "zstd -Xcompression-level 15";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.forceImportRoot = false;

  # Include desktop environment components
  programs.hyprland.enable = true;

  # Network tools
  networking = {
    wireless.enable = lib.mkForce false;
    networkmanager.enable = true;
    hostName = "noctalia-recovery";
  };

  # Auto-login to nixos user via greetd into Hyprland
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "nixos";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.hyprland}/bin/Hyprland";
        user = "greeter";
      };
    };
  };

  # Installer user setup
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "disk"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Pentest and recovery tools suite
  environment.systemPackages = with pkgs; [
    # Desktop & Terminal
    kitty
    firefox

    # Network scanning & analysis
    nmap
    masscan
    rustscan
    wireshark
    tcpdump
    ettercap

    # Wireless
    aircrack-ng
    wifite2
    reaverwps-t6x
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

    # Exploitation & Forensics
    metasploit
    exploitdb
    sleuthkit
    volatility3

    # Utilities
    netcat
    socat
    proxychains
    tor

    # System & Editor
    vim
    git
    curl
    wget
    htop
    tree
    tmux

    # Disk & Filesystem recovery
    gparted
    parted
    btrfs-progs
    cryptsetup
    dosfstools
    e2fsprogs

    # NixOS tools
    nixos-install-tools
  ];

  # Allow unfree packages (burpsuite, unfree firmware, etc.)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
