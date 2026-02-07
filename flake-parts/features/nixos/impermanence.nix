{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options.system-config.impermanence = {
    enable = mkEnableOption "NixOS impermanence (ephemeral root)";

    persistPath = mkOption {
      type = types.str;
      default = "/persist";
      description = "Path to persistent storage";
    };
  };

  config = mkIf config.system-config.impermanence.enable {
    # ============================================================================
    # ENVIRONMENT PERSISTENCE
    # ============================================================================
    environment.persistence.${config.system-config.impermanence.persistPath} = {
      hideMounts = true;

      directories = [
        # System directories
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/log"
        
        # Network configuration
        "/etc/NetworkManager/system-connections"
        
        # AI services
        "/var/lib/ollama"
        "/var/lib/localai"
        "/var/lib/chromadb"
        "/var/lib/qdrant"
        
        # Databases
        "/var/lib/postgresql"
        "/var/lib/mysql"
        "/var/lib/redis"
        
        # Communication
        "/var/lib/matrix-synapse"
        
        # Cloud & Storage
        "/var/lib/nextcloud"
        
        # Home automation
        "/var/lib/home-assistant"
        
        # Automation
        "/var/lib/n8n"
        
        # Web servers
        "/var/lib/caddy"
        
        # Media services
        "/var/lib/immich"
        "/var/lib/calibre-web"
        "/var/lib/jellyfin"
        "/var/lib/plex"
        
        # Download clients
        "/var/lib/deluge"
        "/var/lib/transmission"
        "/var/lib/aria2"
        
        # *arr suite
        "/var/lib/sonarr"
        "/var/lib/radarr"
        "/var/lib/lidarr"
        "/var/lib/readarr"
        "/var/lib/prowlarr"
        
        # VPN & networking
        "/var/lib/headscale"
        "/var/lib/tailscale"
        
        # Binary cache
        "/var/lib/harmonia"
        
        # Monitoring
        "/var/lib/grafana"
        "/var/lib/prometheus"
        
        # Containers
        "/var/lib/docker"
        "/var/lib/containers"
        "/var/lib/podman"
        
        # Virtualization
        "/var/lib/libvirt"
        "/etc/libvirt"
        
        # SSH daemon
        "/etc/ssh"
      ];
      
      files = [
        # Machine identity
        "/etc/machine-id"
        
        # SOPS age key
        "/var/lib/sops-nix/key.txt"
      ];
      
      # Per-user persistence
      users.t0psh31f = {
        directories = [
          # Projects and work
          "Clan"
          "projects"
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"
          
          # Configuration
          ".config"
          ".local"
          
          # SSH & GPG
          ".ssh"
          ".gnupg"
          
          # Development caches
          ".cache"
          
          # Browser profiles (if needed)
          ".mozilla"
          ".config/chromium"
          
          # VS Code / editors
          ".vscode"
          ".config/Code"
          
          # Shell history & state
          ".local/share/fish"
          ".local/share/zsh"
          
          # AI tool data
          ".ollama"
          ".config/cherry-studio"
          ".config/lmstudio"

          # Legacy/Custom User Data (Preserved)
          "Agents"
          "NixOS"
          "Public"
          "Templates"
          "Games"
          "Flatpaks"
          "Appimages"
          "Notes"
          ".icons"
          ".themes"
          ".cursors"
          ".pki"
          ".thunderbird"
          ".background" 
          ".antigravity"
          ".gemini"
          ".kodi"
          ".var/app"
        ];
        
        files = [
          # Shell history
          ".bash_history"
          ".zsh_history"
          
          # Git configuration
          ".gitconfig"
          "facter.json"
        ];
      };
    };

    # Ensure proper permissions for service directories
    systemd.tmpfiles.rules = [
      # AI services
      "d /persist/var/lib/ollama 0750 ollama ollama"
      "d /persist/var/lib/localai 0750 localai localai"
      "d /persist/var/lib/chromadb 0750 chromadb chromadb"
      
      # Databases
      "d /persist/var/lib/postgresql 0750 postgres postgres"
      "d /persist/var/lib/redis 0750 redis redis"
      
      # Communication
      "d /persist/var/lib/matrix-synapse 0750 matrix-synapse matrix-synapse"
      
      # Cloud
      "d /persist/var/lib/nextcloud 0750 nextcloud nextcloud"
      
      # Home Assistant
      "d /persist/var/lib/home-assistant 0750 hass hass"
      
      # n8n
      "d /persist/var/lib/n8n 0750 n8n n8n"
      
      # Web server
      "d /persist/var/lib/caddy 0750 caddy caddy"
      
      # Media
      "d /persist/var/lib/immich 0750 immich immich"
      "d /persist/var/lib/calibre-web 0750 calibre-web calibre-web"
      
      # Downloads
      "d /persist/var/lib/deluge 0750 deluge deluge"
      "d /persist/var/lib/transmission 0750 transmission transmission"
      "d /persist/var/lib/aria2 0750 aria2 aria2"
      
      # Binary cache
      "d /persist/var/lib/harmonia 0750 harmonia harmonia"
      
      # Containers
      "d /persist/var/lib/docker 0710 root root"
      
      # User home persistence
      "d /persist/home/t0psh31f 0700 t0psh31f users"
      "d /persist/home/t0psh31f/.ssh 0700 t0psh31f users"
      "d /persist/home/t0psh31f/.gnupg 0700 t0psh31f users"
    ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        export PATH=${pkgs.btrfs-progs}/bin:$PATH
        mkdir -p /mnt
        mount -t btrfs -o subvol=/ ${config.fileSystems."/".device} /mnt

        # Rollback @root
        if [[ ! -e /mnt/@root-blank ]]; then
            btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
        fi
        btrfs subvolume delete /mnt/@root
        btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

        # Rollback @home
        if [[ ! -e /mnt/@home-blank ]]; then
            btrfs subvolume snapshot -r /mnt/@home /mnt/@home-blank
        fi
        btrfs subvolume delete /mnt/@home
        btrfs subvolume snapshot /mnt/@home-blank /mnt/@home

        umount /mnt
      '';
    };

    # ============================================================================
    # ADDITIONAL CONFIGURATION
    # ============================================================================
    # Mark persistent storage as needed for boot
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;

    # Ensure /persist exists and is mounted before activation
    systemd.tmpfiles.rules = [
      "d ${config.system-config.impermanence.persistPath} 0755 root root -"
    ];

    # Activation script to ensure persistence dirs exist with correct permissions
    system.activationScripts.ensurePersistenceDirs = {
      text = ''
        mkdir -p /persist/home/t0psh31f/.local/share/noctalia
        mkdir -p /persist/home/t0psh31f/.cache/noctalia
        mkdir -p /persist/etc/libvirt
        chown -R t0psh31f:users /persist/home/t0psh31f/.local/share 2>/dev/null || true
        chown -R t0psh31f:users /persist/home/t0psh31f/.cache 2>/dev/null || true
      '';
      deps = [ ];
    };
  };
}
