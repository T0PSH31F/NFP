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

      # System directories to persist
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"

        # Database
        "/var/lib/postgresql"

        # Network
        "/etc/NetworkManager/system-connections"

        # Virtualization/Containers (System level)
        "/var/lib/libvirt"
        "/etc/libvirt"
        "/var/lib/docker"
        "/var/lib/podman"

        # SSH daemon keys
        "/etc/ssh"
      ];

      # Individual files to persist
      # Note: /etc/machine-id is managed separately (symlink to /.host-etc/machine-id)
      # If you need impermanence to manage it, remove the symlink first
      files = [
        "/etc/nix/id_rsa"
      ];

      # User-specific persistence (handled separately)
      users.t0psh31f = {
        directories = [
          # User Data
          "Agents"
          "Clan"
          "Documents"
          "Downloads"
          "Music"
          "NixOS"
          "Pictures"
          "Projects"
          "Public"
          "Templates"
          "Videos"

          # Custom User Data
          "Games"
          "Flatpaks"
          "Appimages"
          "Notes"

          # Configs & State
          ".icons"
          ".themes"
          ".cursors"
          ".ssh"
          ".gnupg"
          ".pki"
          ".mozilla"
          ".thunderbird"
          ".background" # Wallpaper storage
          ".antigravity"
          ".cache"
          ".gemini"
          ".kodi"
          ".vscode"

          # Specific App Configs (Add more as needed)
          ".config/ghostty"
          ".config/sops"
          ".config/Signal"
          ".config/TelegramDesktop"
          ".config/Antigravity"
          ".config/mcp"
          ".config/Bitwarden"
          ".config/obs-studio"
          ".config/vesktop"
          ".config/discord"
          ".config/spicetify"
          ".config/noctalia"
          ".local/share/noctalia"
          ".cache/noctalia"

          # Mobile / Sync
          ".kde/share/config/kdeconnect"
          ".config/kdeconnect"

          # Application data
          ".var/app" # Flatpak
        ];

        files = [
          ".bash_history"
          ".zsh_history"
          "facter.json"
        ];
      };
    };

    # ============================================================================
    # BTRFS ROOT & HOME WITH SNAPSHOT ROLLBACK
    # ============================================================================
    # Both / and /home are handled by disko.nix (@root and @home subvolumes)
    # The postDeviceCommands below will roll them back on each boot
    # This provides full impermanence (determinate builds)

    # Btrfs snapshot rollback for impermanence (Systemd Initrd Version)
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root and home snapshots";
      wantedBy = [ "initrd.target" ];
      after = [ "initrd-root-device.target" ];
      before = [ "sysroot.mount" ];
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
