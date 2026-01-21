{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.themes.sddm-sel;

  # SEL theme package (Qt5 based)
  sddm-sel-theme = pkgs.stdenv.mkDerivation {
    pname = "sddm-sel-theme";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "leonardochappuis";
      repo = "sddmsel";
      rev = "e9860d88899d4fdfaea3cffe570e6ad55e25cf15";
      sha256 = "sha256-izrDuyOMPvEZt9c9Qs1sioqRKL+3M4S0RUUMMHhPK2c=";
    };
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -r sel-basic $out/share/sddm/themes/sel-basic
      cp -r sel-shaders $out/share/sddm/themes/sel-shaders
    '';
  };
in
{
  options.themes.sddm-sel = {
    enable = mkEnableOption "SDDM SEL theme (Serial Experiments Lain inspired)";

    variant = mkOption {
      type = types.enum [
        "basic"
        "shaders"
      ];
      default = "shaders";
      description = ''
        Which variant of the SEL theme to use:
        - "basic" - Without shader effects (lighter on resources)
        - "shaders" - With shader effects (more visual effects)
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertion: Only one SDDM theme can be enabled at a time
    assertions = [
      {
        assertion = !(config.themes.sddm-lain.enable or false);
        message = "Cannot enable both themes.sddm-sel and themes.sddm-lain. Please disable one.";
      }
    ];

    # SDDM SEL theme configuration (Qt5 based - use sddm not kdePackages.sddm)
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sel-${cfg.variant}";
      # Use Qt5-based SDDM for compatibility with Qt5 themes
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [
        sddm-sel-theme
        # Qt6 dependencies for compatibility
        kdePackages.qt5compat
        kdePackages.qtmultimedia
        kdePackages.qtsvg
        kdePackages.qtdeclarative
        # GStreamer for multimedia
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-libav
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

    # Install theme and dependencies to system
    environment.systemPackages = with pkgs; [
      sddm-sel-theme
      kdePackages.qt5compat
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-libav
    ];
  };
}
