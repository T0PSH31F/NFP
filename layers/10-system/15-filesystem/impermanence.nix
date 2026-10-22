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

  options.layers.layer-10.system.config.impermanence = {
    enable = mkEnableOption "NixOS impermanence (ephemeral root)";

    persistPath = mkOption {
      type = types.str;
      default = "/persist";
      description = "Path to persistent storage";
    };
  };

  config = mkIf config.layers.layer-10.system.config.impermanence.enable {
    # ============================================================================
    # ENVIRONMENT PERSISTENCE
    # ============================================================================
    environment.persistence.${config.layers.layer-10.system.config.impermanence.persistPath} = {
      hideMounts = true;

      directories = [
        # System directories
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/lib/hermes" # Hermes agent session DB + state

        # AI Services State — persisted across impermanence reboots
        # NOTE: /var/lib/brain-service is declared by
        # layers/70-agents/73-memory/brain-service.nix with its postgres:postgres
        # 0750 ownership. Listing it here too trips the NixOS "specified two or
        # more times" assertion.
        "/var/lib/postgresql" # PostgreSQL vectordb, brain-service DB, honcho DB

        # Network configuration
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"

        # Tailscale VPN identity (prevents new node key/IP on reboot)
        "/var/lib/tailscale"

        # AI Services State & Databases (declared modularly in respective service modules)
        "/var/lib/camofox" # Camofox persistent browser profiles & OAuth cookies

        # SSH host keys
        "/etc/ssh"
      ];

      files = [
        # Machine identity
        "/etc/machine-id"
      ];

      # Per-user persistence
      users.t0psh31f = {
        directories = [
          # Projects and work
          "Clan"
          "Projects"
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"

          # Configuration
          ".config"
          ".local"

          # SSH (GPG moved to XDG: .local/share/gnupg, covered by ".local")
          ".ssh"

          # NSS exception: libnss3 hardcodes ~/.pki/nssdb (no XDG override
          # exists); spotify/brave keep cert9.db/key4.db open here. XDG
          # migration 2026-10-10 deliberately keeps this path persisted.
          ".pki"

          # Development caches
          ".cache"

          # Shell history & state
          ".local/share/fish"
          ".local/share/zsh"

          # Legacy/Custom User Data
          # (XDG migration 2026-10-10: .gnupg/.mozilla/.icons/.themes/
          #  .claude/.codex/.kodi/.zsh_history moved under .config/ or
          #  .local/share/, which are persisted wholesale above. .pki is
          #  the documented NSS exception above.)
          "Agents"
          "Templates"
          "Games"
          "Appimages"
          "Notes"
          ".cursors"
          ".thunderbird"
          ".background"
          ".antigravity"
          ".gemini"
          ".opencode" # OpenCode local plugin data
          ".zeroclaw" # ZeroClaw logs + skills
          ".openclaw" # OpenClaw logs + skills
          ".kilocode" # KiloCode CLI state
          ".var/app"
          ".authsome"
        ];

        files = [
          # facter.json
          "facter.json"
        ];
      };
    };

    # Ensure proper permissions for core persistence directories
    systemd.tmpfiles.rules = [
      "d ${config.layers.layer-10.system.config.impermanence.persistPath} 0755 root root -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/etc 0755 root root -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/etc/ssh 0755 root root -"

      # User home persistence
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f 0700 t0psh31f users -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f/.ssh 0700 t0psh31f users -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f/.local/share/gnupg 0700 t0psh31f users -"

      # OpenCode local plugin data
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f/.opencode 0700 t0psh31f users -"

      # Noctalia state (moved from activationScripts)
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f/.local/share/noctalia 0700 t0psh31f users -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/home/t0psh31f/.cache/noctalia 0700 t0psh31f users -"

      # Skyvern automation data (subdirectories under the impermanence mount)
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/var/lib/skyvern/data 0755 root root -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/var/lib/skyvern/.skyvern 0700 root root -"

      # Hermes agent state (session DB, workspaces, homedir)
      # Must be 2770 (group-writable + setgid) so t0psh31f (hermes group) can
      # run `hermes auth`, `hermes --tui`, etc.  The hermes-agent NixOS module
      # also declares 2770 tmpfiles rules for /var/lib/hermes; these /persist
      # rules run *after* those, so they must match or they silently override.
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/var/lib/hermes 2770 hermes hermes -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/var/lib/hermes/.hermes 2770 hermes hermes -"
      "d ${config.layers.layer-10.system.config.impermanence.persistPath}/var/lib/hermes/workspace 2770 hermes hermes -"
    ];

    # Suppress sudo lecture on every boot
    security.sudo.extraConfig = "Defaults lecture = never";

    # ============================================================================
    # BTRFS ROOT & HOME WITH SNAPSHOT ROLLBACK
    # ============================================================================
    # Both / and /home are handled by disko.nix (@root and @home subvolumes)
    # The postDeviceCommands below will roll them back on each boot
    # This provides full impermanence (determinate builds)

    # Btrfs snapshot rollback for impermanence (Systemd Initrd Version)
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      # Wait for the LUKS device to be unlocked and udev to create the device mapper node
      wants = [ "dev-mapper-crypted.device" ];
      after = [
        "systemd-cryptsetup@crypted.service"
        "dev-mapper-crypted.device"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      path = [
        pkgs.btrfs-progs
        pkgs.coreutils
        pkgs.util-linuxMinimal
      ];
      script = ''
        ${pkgs.coreutils}/bin/mkdir -p /mnt

        # Explicitly wait up to 10 seconds for the udev node to be created
        for i in {1..10}; do
          if [ -e /dev/mapper/crypted ]; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done

        # Use the explicit device mapper path for the unlocked LUKS container
        ${pkgs.util-linuxMinimal}/bin/mount -o subvol=/ /dev/mapper/crypted /mnt

        # Ensure blank snapshot template exists on first boot
        if [ ! -e /mnt/@root-blank ]; then
          echo "Initial boot detected: creating /@root-blank snapshot template..."
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create /mnt/@root-blank
        fi

        # Delete nested subvolumes inside @root first to avoid "Directory not empty"
        # We sort by depth (descending) to ensure nested subvolumes are deleted first
        if [ -d /mnt/@root ]; then
          echo "Cleaning up nested subvolumes under /@root..."
          ${pkgs.btrfs-progs}/bin/btrfs subvolume list -o /mnt/@root | 
            ${pkgs.coreutils}/bin/cut -f 9- -d ' ' | 
            ${pkgs.coreutils}/bin/sort -r | 
            while read -r subvolume; do
              if [ -n "$subvolume" ]; then
                echo "deleting /$subvolume subvolume..."
                ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "/mnt/$subvolume"
              fi
            done
          
          echo "deleting /@root subvolume..."
          ${pkgs.btrfs-progs}/bin/btrfs subvolume delete /mnt/@root
        fi

        # Restore @root from the blank snapshot
        echo "restoring blank /@root subvolume..."
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

        # Ensure essential skeleton mount directories exist on /@root for impermanence bind mounts
        echo "ensuring mount skeleton directories on /@root..."
        ${pkgs.coreutils}/bin/mkdir -p /mnt/@root/{bin,etc/ssh,etc/NetworkManager/system-connections,var/lib/systemd,var/lib/nixos,var/lib/hermes,var/lib/tailscale,var/lib/skyvern,var/lib/brain-service,var/lib/postgresql,var/log,tmp,usr,home/t0psh31f,root}
        ${pkgs.coreutils}/bin/touch /mnt/@root/etc/NIXOS

        # NOTE: We DO NOT roll back @home. Wiping @home destroys the mount points
        # for impermanence bind-mounts from /persist, causing race conditions
        # that lead to login failures (black screens).

        ${pkgs.util-linuxMinimal}/bin/umount /mnt
      '';
    };

    # ============================================================================
    # BTRFS INTEGRITY — SCHEDULED SCRUB TIMERS
    # ============================================================================
    # Weekly scrubs detect silent bitrot on persist and data pools.
    # autoScrub.fileSystems must list *mountpoints*, not subvolumes.
    services.btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [
        "/persist"
        "/data"
      ];
    };

    # ============================================================================
    # ADDITIONAL CONFIGURATION
    # ============================================================================
    # Mark persistent storage as needed for boot (required for impermanence bind mounts)
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/home".neededForBoot = true;

  };
}
