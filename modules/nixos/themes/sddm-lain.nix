{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.themes.sddm-lain = {
    enable = mkEnableOption "SDDM Lain theme";
  };

  config = mkIf config.themes.sddm-lain.enable {
    # Install SDDM Lain theme
    services.displayManager.sddm = {
      enable = true;
      theme = "lain-wired";
      package = pkgs.kdePackages.sddm; # Use Qt6 SDDM if possible for modern themes
    };

    # Enable sound at login screen (requires system-wide audio)
    # Ensure pipewire is enabled in the system config
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = [
      (pkgs.stdenv.mkDerivation {
        pname = "sddm-lain-wired-theme";
        version = "0.1";
        src = pkgs.fetchFromGitHub {
          owner = "lll2yu";
          repo = "sddm-lain-wired-theme";
          rev = "6bd2074ff0c3eea7979f390ddeaa0d2b95e171b7";
          sha256 = "14l65d2vljqmgn91h5q6kkxwicjzcdz9k49wpjhmdfqky9wwg5xb";
        };
        installPhase = ''
          mkdir -p $out/share/sddm/themes/lain-wired
          cp -r * $out/share/sddm/themes/lain-wired/
        '';
      })
      pkgs.libsForQt5.qt5.qtgraphicaleffects # Often needed for SDDM themes
      pkgs.libsForQt5.qt5.qtquickcontrols2
      pkgs.libsForQt5.qt5.qtsvg
      pkgs.gst_all_1.gstreamer # For sound/video
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
    ];
  };
}
