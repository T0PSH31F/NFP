{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;
  zoroPoster = ../../../layers/00-cyberia/02-assets/sddm_background/zoro-swords-poster.png;
  zoroAvatar = ../../../layers/00-cyberia/02-assets/png-ico/Zoro.png;
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          graceful_fade = true;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [
          {
            path = "${zoroPoster}";
            blur_passes = 2;
            blur_size = 5;
            noise = 0.0117;
            contrast = 0.8916;
            brightness = 0.75;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "280, 52";
            outline_thickness = 2;
            dots_size = 0.33;
            dots_spacing = 0.15;
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(245, 239, 230)";
            inner_color = "rgba(10, 20, 15, 0.75)";
            outer_color = "rgba(57, 255, 20, 0.85)";
            check_color = "rgba(0, 217, 255, 0.85)";
            fail_color = "rgba(255, 0, 85, 0.85)";
            placeholder_text = "<i>Enter Password for Zoro...</i>";
            fail_text = "<i>Nothing happened...</i>";
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        image = [
          {
            monitor = "";
            path = "${zoroAvatar}";
            size = 96;
            border_size = 2;
            border_color = "rgba(57, 255, 20, 0.85)";
            rounding = -1;
            position = "0, -30";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            color = "rgb(57, 255, 20)";
            font_size = 64;
            font_family = "Orbitron";
            position = "0, 160";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[update:1000] date +'%A, %B %d'";
            color = "rgb(245, 239, 230)";
            font_size = 18;
            font_family = "Space Grotesk";
            position = "0, 95";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "⚔️ Roronoa Zoro — Santoryu Style";
            color = "rgba(57, 255, 20, 0.75)";
            font_size = 13;
            font_family = "Orbitron";
            position = "0, 50";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
