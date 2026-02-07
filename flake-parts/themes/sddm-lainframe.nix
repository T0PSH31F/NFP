# modules/nixos/themes/sddm-lainframe.nix
{
  config,
  lib,
  pkgs,
  ...
}:

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
      # theme = "lain-sddm-theme";
      package = pkgs.kdePackages.sddm;

      # Auto-login configuration
      autoLogin = lib.mkIf config.themes.sddm-lainframe.autoLogin.enable {
        relogin = true;
        user = config.themes.sddm-lainframe.autoLogin.user;
      };

      extraPackages = with pkgs; [
        # pkgs.lain-sddm-theme

        qt6.qtwayland
        qt6.qtmultimedia
        qt6.qtsvg
      ];

      settings = {
        Theme = {
          Current = "breeze";
          CursorTheme = "Adwaita";
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
      # pkgs.lain-sddm-theme

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
