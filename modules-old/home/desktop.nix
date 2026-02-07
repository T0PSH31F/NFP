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
    ./shikane.nix
  ];

  config = lib.mkIf (builtins.elem "desktop" clanTags) {
    # Enable Hyprland
    desktop.hyprland.enable = true;

    # Enable Noctalia - hardcoded to hyprland backend for now as per current setup
    # Enable Noctalia
    programs.noctalia-shell = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.system}.default;
      settings = ./assets/noctalia-config.json;
    };

    # NOTE: Noctalia templates would need to be configured according to the
    # noctalia-shell flake's actual options. The themes.noctalia.templates
    # option does not exist in the current version.

    # Ensure directories exist for templates
    home.file = {
      ".config/homepage/.keep".text = "";
      ".config/BraveSoftware/Brave-Browser/Default/User StyleSheets/.keep".text = "";
      ".local/share/gedit/styles/.keep".text = "";
    };

    # Desktop GUI helpers for the user
    home.packages = with pkgs; [
      # Icons
      candy-icons

      # GUI apps
      obs-studio
      pavucontrol
      file-roller
      gedit
      brave
      shikane
      matugen
      qutebrowser
      

      # Communication
      kotatogram-desktop # Telegram client
      element-desktop # Matrix client
      vesktop # Discord client (Vencord)
      equibop # Discord client (alternative)
      caprine # Facebook Messenger

      # Music
      spotdl # Spotify downloader

      # Productivity
      obsidian # Knowledge base / notes
      lsd
    ];

    # Gedit preferences via dconf
    dconf.settings = {
      "org/gnome/gedit/preferences/editor" = {
        scheme = "noctalia";
        use-default-font = false;
        editor-font = lib.mkDefault "JetBrainsMono Nerd Font 11";
        display-line-numbers = true;
        highlight-current-line = true;
        bracket-matching = true;
        auto-indent = true;
        tabs-size = lib.mkDefault 2;
        insert-spaces = true;
      };
    };

    programs.firefox.enable = true;

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 16;
      };
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Sweet-Rainbow";
        package = pkgs.sweet-folders;
      };
    };
  };
}
