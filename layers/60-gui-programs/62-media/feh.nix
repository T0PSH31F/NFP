# Feh image viewer and wallpaper tool
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.layers.layer-60.gui.feh = {
    enable = lib.mkEnableOption "feh image viewer and wallpaper tool";
  };

  nixos = lib.mkIf config.layers.layer-60.gui.feh.enable {
    environment.systemPackages = with pkgs; [ feh ];
  };

  home = lib.mkIf config.layers.layer-60.gui.feh.enable {
    home.packages = with pkgs; [ feh ];
    # Associates feh with image files
    xdg.mimeApps.associations.added = {
      "image/jpeg" = "feh.desktop";
      "image/png" = "feh.desktop";
      "image/gif" = "feh.desktop";
    };
  };
}
