{ config, lib, pkgs, fetchFromGitHub, ... }:

let
  # Package the theme (QT6 + sound)
  lain-sddm-theme = pkgs.stdenv.mkDerivation rec {
    pname = "lain-sddm-theme";
    version = "2024-09-10";

    src = pkgs.fetchFromGitHub {
      owner = "Yangmoooo";
      repo = "lain-sddm-theme";
      rev = "04cc104e470b30e1d12ae9cb94f293ad4effc7f9";
      sha256 = "0mwadl7a0h4w4imiq8qr4nd2lqbgx7y0hn0pnxggq0hrdh4yxqkk"; 
    };

    nativeBuildInputs = [ pkgs.qt6Packages.qttools ];
    
    # This is a theme/data package, not an application - don't wrap Qt apps
    dontWrapQtApps = true;
    
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -r . $out/share/sddm/themes/lain-sddm-theme/
      
      # Ensure sounds work (QT6 audio)
      chmod +x $out/share/sddm/themes/lain-sddm-theme/*.sh 2>/dev/null || true
    '';

    meta = with lib; {
      description = "Serial Experiments Lain SDDM theme (QT6 fork)";
      homepage = "https://github.com/Yangmoooo/lain-sddm-theme";
      license = licenses.mit;  # Adjust if needed
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in
{
  options.themes.sddm-lainframe.enable =
    lib.mkEnableOption "Lain SDDM theme with QT6 + sound support";

  config = lib.mkIf config.themes.sddm-lainframe.enable {
    # SDDM + theme package
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;  # QT6 Wayland support
      theme = "lain-sddm-theme";
      extraPackages = [ lain-sddm-theme ];
    };

    # Audio for welcome.wav (pipewire default)
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # QT6 + sound deps for greeter
    environment.systemPackages = with pkgs; [
      qt6Packages.qtwayland
      qt6Packages.qtmultimedia
      kdePackages.sddm
    ];

    # SDDM config for sound
    environment.etc."sddm.conf.d/lain-theme.conf".text = ''
      [Theme]
      Current=lain-sddm-theme
    '';
  };
}