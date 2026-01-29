{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = "16.0";
      enable_audio_bell = false;
      window_padding_width = 10;
      background_opacity = "0.95";
    };
  };
}
