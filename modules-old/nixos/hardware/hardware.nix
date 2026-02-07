{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.hardware-config = {
    # Kernel selection
    kernel = mkOption {
      type = types.enum ["latest" "cachyos" "zen"];
      default = "latest";
      description = ''
        Select which kernel to use:
        - latest: Latest stable kernel from nixpkgs
        - cachyos: CachyOS optimized kernel for performance
        - zen: Zen kernel for desktop responsiveness
      '';
    };

    # Disk automounting
    automount = {
      enable = mkEnableOption "Automatic disk mounting with udisks2/udiskie";

      useUdiskie = mkOption {
        type = types.bool;
        default = true;
        description = "Use udiskie for automatic mounting (userspace). If false, uses udisks2 only.";
      };
    };

    # RGB lighting control
    openrgb = {
      enable = mkEnableOption "OpenRGB for RGB lighting control";

      enableI2C = mkOption {
        type = types.bool;
        default = true;
        description = "Enable I2C support for RGB RAM and motherboards";
      };
    };
  };

  config = {
    # ============================================================================
    # KERNEL CONFIGURATION
    # ============================================================================

    boot.kernelPackages = mkMerge [
      # Latest stable kernel (default)
      (mkIf (config.hardware-config.kernel == "latest")
        pkgs.linuxPackages_latest)

      # CachyOS kernel - optimized for performance
      (mkIf (config.hardware-config.kernel == "cachyos")
        pkgs.linuxPackages_cachyos)

      # Zen kernel - optimized for desktop/responsiveness
      (mkIf (config.hardware-config.kernel == "zen")
        pkgs.linuxPackages_zen)
    ];

    # ============================================================================
    # DISK AUTOMOUNTING
    # ============================================================================

    # Enable udisks2 service
    services.udisks2.enable = mkIf config.hardware-config.automount.enable true;

    # Udiskie as systemd user service (for automounting)
    # Note: Udiskie is user-level, so it's installed as a package and can be run per-user
    systemd.user.services.udiskie = mkIf (config.hardware-config.automount.enable && config.hardware-config.automount.useUdiskie) {
      description = "Udiskie automount daemon";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify --tray";
        Restart = "on-failure";
      };
    };

    # Add udiskie and udisks to system packages

    # ============================================================================
    # RGB LIGHTING (OpenRGB)
    # ============================================================================

    services.hardware.openrgb = mkIf config.hardware-config.openrgb.enable {
      enable = true;
      motherboard = "amd"; # or "intel" - auto-detected in most cases
    };

    # Enable I2C for RGB RAM and motherboard control
    hardware.i2c.enable = mkIf (config.hardware-config.openrgb.enable && config.hardware-config.openrgb.enableI2C) true;

    # Add hardware packages
    environment.systemPackages =
      (lib.optionals config.hardware-config.automount.enable (with pkgs; [udiskie udisks]))
      ++ (lib.optionals config.hardware-config.openrgb.enable [pkgs.openrgb]);

    # Add user to i2c group for RGB control
    # This will need to be added to user configuration
    # users.users.<username>.extraGroups = [ "i2c" ];

    # ============================================================================
    # GENERAL HARDWARE SUPPORT
    # ============================================================================

    # Enable firmware updates
    services.fwupd.enable = true;

    # Enable CPU microcode updates
    hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

    # Enable redistributable firmware (doesn't require allowUnfree)
    hardware.enableRedistributableFirmware = true;

    # Graphics support
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # For 32-bit applications and games
    };

    # Audio support - don't use PulseAudio, prefer PipeWire (set by audio.nix)
    # hardware.pulseaudio.enable is managed by audio module
    security.rtkit.enable = true; # RealtimeKit for audio

    # Bluetooth
    hardware.bluetooth.enable = lib.mkDefault true;
    hardware.bluetooth.powerOnBoot = lib.mkDefault true;

    # USB automounting
    services.devmon.enable = mkIf config.hardware-config.automount.enable true;
    services.gvfs.enable = mkIf config.hardware-config.automount.enable true;

    # Storage optimization
    services.fstrim.enable = true; # SSD TRIM support
  };
}
