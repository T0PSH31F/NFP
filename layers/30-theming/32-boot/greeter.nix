{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.layers.layer-30.theming.themes.greeter = {
    # Greeter selection — mutually exclusive. Only one can be active.
    type = lib.mkOption {
      type = lib.types.enum [
        "sddm"
        "greetd"
        "noctalia-greeter"
      ];
      default = "noctalia-greeter";
      description = ''
        Which login greeter to use:
        - "sddm": SDDM with Astronaut theme (Qt-based, X11/Wayland)
        - "greetd": Greetd with ReGreet in cage (minimal, Wayland-native)
        - "noctalia-greeter": Noctalia Greeter (native Wayland, recommended)
      '';
    };

    greetd = {
      background = lib.mkOption {
        type = lib.types.path;
        default = ../../00-cyberia/02-assets/sddm_background/thousand-sunny-poster.png;
        description = "Path to the background image for ReGreet (greetd only)";
      };
    };

    noctalia-greeter = {
      session = lib.mkOption {
        type = lib.types.str;
        default = "hyprland-uwsm";
        description = "Default session to launch (hyprland-uwsm, niri-uwsm, etc.)";
      };
    };
  };

  config =
    let
      cfg = config.layers.layer-30.theming.themes.greeter;
    in
    lib.mkMerge [
      # SDDM Implementation
      (mkIf (cfg.type == "sddm") {
        services.xserver.enable = true;
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          theme = "sddm-astronaut-theme";
        };

        environment.systemPackages = [
          (pkgs.sddm-astronaut.override {
            themeConfig = {
              Background = "${../../00-cyberia/02-assets/sddm_background/thousand-sunny.mp4}";
            };
          })
        ];
      })

      # Greetd Implementation (cage + regreet per best practice)
      (mkIf (cfg.type == "greetd") {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              # Minimal, stable Wayland greeter host (cage kiosk)
              command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
              user = "greeter";
            };
          };
        };

        programs.regreet = {
          enable = true;
          settings = {
            background = {
              path = toString cfg.greetd.background;
              fit = "Cover";
            };
            GTK = lib.mkDefault {
              icon_theme_name = "candy-icons";
              theme_name = "adw-gtk3-dark";
            };
          };
        };
      })

      # Noctalia Greeter Implementation
      (mkIf (cfg.type == "noctalia-greeter") {
        users.users.greeter = {
          isSystemUser = true;
          group = "greeter";
        };
        users.groups.greeter = { };

        services.greetd.settings.default_session.user = "greeter";

        programs.noctalia-greeter = {
          enable = true;
          package =
            inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
              (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.linuxHeaders ];
                buildInputs = (old.buildInputs or [ ]) ++ [
                  pkgs.linuxHeaders
                  pkgs.util-linux.lib
                  (lib.getLib pkgs.libselinux)
                ];
              });
          greeter-args = "--session ${cfg.noctalia-greeter.session}";
          settings = {
            cursor = {
              theme = "Bibata-Modern-Ice";
              size = 24;
              path = "${pkgs.bibata-cursors}/share/icons";
            };
            keyboard = {
              layout = "us";
            };
            appearance = {
              password_style = "random";
              wallpaper = "${../../00-cyberia/02-assets/sddm_background/thousand-sunny-poster.png}";
            };
            wallpaper = {
              path = "${../../00-cyberia/02-assets/sddm_background/thousand-sunny-poster.png}";
            };
          };
        };

        environment.systemPackages = [
          pkgs.bibata-cursors
        ];
      })
    ];
}
