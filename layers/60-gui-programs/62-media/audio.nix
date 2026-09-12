{
  pkgs,
  lib,
  ...
}:
{
  options.layers.layer-60.gui.audio = {
    enable = lib.mkEnableOption "Audio visualization and management (cava, cavalier, mpd)" // {
      default = true;
    };
  };

  home =
    { config, osConfig, ... }:
    lib.mkIf osConfig.layers.layer-60.gui.audio.enable {
      # MPD Service and Client
      services.mpd = {
        enable = true;
        musicDirectory = "${config.home.homeDirectory}/Music";
        dataDir = "${config.home.homeDirectory}/.local/share/mpd";
        extraConfig = ''
          audio_output {
            type "pipewire"
            name "PipeWire Output"
          }
        '';
      };

      # Visualization
      programs.cava = {
        enable = true;
        settings = {
          general.framerate = 60;
          input.method = "pipewire";
          smoothing.monstercat = 1;
          color = {
            theme = "'noctalia'";
            gradient = 1;
            gradient_count = 8;
            gradient_color_1 = "'#94e2d5'";
            gradient_color_2 = "'#89dceb'";
            gradient_color_3 = "'#74c7ec'";
            gradient_color_4 = "'#89b4fa'";
            gradient_color_5 = "'#cba6f7'";
            gradient_color_6 = "'#f5c2e7'";
            gradient_color_7 = "'#eba0ac'";
            gradient_color_8 = "'#f38ba8'";
          };

        };
      };

      home.packages = with pkgs; [
        cavalier # GUI Visualizer
        mpc # CLI control for mpd
        picard # MusicBrainz Picard for metadata tagging & cover art
        mediainfo-gui # GUI media file technical inspector
        mediainfo # CLI media file inspector
        musicfree-desktop
        musikcube
        clementine
        strawberry
        wrtag
      ];
    };
}
