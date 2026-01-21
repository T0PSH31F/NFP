{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.programs.uwsm = {
    enable = lib.mkEnableOption "Universal Wayland Session Manager";

    waylandCompositors = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            prettyName = lib.mkOption {
              type = lib.types.str;
              description = "Display name for the compositor session";
            };
            comment = lib.mkOption {
              type = lib.types.str;
              description = "Description shown in session selector";
            };
            binPath = lib.mkOption {
              type = lib.types.str;
              description = "Path to compositor binary";
            };
          };
        }
      );
      default = { };
      description = "Wayland compositor sessions to register with SDDM";
    };
  };

  config = lib.mkIf config.programs.uwsm.enable {
    # Install UWSM package
    environment.systemPackages = [ pkgs.uwsm ];

    # Create wayland-sessions directory entries for
    environment.etc = lib.mapAttrs' (
      name: compositorCfg:
      lib.nameValuePair "wayland-sessions/${name}.desktop" {
        text = ''
          [Desktop Entry]
          Name=${compositorCfg.prettyName}
          Comment=${compositorCfg.comment}
          Exec=uwsm start -F -- ${compositorCfg.binPath}
          Type=Application
          DesktopNames=${name}
        '';
      }
    ) config.programs.uwsm.waylandCompositors;

    # Enable necessary services for Wayland
    services.dbus.enable = lib.mkDefault true;
    xdg.portal.enable = lib.mkDefault true;
  };
}
