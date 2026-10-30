{
  lib,
  config,
  ...
}:
{
  options.layers.layer-60.gui.browsers.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird Mail Client";
  };

  home = lib.mkIf config.layers.layer-60.gui.browsers.thunderbird.enable {
    programs.thunderbird = {
      enable = true;
      profiles = {
        default = {
          isDefault = true;
        };
      };
    };
  };
}
