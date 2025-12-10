{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.browsers = {
    firefox.enable = mkEnableOption "Firefox browser";
    brave.enable = mkEnableOption "Brave browser";
    vivaldi.enable = mkEnableOption "Vivaldi browser";
    qutebrowser.enable = mkEnableOption "Qutebrowser";

    # Default to enable all browsers
    enableAll = mkOption {
      type = types.bool;
      default = false;
      description = "Enable all browsers";
    };
  };

  config = mkMerge [
    # Firefox
    (mkIf (config.browsers.firefox.enable || config.browsers.enableAll) {
      environment.systemPackages = with pkgs; [
      ];

      # Firefox policies for better defaults
      programs.firefox = {
        enable = true;
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableFormHistory = true;
          DisplayBookmarksToolbar = "newtab";
          DontCheckDefaultBrowser = true;

          # Enable tracking protection
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };

          # Performance settings
          Preferences = {
            "browser.cache.disk.enable" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.memory.capacity" = 512000;
            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
          };
        };
      };
    })

    # Brave
    (mkIf (config.browsers.brave.enable || config.browsers.enableAll) {
      environment.systemPackages = with pkgs; [
        brave
      ];
    })

    # Vivaldi
    (mkIf (config.browsers.vivaldi.enable || config.browsers.enableAll) {
      environment.systemPackages = with pkgs; [
        vivaldi
        vivaldi-ffmpeg-codecs # Additional codec support
      ];
    })

    # Qutebrowser
    (mkIf (config.browsers.qutebrowser.enable || config.browsers.enableAll) {
      environment.systemPackages = with pkgs; [
        qutebrowser
      ];
    })
  ];
}
