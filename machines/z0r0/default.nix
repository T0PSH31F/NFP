{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  imports = [
    ../../modules/nixos/default.nix
    ../../modules/nixos/system/laptop.nix
    ../../modules/nixos/system/desktop-portals.nix
    ../../modules/Desktop-env/default.nix
    ../../modules/Desktop-env/Noctalia/default.nix
    ../../modules/users/t0psh31f.nix
    ../../clan-service-modules/desktop/ssh-agent.nix
  ];

  # ============================================================================
  # HARDWARE CONFIGURATION
  # ============================================================================
  
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
      size = 32768; # 32GB
    }
  ];

  # Keep this to prevent auto-detection of broken swap partitions
  boot.kernelParams = [ "systemd.swap=0" ];

  networking.hostName = "z0r0";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";

  # ============================================================================
  # FEATURE TOGGLES (Dendritic Pattern)
  # ============================================================================
  
  config = {
    nix-tools.enable = true;
    desktop-portals.enable = true;
  };

  # Yazelix (Yazi + Helix integration)
  programs.yazelix.enable = true;

  # Keybind cheatsheet overlay
  programs.keybind-cheatsheet.enable = true;

  # ============================================================================
  # DESKTOP ENVIRONMENT
  # ============================================================================

  # Noctalia Shell (Primary DE)
  desktop.noctalia = {
    enable = true;
    backend = "hyprland";
  };

  # Alternative DEs (disabled)
  desktop.dankmaterialshell.enable = false;
  desktop.omarchy.enable = false;
  desktop.caelestia.enable = false;
  desktop.illogical.enable = false;

  # ============================================================================
  # THEMES
  # ============================================================================

  themes = {
    sddm-lain.enable = false;
    sddm-sel = {
      enable = true;
      variant = "shaders";
    };
    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };

  # ============================================================================
  # MOBILE DEVICE SUPPORT
  # ============================================================================
  
  mobile = {
    android.enable = true;
    ios.enable = true;
  };

  # ============================================================================
  # GAMING & VIRTUALIZATION
  # ============================================================================

  gaming.enable = true;
  virtualization.enable = true;

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================

  # Sops secrets management
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

  # Impermanence
  system-config.impermanence.enable = true;

  # Nix settings (optimized for 12th Gen Intel: 4P + 8E = 12 Cores / 16 Threads)
  nix.settings = {
    cores = 4; # Cores per build job
    max-jobs = 4; # Total parallel build jobs (reduced to prevent OOM)
  };

  # ============================================================================
  # SERVICE TOGGLES (Dendritic Pattern)
  # ============================================================================

  # Desktop Services
  services.ssh-agent.enable = true;
  # services.searxng.enable = false; # Optional: Enable SearxNG metasearch
  # services.pastebin.enable = false; # Optional: Enable PrivateBin

  # Home Automation & Infrastructure
  services.home-assistant-server.enable = true;
  services.caddy-server.enable = true;
  services.n8n-server.enable = true;

  # AI Services
  services.sillytavern-app.enable = true;
  services.llm-agents.enable = true;
  services.ai-services = {
    enable = true;
    open-webui.enable = true;
    localai.enable = true;
    chromadb.enable = true;
  };

  # Media & Cloud
  services.immich-server.enable = true;
  services.calibre-web-app.enable = true;
  services.nextcloud-server.enable = true;
  services-config.media-stack.enable = false; # Disabled - Prowlarr STATE_DIRECTORY issue

  # Communication
  services.matrix-server.enable = true;
  services.mautrix-bridges.enable = true;
  services-config.avahi.enable = true; # mDNS

  # Monitoring
  services-config.monitoring.enable = false; # Disabled - Promtail NAMESPACE issue

  # Dashboard
  services-config.homepage-dashboard.enable = true;

  # ============================================================================
  # SERVICE FIXES (Temporary workarounds)
  # ============================================================================

  # Aria2 RPC secret
  services.aria2.rpcSecretFile = "/etc/aria2-rpc-token";
  environment.etc."aria2-rpc-token" = {
    text = "temporary-secret-change-me";
    mode = "0400";
    user = "media";
    group = "media";
  };

  # Deluge auth file
  services.deluge.authFile = "/etc/deluge-auth";
  environment.etc."deluge-auth" = {
    text = "localclient:a7c6f0e3bc4:10";
    mode = "0400";
    user = "media";
    group = "media";
  };

  # ============================================================================
  # SECURITY / ACME
  # ============================================================================
  
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@grandlix.com";
  };
}
