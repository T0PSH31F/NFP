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
    # Assertion: Only one SDDM theme can be enabled at a time
    assertions = [
      {
        assertion = !(config.themes.sddm-sel.enable or false);
        message = "Cannot enable both themes.sddm-lain and themes.sddm-sel. Please disable one.";
      }
    ];

    # SDDM Lain theme configuration
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "lain";
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [
        # The Lain theme package (Qt6 compatible fork)
        (stdenv.mkDerivation {
          pname = "sddm-lain-theme";
          version = "0.1";
          src = fetchFromGitHub {
            owner = "Yangmoooo";
            repo = "lain-sddm-theme";
            rev = "04cc104e470b30e1d12ae9cb94f293ad4effc7f9";
            sha256 = "sha256-c+LuCWwZAvxetxdYCPzpb2EqmiUZIxxrJJxAoA5tilc=";
          };
          installPhase = ''
            mkdir -p $out/share/sddm/themes/lain
            cp -r * $out/share/sddm/themes/lain/
          '';
        })
        # Qt6 dependencies for the theme
        kdePackages.qtsvg
        kdePackages.qt5compat
        kdePackages.qtmultimedia
      ];
    };

    # Enable sound at login screen (requires system-wide audio)
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # GStreamer for audio/video in SDDM
    environment.systemPackages = with pkgs; [
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
    ];
  };
}
