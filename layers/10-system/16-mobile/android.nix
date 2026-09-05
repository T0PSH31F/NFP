# Android Device Support (ADB, Waydroid, Valent, MTP)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.mobile.android;
in
{
  options.layers.layer-10.system.mobile.android = {
    enable = lib.mkEnableOption "Android device support (ADB, Waydroid, Valent)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-tools # ADB, Fastboot
      scrcpy # Screen mirroring
      heimdall-gui # GUI for Heimdall
      mtkclient
      mobile-broadband-provider-info
      qmk-udev-rules
      phonemizer
      pixelflasher
      universal-android-debloater
      # valent # KDE Connect implementation for GTK
    ];

    # Open ports for KDE Connect protocol (used by Valent)
    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
