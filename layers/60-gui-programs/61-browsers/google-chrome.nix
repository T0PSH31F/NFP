{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.layers.layer-60.gui.browsers.google-chrome = {
    enable = lib.mkEnableOption "Google Chrome browser";
  };

  home = lib.mkIf config.layers.layer-60.gui.browsers.google-chrome.enable {
    home.packages = [ pkgs.google-chrome ];
  };
}
