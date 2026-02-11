{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mobile;
in
{
  options.mobile = {
    android = {
      enable = mkEnableOption "Android device support (ADB, Waydroid)";
    };
    ios = {
      enable = mkEnableOption "iOS device support (usbmuxd, ifuse)";
    };
  };

  config = mkMerge [
    # ============================================================================
    # ANDROID SUPPORT
    # ============================================================================
    (mkIf cfg.android.enable {

      # Enable Waydroid container
      # Note: Requires appropriate kernel modules (often compiled in Zen/CachyOS kernels)
      virtualisation.waydroid.enable = true;

      # File Transfer & MTP
      # services.gvfs.enable = true; # Mount, Trash, and other functionalities
      environment.systemPackages = with pkgs; [
        android-tools # ADB, Fastboot
        jmtpfs # MTP Filesystem
        scrcpy # Screen mirroring
        heimdall-gui # GUI for Heimdall (provides CLI tools as well)
      ];

      # User permissions
      # Ensure users are in 'adbusers' group in user config
    })

    # ============================================================================
    # iOS SUPPORT
    # ============================================================================
    (mkIf cfg.ios.enable {
      # Enable usbmuxd for USB multiplexing (required for iOS)
      services.usbmuxd.enable = true;

      environment.systemPackages = with pkgs; [
        libimobiledevice # Communicate with iOS devices
        ifuse # Mount iOS filesystems
        ideviceinstaller # Manage apps
        ios-webkit-debug-proxy # Debug WebKit on iOS
      ];
    })

    # ============================================================================
    # COMMON MOBILE INTEGRATION
    # ============================================================================
    (mkIf (cfg.android.enable || cfg.ios.enable) {
      # KDE Connect / GSConnect
      # Allows wireless file transfer, clipboard sync, notifications
      # programs.kdeconnect.enable = true; # Tag: mobile/laptop?
      # services.gvfs.enable = true; # Moved to service-distribution.nix
    })
  ];
}
