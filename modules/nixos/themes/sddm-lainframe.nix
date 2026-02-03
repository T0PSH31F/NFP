# modules/nixos/themes/sddm-lainframe.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Package the theme (QT6 + sound)
  lain-sddm-theme = pkgs.stdenv.mkDerivation rec {
    pname = "lain-sddm-theme";
    version = "2024-09-10";

    src = pkgs.fetchFromGitHub {
      owner = "Yangmoooo";
      repo = "lain-sddm-theme";
      rev = "04cc104e470b30e1d12ae9cb94f293ad4effc7f9";
      sha256 = "sha256-c+LuCWwZAvxetxdYCPzpb2EqmiUZIxxrJJxAoA5tilc=";
    };

    nativeBuildInputs = with pkgs; [
      qt6.qttools
      qt6.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtsvg
      qt6.qtmultimedia
    ];

    dontWrapQtApps = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/sddm/themes/lain-sddm-theme
      cp -r * $out/share/sddm/themes/lain-sddm-theme/

      # Ensure proper permissions for media files
      find $out/share/sddm/themes/lain-sddm-theme -type f -name "*.wav" -exec chmod 644 {} \;
      find $out/share/sddm/themes/lain-sddm-theme -type f -name "*.sh" -exec chmod +x {} \;

      runHook postInstall
    '';

    meta = with lib; {
      description = "Serial Experiments Lain SDDM theme (QT6 fork with audio)";
      homepage = "https://github.com/Yangmoooo/lain-sddm-theme";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in
{
  options.themes.sddm-lainframe = {
    enable = lib.mkEnableOption "Lain SDDM theme with QT6 + sound support";

    autoLogin = {
      enable = lib.mkEnableOption "automatic login";
      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Username for automatic login";
      };
    };
  };

  config = lib.mkIf config.themes.sddm-lainframe.enable {
    # SDDM configuration
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "lain-sddm-theme";
      package = pkgs.kdePackages.sddm;

      # Auto-login configuration
      autoLogin = lib.mkIf config.themes.sddm-lainframe.autoLogin.enable {
        relogin = true;
        user = config.themes.sddm-lainframe.autoLogin.user;
      };

      settings = {
        Theme = {
          Current = "lain-sddm-theme";
          CursorTheme = "Sonic-cursor-hyprcursor";
          CursorSize = 32;
        };

        General = {
          DisplayServer = "wayland";
          GreeterEnvironment = "QT_WAYLAND_PLATFORM=wayland";
        };
      };
    };

    # QT6 + Wayland environment for SDDM
    environment.systemPackages = with pkgs; [
      lain-sddm-theme
      qt6.qtwayland
      qt6.qtmultimedia
      qt6.qtsvg
      kdePackages.sddm
    ];

    # Audio system (PipeWire) - ensure no PulseAudio conflicts
    security.rtkit.enable = true;
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Ensure sddm user can access audio
    users.users.sddm.extraGroups = [
      "audio"
      "video"
    ];

    # Session environment for proper QT/Wayland rendering
    environment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
