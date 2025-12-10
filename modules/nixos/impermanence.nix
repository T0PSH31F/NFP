{
  config,
  lib,
  inputs,
  ...
}:
with lib; {
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

      # System directories to persist
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"

        # Network
        "/etc/NetworkManager/system-connections"

        # Services
        "/var/lib/docker"
        "/var/lib/podman"
        "/var/lib/libvirt"
        "/var/lib/postgresql"
        "/var/lib/redis"
        "/var/lib/grafana"
        "/var/lib/prometheus2"
        "/var/lib/loki"
        "/var/lib/private/promtail"

        # Media stack
        "/var/lib/media"
        "/var/lib/sonarr"
        "/var/lib/radarr"
        "/var/lib/prowlarr"
        "/var/lib/lidarr"
        "/var/lib/readarr"
        "/var/lib/bazarr"
        "/var/lib/deluge"
        "/var/lib/aria2"

        # AI Services
        "/var/lib/ollama"
        "/var/lib/qdrant"

        # Communication
        "/var/lib/matrix-synapse"
        "/var/lib/mautrix-telegram"
        "/var/lib/mautrix-whatsapp"
        "/var/lib/mautrix-signal"

        # Cloud services
        "/var/lib/nextcloud"
        "/var/lib/immich"
        "/var/lib/calibre-web"
        "/var/lib/home-assistant"

        # SSH daemon keys
        "/etc/ssh"
      ];

      # Individual files to persist
      files = [
        "/etc/machine-id"
        "/etc/nix/id_rsa"
      ];

      # User-specific persistence (handled separately)
      users.t0psh31f = {
        directories = [
          "Appimages"
          "Desktop"
          "Downloads"
          "Documents"
          "Flatpaks"
          "Games"
          "MCP"
          "Music"
          "nix-ai-help"
          "Notes"
          "Pictures"
          "Public"
          "Templates"
          "Videos"
          ".ssh"
          ".gnupg"
          ".config"
          ".local"
          ".cache"
          ".antigravity"
          "74daf1 nextdns id"

          # Development
          "Clan"
          "Projects"

          # Application data
          ".mozilla"
          ".thunderbird"
          ".var/app" # Flatpak
        ];

        files = [
          ".bash_history"
          ".zsh_history"
        ];
      };
    };

    # ============================================================================
    # ============================================================================
    # BTRFS ROOT WITH SNAPSHOT ROLLBACK
    # ============================================================================
    # Root filesystem is handled by disko.nix (@root subvolume)
    # The postDeviceCommands below will roll it back to @root-blank on each boot
    # This provides impermanence without tmpfs

    # ============================================================================
    # BOOT OPTIMIZATION
    # ============================================================================
    # ============================================================================
    # BTRFS ROOT WITH SNAPSHOT ROLLBACK
    # ============================================================================
    # Root is on btrfs @root subvolume (mounted via disko)
    # The postDeviceCommands will roll it back to @root-blank snapshot on boot
    # No need to define "/" here - disko handles it via @root subvolume

    # Disable systemd stage 1 initrd to allow postDeviceCommands
    # This is required for btrfs snapshot rollback functionality
    boot.initrd.systemd.enable = lib.mkForce false;

    # Btrfs snapshot rollback for impermanence
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      # Create blank snapshot if it doesn't exist
      if [[ ! -e /mnt/@root-blank ]]; then
          btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
      fi

      # Delete the root subvolume
      btrfs subvolume delete /mnt/@root || true

      # Restore root subvolume from blank snapshot
      btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

      # Cleanup
      umount /mnt
    '';

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
  };
}
