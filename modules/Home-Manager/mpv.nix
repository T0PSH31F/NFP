{
  config,
  lib,
  pkgs,
  ...
}: {
  # MPV configuration with anime4k shaders and cinematic playback
  programs.mpv = {
    enable = true;

    package = pkgs.mpv-unwrapped.wrapper {
      mpv = pkgs.mpv-unwrapped;
      scripts = with pkgs.mpvScripts; [
        mpris
        thumbnail
        quality-menu
        sponsorblock
        uosc
      ];
    };

    config = {
      # Video output
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "auto-safe";

      # Quality & Performance
      profile = "gpu-hq";
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      dscale = "mitchell";
      scale-antiring = "0.7";
      cscale-antiring = "0.7";
      dither-depth = "auto";
      correct-downscaling = "yes";
      linear-downscaling = "yes";
      sigmoid-upscaling = "yes";

      # Debanding
      deband = "yes";
      deband-iterations = "4";
      deband-threshold = "35";
      deband-range = "16";
      deband-grain = "5";

      # Interpolation for smooth motion
      video-sync = "display-resample";
      interpolation = "yes";
      tscale = "oversample";

      # HDR & Color
      tone-mapping = "bt.2390";
      tone-mapping-mode = "hybrid";
      hdr-compute-peak = "yes";
      hdr-contrast-recovery = "0.30";

      # Audio
      audio-file-auto = "fuzzy";
      audio-pitch-correction = "yes";
      volume-max = "150";

      # Subtitles
      sub-auto = "fuzzy";
      sub-file-paths = "ass:srt:sub:subs:subtitles";
      slang = "enm,en,eng,de,deu,ger";
      sub-fix-timing = "no";

      # Subtitle styling
      sub-font = "Gandhi Sans";
      sub-font-size = "46";
      sub-color = "#FFFFFFFF";
      sub-border-color = "#FF000000";
      sub-border-size = "3.0";
      sub-shadow-offset = "1";
      sub-shadow-color = "#33000000";
      sub-spacing = "0.5";

      # Screenshots
      screenshot-format = "png";
      screenshot-png-compression = "8";
      screenshot-template = "~/Pictures/mpv-screenshot-%F-[%P]v%#01n";
      screenshot-directory = "~/Pictures/";

      # Cache
      cache = "yes";
      demuxer-max-bytes = "800M";
      demuxer-max-back-bytes = "200M";

      # OSD
      osd-level = "1";
      osd-duration = "2500";
      osd-status-msg = "\${time-pos} / \${duration}\${?percent-pos:(\${percent-pos}%)}\\n\${?chapter:Chapter: \${chapter}}";
      osd-font = "Gandhi Sans";
      osd-font-size = "32";
      osd-color = "#CCFFFFFF";
      osd-border-color = "#CC000000";
      osd-bar-align-y = "0";
      osd-border-size = "2";
      osd-bar-h = "2";
      osd-bar-w = "60";

      # Window
      keep-open = "yes";
      save-position-on-quit = "yes";

      # Performance
      vulkan-async-compute = "yes";
      vulkan-async-transfer = "yes";
      vulkan-queue-count = "1";
    };

    profiles = {
      # Anime profile with anime4k
      anime = {
        profile-desc = "Anime upscaling with Anime4K";
        glsl-shaders-clr = "";
        # Anime4K shaders will be added via scripts
      };

      # High quality profile for movies
      movies = {
        profile-desc = "High quality for movies";
        deband-iterations = "2";
        deband-threshold = "35";
        deband-range = "20";
      };

      # Low-end profile for weaker hardware
      fast = {
        profile-desc = "Fast profile for low-end hardware";
        vo = "gpu";
        hwdec = "auto";
        scale = "bilinear";
        cscale = "bilinear";
        dscale = "bilinear";
        scale-antiring = "0";
        cscale-antiring = "0";
        deband = "no";
        interpolation = "no";
      };
    };

    bindings = {
      # Profiles
      "F1" = "show-text \${profile-list}";
      "F2" = "set profile anime; show-text 'Profile: Anime'";
      "F3" = "set profile movies; show-text 'Profile: Movies'";
      "F4" = "set profile fast; show-text 'Profile: Fast'";

      # Playback
      "RIGHT" = "seek 5";
      "LEFT" = "seek -5";
      "UP" = "seek 60";
      "DOWN" = "seek -60";
      "Shift+RIGHT" = "seek 1 exact";
      "Shift+LEFT" = "seek -1 exact";

      # Subtitles
      "z" = "add sub-delay -0.1";
      "x" = "add sub-delay +0.1";
      "c" = "add sub-scale -0.1";
      "v" = "add sub-scale +0.1";

      # Audio
      "9" = "add volume -2";
      "0" = "add volume 2";
      "/" = "add audio-delay -0.1";
      "*" = "add audio-delay 0.1";

      # Screenshots
      "s" = "screenshot";
      "S" = "screenshot video";
      "Ctrl+s" = "screenshot window";
    };
  };
}
