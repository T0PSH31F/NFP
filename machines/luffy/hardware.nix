{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Modules for Intel i7 9700F / Gigabyte B365M
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      luks.devices."crypted" = {
        device = "/dev/disk/by-uuid/c62695ca-f48c-4296-8e27-62f27a32c7e1";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    };
    kernelModules = [ "kvm-intel" ];
    kernel.sysctl = {
      "kernel.unprivileged_userns_clone" = 1;
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Stage 2 LUKS decryption for non-essential partitions using keyfiles
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      swap_crypted UUID=b0a3e560-5af1-4311-abd0-12e5e463812b /persist/secrets/swap.key discard,nofail
      luffy_storage UUID=1d5aefd2-bee6-47a3-b691-91d2794c5258 /persist/secrets/luffy_storage.key discard,nofail
    '';
  };

  # Filesystems (btrfs subvolumes)
  fileSystems = {
    "/" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd"
        "noatime"
      ];
    };
    "/var/log" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd"
        "noatime"
      ];
    };
    "/nix" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
      ];
    };
    "/persist" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@persist"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/backup" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@backup"
        "compress=zstd"
        "noatime"
      ];
    };
    "/home" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/8F18-74D6";
      fsType = "vfat";
      options = [
        "defaults"
        "umask=0077"
      ];
    };
    # Samsung 860 EVO 250GB SSD - Extended Storage
    "/storage" = {
      device = "/dev/mapper/luffy_storage";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "nofail"
      ];
    };
    # External USB 932GB Btrfs Drive (Backup_1) — hosts Media, Torrents, and Consolidated Calibre Library non-destructively alongside bkups/Games/Pictures
    "/mnt/drives/backup-1" = {
      device = "/dev/disk/by-uuid/d917e1ff-6eb8-46c8-aedd-24d160b0df09";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "nofail"
        "x-systemd.device-timeout=5s"
      ];
    };
    # Internal Samsung 860 EVO 250GB SSD (Windows NTFS partition) — mounted read-only to preserve data cleanly
    "/mnt/drives/ssd-win" = {
      device = "/dev/disk/by-uuid/62CCE32ECCE2FB65";
      fsType = "ntfs3";
      options = [
        "ro"
        "nofail"
        "noauto"
        "x-systemd.automount"
        "uid=1000"
        "gid=100"
        "x-systemd.device-timeout=3s"
      ];
    };
    # NOTE: /dev/sdc (1.8TB Hitachi HDS723020BLA642) & /dev/sde1 (NATE DRIVE F7E6-2205) are intentionally
    # omitted from static fstab while active photorec recovery writes /dev/sdc -> NATE DRIVE/Recovered_Hitachi_2TB.
  };

  # Swap Configuration
  swapDevices = [
    {
      device = "/dev/mapper/swap_crypted";
      discardPolicy = "both";
      options = [ "nofail" ];
    }
  ];

  # Plain assignment, not lib.mkDefault: z0r0 sets it this way and evaluates
  # fine; with mkDefault the option was losing the merge and NixOS then failed
  # with "Neither nixpkgs.hostPlatform nor the legacy option nixpkgs.system has
  # been set" while evaluating bluetooth.nix.
  nixpkgs.hostPlatform = "x86_64-linux";
}
