{
  config,
  lib,
  pkgs,
  osConfig ? config,
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

    # Noctalia follow: when Noctalia shell is active, use Noctalia style (generated via 43-noctalia templates)
    # Fallback to oblivion for headless/GTK-only. Full matugen gedit style (gedit-matugen.xml) can be added as community template later.
    dconf.settings = {
      "org/gnome/gedit/preferences/editor" = {
        scheme = lib.mkDefault (
          if (osConfig.layers.layer-40.desktop.noctalia.enable or false) then "Noctalia" else "oblivion"
        );
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
