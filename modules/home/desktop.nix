{
  config,
  pkgs,
  lib,
  inputs,
  clanTags,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./hyprland.nix
    ./spicetify.nix
    ./ghostty.nix
  ];

  config = lib.mkIf (builtins.elem "desktop" clanTags) {
    # Enable Hyprland
    desktop.hyprland.enable = true;

    # Enable Noctalia - hardcoded to hyprland backend for now as per current setup
    programs.noctalia-shell = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.system}.default;
    };

    # Desktop GUI helpers for the user
    home.packages = with pkgs; [
      # GUI apps
      # (You can refine this list later)
      obs-studio
      pavucontrol
      file-roller
    ];

    # Terminal emulator configuration (example: kitty)
    programs.kitty = {
      enable = true;
      theme = "Catppuccin-Mocha";
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 11;
      };
    };

    # Basic theming / GTK
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };
  };
}
