{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-30.theming.themes.plymouth-matrix = {
    enable = mkEnableOption "Plymouth Matrix theme";
  };

  config = mkIf config.layers.layer-30.theming.themes.plymouth-matrix.enable {
    # Boot configuration
    boot = {
      plymouth = {
        enable = true;
        theme = "matrix";
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override {
            selected_themes = [ "matrix" ];
          })
        ];
      };

      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "splash"
      ];
    };
  };
}
