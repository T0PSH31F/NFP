# Unified GTK Theming Module
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
{
  options.layers.layer-30.theming.gtk = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GTK theming engine and configuration";
    };
  };

  # Home Manager GTK configuration
  home =
    let
      cfg = osConfig.layers.layer-30.theming.gtk;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        adw-gtk3
        nwg-look
        hicolor-icon-theme
        whitesur-icon-theme
        papirus-icon-theme
        rose-pine-icon-theme
      ];

      gtk = {
        enable = true;
        gtk4.theme = null;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "whitesur-icons";
          package = pkgs.whitesur-icon-theme;
        };
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 15;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
          gtk-cursor-blink = true;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
          gtk-cursor-blink = true;
        };
        gtk2.extraConfig = ''
          gtk-application-prefer-dark-theme = 1
        '';
      };

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "whitesur-icons";
        font-name = "JetBrainsMono Nerd Font 15";
      };
    };
}
