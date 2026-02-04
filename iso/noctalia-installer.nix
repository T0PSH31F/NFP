{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ISO metadata
  isoImage = {
    isoName = "noctalia-installer-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = "NOCTALIA_INSTALLER";
    squashfsCompression = "zstd -Xcompression-level 15";
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Include desktop environment components
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
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

  # Installer user setup
  users.users.t0psh31f = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    hashedPassword = "$6$WbMMiboG5lnMx4Ok$.RCZzi7GUXpt0gqsdgHL3jnke5OgCfdoOpErWxZ9/2oJj/guc5zZRYPBYzcBkV/929cwSIno/4RtW0Rfz8GCy/";
  };

  # Allow unfree packages (for some pentest tools)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
