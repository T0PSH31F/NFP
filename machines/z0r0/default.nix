{
  lib,
  inputs,
  ...
}:
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  imports = [
    ../../modules/nixos/default.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/overlays.nix
    ../../modules/clan/tags.nix
    ../../modules/clan/lib.nix
    ../../modules/clan/metadata.nix
    ../../modules/clan/service-distribution.nix
    ../../modules/clan/secrets.nix
    ../../packages/default.nix
    ../../modules/nixos/system/laptop.nix
    ../../modules/nixos/hardware/intel-12th-gen.nix
    ../../modules/users/t0psh31f.nix
  ];

  # ... (middle of file skipped) ...

  # ============================================================================
  # HOME-MANAGER CONFIGURATION
  # ============================================================================

  # ============================================================================
  # HARDWARE CONFIGURATION
  # ============================================================================

  # Boot configuration
  boot.initrd = {
    luks.devices."crypted".device = "/dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f";
  };

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
    neededForBoot = true;
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
    neededForBoot = true;
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
  # FEATURE TOGGLES (Dendritic Pattern - Nested Attrsets)
  # ============================================================================

  # System features
  nix-tools.enable = true;
  desktop-portals.enable = true;

  # Themes
  themes = {
    sddm-lainframe.enable = true;
    sddm-lain.enable = false;
    sddm-sel = {
      enable = false;
      variant = "shaders";
    };
    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };

  # Mobile device support
  mobile = {
    android.enable = true;
    ios.enable = true;
  };

  # Gaming & Virtualization
  gaming.enable = false;
  virtualization.enable = true;

  # Flatpak & AppImage
  flatpak.enable = true;
  # programs.appimage-support.enable = true; # Moved to service-distribution.nix

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================

  # Sops secrets management
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

  # Impermanence
  system-config.impermanence.enable = true;

  # Tag z0r0 as desktop + AI + build + cache + DB + dev + pentest
  clan.tags = [
    "desktop"
    "laptop"
    "ai-server"
    "build-server"
    "binary-cache"
    "database"
    "dev"
    # "pentest"
  ];

  # Nix settings are now managed in modules/nixos/nix-settings.nix
  # z0r0 specific overrides can be added here if needed, but the defaults are 4 jobs / 2 cores.

  # ============================================================================
  # HOME-MANAGER CONFIGURATION
  # ============================================================================

  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.t0psh31f = {
      imports = [ ../../modules/home ];
      # Home-Manager programs
      programs = {
        yazelix.enable = true;
        #   keybind-cheatsheet.enable = true;
        #   pentest.enable = false;
        vicinae.enable = true;
      };
    };
  };

  # ============================================================================
  # SERVICE TOGGLES (Dendritic Pattern - Nested Attrsets)
  # ============================================================================

  services = {
    # Desktop Services
    ssh-agent.enable = true;
    searxng.enable = true; # Optional: Enable SearxNG metasearch
    pastebin.enable = true; # Optional: Enable PrivateBin
    # harmonia.enable = true; # Managed by service-distribution.nix via 'binary-cache' tag

    # Home Automation & Infrastructure
    home-assistant-server.enable = true;
    caddy-server.enable = true;
    n8n-server.enable = true;

    # AI Services - Granular toggles for each AI service
    llm-agents.enable = true;
    ai-services = {
      enable = true;
      # LLM Frontends
      open-webui.enable = true;
      # sillytavern.enable = true; # Moved to Clan Service
      # Local inference
      localai.enable = true;
      # ollama.enable = false; # Managed by service-distribution.nix via 'ai-server' tag
      # Vector databases
      chromadb.enable = true;
      qdrant.enable = false;
      # Desktop apps (conditional install)
      lmstudio.enable = true;
      jan.enable = true;
      cherry-studio.enable = true;
      aider.enable = true;
    };

    # Media & Cloud
    immich-server.enable = true;
    calibre-web-app.enable = true;
    nextcloud-server.enable = true;

    # Communication
    matrix-server.enable = true;
    mautrix-bridges.enable = true;

    # Extra Services (User Requested)
    glances-server.enable = true;
    filebrowser-app.enable = true;
    deluge-server.enable = true;
    transmission-server.enable = true;
    headscale-server.enable = true;

    # Service fixes (temporary workarounds)
    aria2.rpcSecretFile = "/etc/aria2-rpc-token";
    deluge.authFile = "/etc/deluge-auth";
  };

  # Services config (separate namespace for config-only services)
  services-config = {
    media-stack.enable = false; # DISABLED: Toggle on for *arr suite
    avahi.enable = true; # mDNS
    monitoring.enable = true; # Fixed - Promtail NAMESPACE issue resolved
    homepage-dashboard.enable = true;
  };

  # ============================================================================
  # ENVIRONMENT CONFIGURATION (Service support files)
  # ============================================================================

  # Aria2 RPC secret file
  environment.etc."aria2-rpc-token" = {
    text = "temporary-secret-change-me";
    mode = "0400";
    user = "media";
    group = "media";
  };

  # Deluge auth file
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
