{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Use centralized helper
  inherit (config.clan.lib) hasTag;
in
{
  imports = [
    ./tags.nix
    ./lib.nix
  ];

  config = lib.mkMerge [

    # ======================================================
    # AI Services (tags: ai-server, ai-heavy)
    # ======================================================
    (lib.mkIf (hasTag "ai-server") {
      services.ollama = {
        enable = true;
        package =
          if hasTag "nvidia" then
            pkgs.ollama-cuda
          else if hasTag "amd-gpu" then
            pkgs.ollama-rocm
          else
            pkgs.ollama;
        home = "/var/lib/ollama";
      };

      systemd.services.ollama.serviceConfig = lib.mkIf (hasTag "server") {
        MemoryMax = "8G";
        CPUQuota = "400%";
      };

      networking.firewall.allowedTCPPorts = [ 11434 ];
    })

    # ======================================================
    # Binary Cache (tag: binary-cache)
    # ======================================================
    (lib.mkIf (hasTag "binary-cache") {
      services.harmonia = {
        enable = true;
        signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
        settings = {
          bind = "[::]:5000";
          workers = 4;
          max_connection_rate = 256;
          priority = 50;
        };
      };

      networking.firewall.allowedTCPPorts = [ 5000 ];
    })

    # ======================================================
    # Database Services (tag: database)
    # ======================================================
    (lib.mkIf (hasTag "database") {
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        authentication = ''
          host all all 127.0.0.1/32 scram-sha-256
          host all all ::1/128 scram-sha-256
        '';
      };

      services.redis.servers."" = {
        enable = true;
        bind = "127.0.0.1";
        port = 6379;
      };
    })

    # ======================================================
    # Media Server (tag: media-server)
    # ======================================================
    (lib.mkIf (hasTag "media-server") {
      # Assuming services-config.media-stack is your custom module
      services-config.media-stack.enable = true;

      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };
    })

    # ======================================================
    # Download Management (tag: download-server)
    # ======================================================
    (lib.mkIf (hasTag "download-server") {
      services.radarr = {
        enable = true;
        openFirewall = true;
      };

      services.sonarr = {
        enable = true;
        openFirewall = true;
      };

      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };

      # qBittorrent via OCI container
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        ports = [
          "8080:8080"
          "6881:6881"
          "6881:6881/udp"
        ];
        volumes = [
          "/srv/media/downloads:/downloads"
          "/etc/qbittorrent:/config"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Los_Angeles";
        };
      };
    })

    # ======================================================
    # Desktop Services (tag: desktop)
    # ======================================================
    (lib.mkIf (hasTag "desktop") {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # UWSM for session management (waylandCompositors defined in packages/desktop/hyprland.nix)
      programs.uwsm.enable = true;

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      # Audio stack
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };

      # Desktop utilities
      programs.dconf.enable = true;
      services.udisks2.enable = true;
      services.gvfs.enable = true;
    })

    # ======================================================
    # Gaming Services (tag: gaming)
    # ======================================================
    (lib.mkIf (hasTag "gaming") {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };

      programs.gamemode.enable = true;
    })

    # ======================================================
    # Server Hardening (tag: server)
    # ======================================================
    (lib.mkIf (hasTag "server") {
      services.openssh = {
        enable = true;
        settings = {
          # PermitRootLogin = "no";
          # PasswordAuthentication = false;
        };
      };

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
      };

      # Disable unnecessary services on servers
      services.xserver.enable = lib.mkForce false;
      hardware.graphics.enable = lib.mkForce false;
      fonts.fontconfig.enable = lib.mkForce false;
      documentation.enable = lib.mkForce false;
    })

    # ======================================================
    # Build Server Optimizations (tag: build-server)
    # ======================================================
    (lib.mkIf (hasTag "build-server") {
      nix.settings = {
        # Higher priority for builds on build server
        trusted-users = [
          "root"
          "@wheel"
        ];
        max-jobs = 8;
        cores = 0; # Use all cores
      };

      systemd.services.nix-daemon.serviceConfig = {
        CPUQuota = "800%"; # 8 cores
        MemoryMax = "12G";
      };
    })
    # ======================================================
    # Base System Services (tag: base - implied for all)
    # ======================================================
    # Note: Effectively enabled for all machines via base module logic or here
    # Tailscale is critical for networking
    {
      services.tailscale.enable = true;
    }

    # ======================================================
    # Desktop Enhancements (tag: desktop)
    # ======================================================
    (lib.mkIf (hasTag "desktop") {
      # AppImage Support
      programs.appimage-support.enable = true;

      # Flatpak Support
      services.flatpak.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      };

      # File Managers
      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
          thunar-media-tags-plugin
        ];
      };
      services.tumbler.enable = true; # Thumbnail support

      environment.systemPackages = with pkgs; [
        # Nemo File Manager
        nemo-with-extensions
        nemo-fileroller
        # Dolphin File Manager (KDE)
        kdePackages.dolphin
        kdePackages.dolphin-plugins
        kdePackages.kio-extras
        kdePackages.kio-admin
        # Archive Manager
        file-roller
        # Terminal file managers
        lf
        yazi
        superfile
      ];
    })
  ];
}
