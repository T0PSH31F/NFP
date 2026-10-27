{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  config =
    lib.mkIf (cfg.enable && (cfg.backend == "niri" || cfg.backend == "both" || cfg.backend == "all"))
      {
        programs.niri = {
          settings = {
            # Layout settings based on Niri defaults
            layout = {
              gaps = 15;
              center-focused-column = "never";
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];
              default-column-width = {
                proportion = 0.5;
              };
              focus-ring = {
                width = 4;
                active.color = "#7fc8ff";
                inactive.color = "#505050";
              };
              border = {
                enable = false;
              };
              shadow = {
                enable = false;
              };
            };

            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  options = "caps:escape";
                };
              };
              touchpad = {
                tap = true;
                natural-scroll = true;
              };
            };

            animations = {
              # slowdown = 1.0;
            };

            window-rules = [
              {
                matches = [
                  {
                    app-id = "firefox";
                    title = "^Picture-in-Picture$";
                  }
                ];
                open-floating = true;
              }
            ];
          };
        };
      };
}
