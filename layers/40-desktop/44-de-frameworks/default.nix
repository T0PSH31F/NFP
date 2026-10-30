{ lib, ... }:
{
  options.layers.layer-40.desktop.frameworks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable desktop frameworks";
    };

    portals = {
      enable = lib.mkEnableOption "Desktop portals for Wayland compositors";
      extraPortals = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Additional XDG desktop portals to enable";
      };
    };

    vicinae = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Vicinae launcher";
      };
    };

    which-key = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable wlr-which-key visual keybinding popup (Vimjoyer vid74)";
      };
    };
  };

  imports = [
    ./portals.nix
  ];

  home = {
    imports = [
      ./vicinae.nix
      ./which-key.nix
    ];
  };
}
