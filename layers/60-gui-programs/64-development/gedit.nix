{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-60.gui.gedit;
in
{
  options.layers.layer-60.gui.gedit = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Gedit text editor with custom dconf settings";
    };
  };

  home = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gedit ];

    dconf.settings = {
      "org/gnome/gedit/preferences/editor" = {
        scheme = lib.mkDefault "oblivion";
        use-default-font = false;
        editor-font = lib.mkDefault "JetBrainsMono Nerd Font 14";
        display-line-numbers = true;
        highlight-current-line = true;
        bracket-matching = true;
        auto-indent = true;
        tabs-size = lib.mkDefault 4;
        insert-spaces = true;
      };
    };
  };
}
