{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # ============================================================================
  # GLOBAL SETTINGS
  # ============================================================================
  users.mutableUsers = false;

  # Workaround for nixpkgs unstable broken symlinks in util-linux.bin
  security.wrappers.mount.source = lib.mkForce "${pkgs.util-linuxMinimal}/bin/mount";
  security.wrappers.umount.source = lib.mkForce "${pkgs.util-linuxMinimal}/bin/umount";

  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];

  _module.args.osConfig = config;

  _module.args.lib = lib.extend (
    _final: _prev: {
      hm = inputs.home-manager.lib.hm;
    }
  );

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
  };

  # ============================================================================
  # SYSTEM CORE CONFIGURATION
  # ============================================================================
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "beekeeper-studio-5.5.7"
    "olm-3.2.16"
    "nodejs-20.20.2"
    "nodejs-slim-20.20.2"
    "webull-desktop-9.3.0"
    "electron-40.10.5"
    "electron-41.10.3"
    "electron-41.10.6"
    "pnpm-10.29.2"
  ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 15; # Increased from 10 for more rollback room
      };
      efi.canTouchEfiVariables = true;
    };

    blacklistedKernelModules = [
      "8250"
      "8250_pci"
      "serial_core"
    ];
    initrd = {
      systemd.enable = true;
      compressor = "zstd";
    };
  };

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
    enable = true; # Re-enabled: was disabled entirely, now provides docs
    nixos.enable = true; # Re-enabled: NixOS manual
    man.enable = true; # Re-enabled: man pages are essential for CLI work
    info.enable = false; # Keep disabled: rarely used
    doc.enable = false; # Keep disabled: rarely used
  };

  # ============================================================================
  # PACKAGES & TOOLS (Minimal System-level)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Boot/System essentials
    curl
    git
    vim
    wget
    ghostty.terminfo
  ];

  programs.zsh.enable = true;

  # system.checks: Re-enabled. The previous lib.mkForce [] silenced ALL NixOS
  # config validation (broken symlinks, config errors, etc). The original issue
  # was a broken check-sshd-config.drv / sandbox PAM link error which should be
  # fixed at the source, not by disabling all checks. If a specific check fails,
  # scope the override to that single check instead of nuking everything.
  # system.checks = lib.mkForce [ ];  # REMOVED: see above

  # Root password: managed by Clan core users module
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg4e32XqA2CyYsHyl+urGN1Soiz00DLgc+dkDw/uFCw luffy@agentaflow.com"
    ];
  };
}
