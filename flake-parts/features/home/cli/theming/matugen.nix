# flake-parts/features/home/cli/theming/matugen.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.cli-environment.theming.matugen;
  hasNoctalia = config.programs.noctalia-shell.enable or false;
in
{
  options.programs.cli-environment.theming.matugen = {
    enable = lib.mkEnableOption "Matugen dynamic theming for CLI tools";

    source = lib.mkOption {
      type = lib.types.enum [
        "wallpaper"
        "noctalia"
        "tokyo-night"
      ];
      default = if hasNoctalia then "noctalia" else "wallpaper";
      description = "Color scheme source for Matugen";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.matugen ];

    # Deploy templates to ~/.config/matugen/templates/
    home.file = {
      ".config/matugen/templates/helix.toml".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/helix.toml";
        sha256 = "0kh498w51mk47hxia7frc7c0a5a2lww6day3b8lz5dh5a1j1vxmq";
      };
      ".config/matugen/templates/kitty-colors.conf".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/kitty-colors.conf";
        sha256 = "1fyr9phqvjci1pid0z9nzhima58sq0jnwx53jr7a33hc6w31jsha";
      };
      ".config/matugen/templates/btop.theme".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/btop.theme";
        sha256 = "01zyc17yxkv5cdry6nkpz2psmzz5qcglwvipwy1gbx9dxqk9rla9";
      };
      ".config/matugen/templates/gtk-colors.css".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/gtk-colors.css";
        sha256 = "0qxlvbrcq3x7hf84vrsymqz1x42j78b46jmwaagjh1r7scg7i44g";
      };
      ".config/matugen/templates/fuzzel.ini".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/fuzzel.ini";
        sha256 = "0kkpyd1s1nspc7wps5amkmgwjz80xvn7lhf1fd6yajqmr6nm7kvj";
      };
      ".config/matugen/templates/hyprland-colors.conf".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/hyprland-colors.conf";
        sha256 = "08hhr9bd7wl58z1lgfl6ical4czsa4q79jn1f4nwf8rlxq0n2h12";
      };

      ".config/matugen/templates/yazi.toml".source = ./templates/yazi.toml;
      ".config/matugen/templates/zellij-colors.kdl".source = ./templates/zellij-colors.kdl;
      ".config/matugen/templates/bat-theme.tmTheme".source = ./templates/bat-theme.tmTheme;
      ".config/matugen/templates/delta.gitconfig".source = ./templates/delta.gitconfig;
      ".config/matugen/templates/fzf-colors.conf".source = ./templates/fzf-colors.conf;
      ".config/matugen/templates/brave-css-override.css".source = ./templates/brave-css-override.css;
      ".config/matugen/templates/homepage-custom.css".source = ./templates/homepage-custom.css;
      ".config/matugen/templates/starship.toml".source = ./templates/starship.toml;
      ".config/matugen/templates/dunst.conf".source = ./templates/dunst.conf;
      ".config/matugen/templates/waybar.css".source = ./templates/waybar.css;
    };

    # Matugen main configuration
    home.file.".config/matugen/config.toml".text = ''
      [config]
      reload = "all"

      [templates.helix]
      input_path = '~/.config/matugen/templates/helix.toml'
      output_path = '~/.config/helix/themes/matugen.toml'

      [templates.yazi]
      input_path = '~/.config/matugen/templates/yazi.toml'
      output_path = '~/.config/yazi/theme.toml'

      [templates.zellij]
      input_path = '~/.config/matugen/templates/zellij-colors.kdl'
      output_path = '~/.config/zellij/themes/matugen.kdl'
      post_hook = 'pkill -SIGUSR1 zellij'

      [templates.bat]
      input_path = '~/.config/matugen/templates/bat-theme.tmTheme'
      output_path = '~/.config/bat/themes/matugen.tmTheme'
      post_hook = 'bat cache --build'

      [templates.delta]
      input_path = '~/.config/matugen/templates/delta.gitconfig'
      output_path = '~/.config/delta/matugen-theme.gitconfig'

      [templates.fzf]
      input_path = '~/.config/matugen/templates/fzf-colors.conf'
      output_path = '~/.config/fzf/matugen.conf'

      [templates.brave]
      input_path = '~/.config/matugen/templates/brave-css-override.css'
      output_path = '~/.config/BraveSoftware/Brave-Browser/Default/User StyleSheets/Custom.css'

      [templates.homepage]
      input_path = '~/.config/matugen/templates/homepage-custom.css'
      output_path = '~/.config/homepage/custom.css'

      [templates.starship]
      input_path = '~/.config/matugen/templates/starship.toml'
      output_path = '~/.config/starship-matugen.toml'

      [templates.btop]
      input_path = '~/.config/matugen/templates/btop.theme'
      output_path = '~/.config/btop/themes/matugen.theme'

      [templates.kitty]
      input_path = '~/.config/matugen/templates/kitty-colors.conf'
      output_path = '~/.config/kitty/colors.conf'
      post_hook = 'pkill -SIGUSR1 kitty'

      [templates.gtk]
      input_path = '~/.config/matugen/templates/gtk-colors.css'
      output_path = '~/.config/gtk-3.0/gtk.css'

      [templates.gtk4]
      input_path = '~/.config/matugen/templates/gtk-colors.css'
      output_path = '~/.config/gtk-4.0/gtk.css'

      [templates.fuzzel]
      input_path = '~/.config/matugen/templates/fuzzel.ini'
      output_path = '~/.config/fuzzel/fuzzel-colors.ini'

      [templates.hyprland]
      input_path = '~/.config/matugen/templates/hyprland-colors.conf'
      output_path = '~/.config/hypr/colors.conf'

      [templates.dunst]
      input_path = '~/.config/matugen/templates/dunst.conf'
      output_path = '~/.config/dunst/dunstrc'
      post_hook = 'systemctl --user reload dunst'

      [templates.waybar]
      input_path = '~/.config/matugen/templates/waybar.css'
      output_path = '~/.config/waybar/colors.css'
      post_hook = 'pkill -SIGUSR2 waybar'

      [templates.vivid]
      input_path = '~/.config/matugen/templates/vivid.yml'
      output_path = '~/.config/matugen/vivid.yml'
    '';
  };
}
