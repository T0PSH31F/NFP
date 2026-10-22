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
    # Enable Plymouth
    boot.plymouth = {
      enable = true;
      theme = "matrix";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "matrix" ];
        })
      ];
    };

    # Enable silent boot for a clean plymouth experience
    boot.consoleLogLevel = 3;
    boot.kernelParams = [
      "quiet"
      "splash"
    ];
  };
}
