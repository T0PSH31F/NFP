{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.layers.layer-60.gui.browsers.google-chrome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Google Chrome browser";
    };
  };

  home = lib.mkIf config.layers.layer-60.gui.browsers.google-chrome.enable {
    home.packages = [ pkgs.google-chrome ];
  };
}
