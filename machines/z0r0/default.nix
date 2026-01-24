{ ... }:
{
  imports = [
    # Clan already provides facter support - just set facter.reportPath below
    ../../modules/nixos/default.nix
    ../../modules/nixos/system/laptop.nix
    ../../modules/Desktop-env/default.nix
    ../../modules/users/t0psh31f.nix
  ];

  # Hardware detection via facter.json (clan auto-discovers this)
  # fileSystems must be defined manually (facter doesn't handle this)

  # Boot configuration
  boot.initrd.luks.devices."crypted".device =
    "/dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f";

  # Filesystems (btrfs subvolumes)
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@root" ];
  };
  fileSystems."/var/log" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@log" ];
  };
  fileSystems."/nix" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };
  fileSystems."/persist" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@persist" ];
  };
  fileSystems."/backup" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@backup" ];
  };
  fileSystems."/home" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E6FA-59AC";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap Configuration
  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 16384; # 16GB
    }
  ];

  # Keep this to prevent auto-detection of broken swap partitions
  boot.kernelParams = [ "systemd.swap=0" ];

  networking.hostName = "z0r0";

  # ============================================================================
  # DESKTOP ENVIRONMENT SELECTION
  # ============================================================================

  desktop.dankmaterialshell = {
    enable = true;
    backend = "hyprland";
  };

  desktop.omarchy = {
    enable = false;
    backend = "both";
  };

  desktop.caelestia = {
    enable = false;
    backend = "both";
  };

  desktop.illogical.enable = false;

  # ============================================================================
  # THEMES
  # ============================================================================

  themes.sddm-lain.enable = false;
  themes.sddm-sel = {
    enable = true;
    variant = "shaders"; # Options: "shaders" (with effects) or "basic" (lighter)
  };
  themes.grub-lain.enable = true;
  themes.plymouth-hellonavi = {
    enable = true;
    # color = "red"; # Match Lain theme aesthetic
  };

  # ============================================================================
  # MOBILE DEVICE SUPPORT
  # ============================================================================
  mobile.android.enable = true;
  mobile.ios.enable = true;

  # ============================================================================
  # GAMING & VIRTUALIZATION
  # ============================================================================

  gaming.enable = true;
  virtualization.enable = true;

  # ============================================================================
  # SYSTEM
  # ============================================================================

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";

  # Sops configuration
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

  # Enable Impermanence
  system-config.impermanence.enable = true;

  # Optimized for 12th Gen Intel (4P + 8E = 12 Cores / 16 Threads)
  # Leave some headroom for system responsiveness
  nix.settings.cores = 4; # Cores per build job
  nix.settings.max-jobs = 4; # Total parallel build jobs (reduced to prevent OOM)

  # Vicinae cachix cache (requires NOT following nixpkgs in flake input)
  nix.settings.extra-substituters = [ "https://vicinae.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
  ];

  # ============================================================================
  # SERVICES
  # ============================================================================
  services.home-assistant-server.enable = true;
  services.caddy-server.enable = true;
  services.sillytavern-app.enable = false; # Disabled - Docker container failing

  services.ai-services = {
    enable = true; # Enables PostgreSQL vector DB
    open-webui.enable = true; # Interface
    localai.enable = true; # Local inference
    chromadb.enable = true; # Vector DB
  };

  # Media & Cloud
  services.immich-server.enable = true;
  services.calibre-web-app.enable = true;
  services.nextcloud-server.enable = true;
  services-config.media-stack.enable = false; # Disabled - Prowlarr STATE_DIRECTORY issue

  # Fix for missing Aria2 secret (required when RPC is enabled)
  services.aria2.rpcSecretFile = "/etc/aria2-rpc-token";
  environment.etc."aria2-rpc-token" = {
    text = "temporary-secret-change-me";
    mode = "0400";
    user = "media"; # Matches media-stack user
    group = "media";
  };

  # Fix for missing Deluge auth file (required for declarative config)
  services.deluge.authFile = "/etc/deluge-auth";
  environment.etc."deluge-auth" = {
    text = "localclient:a7c6f0e3bc4:10"; # Dummy credentials
    mode = "0400";
    user = "media";
    group = "media";
  };

  # Communication
  services.matrix-server.enable = true;
  services.mautrix-bridges.enable = true; # Base enablement
  services-config.avahi.enable = true; # mDNS

  # Monitoring
  services-config.monitoring.enable = false; # Disabled - Promtail NAMESPACE issue

  # Dashboard
  services-config.homepage-dashboard.enable = true;

  # n8n Automation
  services.n8n-server.enable = true;

  # ============================================================================
  # SECURITY / ACME
  # ============================================================================
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@grandlix.com"; # Placeholder for Let's Encrypt via config if needed, or use placeholder
  };
}
