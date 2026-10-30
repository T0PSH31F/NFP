# Unified QT Theming Module
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
{
  options.layers.layer-30.theming.qt = {
    enable = lib.mkEnableOption "QT application theming and style integration";
  };

  # Home Manager QT configuration
  home =
    let
      cfg = osConfig.layers.layer-30.theming.qt;
      isNoctalia = osConfig.layers.layer-40.desktop.noctalia.enable or false;
      colorSchemeLine5 =
        if isNoctalia then
          "color_scheme_path=~/.config/qt5ct/colors/noctalia.conf\ncustom_palette=true"
        else
          "custom_palette=false";
      colorSchemeLine6 =
        if isNoctalia then
          "color_scheme_path=~/.config/qt6ct/colors/noctalia.conf\ncustom_palette=true"
        else
          "custom_palette=false";
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        qt5.qtwayland
        qt6.qtwayland
        qt6Packages.qt5compat
        qt6Packages.qt6ct
        libsForQt5.qt5ct
        qt6Packages.qtstyleplugin-kvantum
      ];

      qt = {
        enable = true;
        platformTheme.name = "qtct";
        style.name = "kvantum";
      };

      xdg.configFile."qt5ct/qt5ct.conf" = {
        text = ''
          [Appearance]
          ${colorSchemeLine5}
          icon_theme=whitesur-icons
          standard_dialogs=default
          style=Fusion

          [Fonts]
          fixed="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"
          general="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"

          [Interface]
          activate_item_on_single_click=1
          buttonbox_layout=0
          cursor_flash_time=1000
          dialog_buttons_have_icons=1
          double_click_interval=400
          gui_effects=@Invalid()
          keyboard_scheme=2
          menus_have_icons=true
          show_shortcuts_in_context_menus=true
          toolbutton_style=4
          wheel_scroll_lines=3
        '';
        force = true;
      };

      xdg.configFile."qt6ct/qt6ct.conf" = {
        text = ''
          [Appearance]
          ${colorSchemeLine6}
          icon_theme=whitesur-icons
          standard_dialogs=default
          style=Fusion

          [Fonts]
          fixed="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"
          general="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"

          [Interface]
          activate_item_on_single_click=1
          buttonbox_layout=0
          cursor_flash_time=1000
          dialog_buttons_have_icons=1
          double_click_interval=400
          gui_effects=@Invalid()
          keyboard_scheme=2
          menus_have_icons=true
          show_shortcuts_in_context_menus=true
          toolbutton_style=4
          wheel_scroll_lines=3
        '';
        force = true;
      };
    };
}
