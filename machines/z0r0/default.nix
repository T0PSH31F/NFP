{...}: {
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
  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f";

  # Filesystems (btrfs subvolumes)
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@root"];
  };
  fileSystems."/var/log" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@log"];
  };
  fileSystems."/nix" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@nix"];
  };
  fileSystems."/persist" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@persist"];
  };
  fileSystems."/backup" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@backup"];
  };
  fileSystems."/home" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = ["subvol=@home"];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E6FA-59AC";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
  swapDevices = [
    {device = "/dev/mapper/dev-disk-byx2dpartlabel-diskx2dmainx2dswap";}
  ];

  networking.hostName = "z0r0";

  # ============================================================================
  # DESKTOP ENVIRONMENT SELECTION
  # ============================================================================

  desktop.dankmaterialshell = {
    enable = false;
    backend = "both";
  };

  desktop.omarchy = {
    enable = true;
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

  themes.sddm-lain.enable = true;
  themes.grub-lain.enable = true;
  themes.plymouth-hellonavi.enable = true;

  # ============================================================================
  # GAMING & VIRTUALIZATION
  # ============================================================================

  gaming.enable = false;
  virtualization.enable = false;

  # ============================================================================
  # SYSTEM
  # ============================================================================

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
