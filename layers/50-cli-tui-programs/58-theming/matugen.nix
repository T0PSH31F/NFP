{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.layers.layer-50.cli.theming.matugen;
in
{
  options.layers.layer-50.cli.theming.matugen = {
    enable = lib.mkEnableOption "Matugen dynamic theming for CLI tools";
    source = lib.mkOption {
      type = lib.types.enum [
        "wallpaper"
        "noctalia"
        "tokyo-night"
      ];
      default = "wallpaper";
      description = "Color scheme source for Matugen";
    };
  };

  home = lib.mkIf cfg.enable {
    home.packages = [ pkgs.matugen ];
    home.file = {
      ".config/matugen/templates/delta.gitconfig".source = ./templates/delta.gitconfig;

      ".config/matugen/config.toml".text = ''
        [config]
        reload = "all"
        [templates.delta]
        input_path = '~/.config/matugen/templates/delta.gitconfig'
        output_path = '~/.config/delta/matugen-theme.gitconfig'
      '';
    };
  };
}
