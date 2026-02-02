{
  ...
}:
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  imports = [
    ../../modules/nixos/default.nix
    ../../modules/nixos/system/laptop.nix
    ../../modules/Home-Manager/Desktop-env/default.nix
    ../../modules/Home-Manager/Desktop-env/Noctalia/default.nix
    ../../modules/users/t0psh31f.nix
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
  # FEATURE TOGGLES (Dendritic Pattern - Nested Attrsets)
  # ============================================================================

  # System features
  nix-tools.enable = true;
  desktop-portals.enable = true;

  # Desktop environments
  desktop = {
    noctalia = {
      enable = true;
      backend = "hyprland";
      #backend = "niri"
      #backend = "both"
    };
  };
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
  gaming.enable = true;
  virtualization.enable = true;

  # Flatpak & AppImage
  flatpak.enable = true;
  programs.appimage-support.enable = true;

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
  # HOME-MANAGER CONFIGURATION
  # ============================================================================

  home-manager.users.t0psh31f = {
    # Home-Manager programs
    programs = {
      yazelix.enable = true;
      keybind-cheatsheet.enable = true;
      pentest.enable = false;
      vicinae.enable = true;
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
      sillytavern.enable = true; # Moved from sillytavern-app
      # Local inference
      localai.enable = true;
      ollama.enable = false; # Enable when you have GPU acceleration
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
