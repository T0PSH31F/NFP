{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let

  # Experience-coupled greeter auto-derivation:
  #   - noctalia-*         → noctalia-greeter   (native Noctalia login screen)
  #   - nixarchy-rise      → nixarchy-greeter   (Omarchy's own DM)
  #   - headless-console   → tuigreet
  #   - none               → tuigreet
  #   - everything else    → sddm-astronaut     (eye-candy Qt6 fallback)
  derivedType = config.layers.desktop.derivedGreeter or "sddm-astronaut";
in
{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.layers.layer-30.theming.themes.greeter = {
    # Greeter selection — mutually exclusive. Defaults to experience-derived value.
    type = lib.mkOption {
      type = lib.types.enum [
        "noctalia-greeter"
        "nixarchy-greeter"
        "sddm-astronaut"
        "sddm" # legacy alias for plain SDDM without astronaut theme
        "greetd" # regreet-in-cage
        "regreet-wayland" # ReGreet Wayland greeter
        "tuigreet"
      ];
      default = derivedType;
      description = ''
        Which login greeter to use. Defaults to the value auto-derived from
        layers.desktop.experience so each desktop environment gets its own
        native login screen:
          noctalia-*       → noctalia-greeter
          nixarchy-rise    → nixarchy-greeter
          micro-smol-ai    → tuigreet
          headless-console → tuigreet
          everything else  → sddm-astronaut
        Override here only to decouple from the experience default.
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
        description = "Default session to launch (hyprland-uwsm, niri-uwsm, umbriel-uwsm, etc.)";
      };
    };

    sddm-astronaut = {
      videoTheme = lib.mkOption {
        type = lib.types.enum [
          "thousand-sunny"
          "one-piece-skull"
          "zoro-swords"
          "custom"
        ];
        default = "thousand-sunny";
        description = "Curated video loop presets (thousand-sunny, one-piece-skull, zoro-swords, custom)";
      };
      videoBackground = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to a custom video file for the SDDM Astronaut background loop.
          Supports .mp4 / .webm. Used when videoTheme is "custom".
        '';
      };
      staticBackground = lib.mkOption {
        type = lib.types.path;
        default = ../../00-cyberia/02-assets/sddm_background/thousand-sunny-poster.png;
        description = "Static image fallback when videoBackground is null.";
      };
    };
  };

  config =
    let
      cfg = config.layers.layer-30.theming.themes.greeter;
      resolvedVideoBackground =
        if cfg.sddm-astronaut.videoTheme == "one-piece-skull" then
          ../../00-cyberia/02-assets/sddm_background/one-piece-skull.1920x1080.mp4
        else if cfg.sddm-astronaut.videoTheme == "zoro-swords" then
          ../../00-cyberia/02-assets/sddm_background/zoro-swords.mp4
        else if cfg.sddm-astronaut.videoTheme == "thousand-sunny" then
          ../../00-cyberia/02-assets/sddm_background/thousand-sunny.mp4
        else
          cfg.sddm-astronaut.videoBackground;
    in
    lib.mkMerge [
      # ── Noctalia Greeter ──────────────────────────────────────────────
      (mkIf (cfg.type == "noctalia-greeter") {
        users.users.greeter = {
          isSystemUser = true;
          group = "greeter";
          extraGroups = [
            "video"
            "render"
            "input"
            "tty"
          ];
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

      # ── Nixarchy Greeter ──────────────────────────────────────────────
      # Omarchy 4.x ships its own greetd wrapper; we invoke it via tuigreet
      # on the Omarchy session path as a fallback until nixarchy exposes its
      # own NixOS greeter module.
      (mkIf (cfg.type == "nixarchy-greeter") {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet -u t0psh31f --time --remember --remember-session --asterisks --sessions /run/current-system/sw/share/wayland-sessions --session-wrapper 'uwsm start'";
              user = "greeter";
            };
          };
        };
        users.users.greeter = {
          isSystemUser = true;
          group = "greeter";
          extraGroups = [
            "video"
            "render"
            "input"
            "tty"
          ];
        };
        users.groups.greeter = { };
      })

      # ── SDDM Astronaut (Eye-Candy Qt6 — default for non-native DEs) ───
      (mkIf (cfg.type == "sddm-astronaut") {
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          package = pkgs.kdePackages.sddm;
          extraPackages = [ pkgs.kdePackages.qtmultimedia ];
          theme = "sddm-astronaut-theme";
        };

        environment.systemPackages = [
          (pkgs.sddm-astronaut.override {
            themeConfig =
              lib.optionalAttrs (resolvedVideoBackground != null) {
                Background = toString resolvedVideoBackground;
              }
              // lib.optionalAttrs (resolvedVideoBackground == null) {
                Background = toString cfg.sddm-astronaut.staticBackground;
              };
          })
        ];
      })

      # ── SDDM (legacy plain, no astronaut theme) ───────────────────────
      (mkIf (cfg.type == "sddm") {
        services.xserver.enable = true;
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };
      })

      # ── Greetd + ReGreet in cage (regreet-wayland) ─────────────────────
      (mkIf (cfg.type == "greetd" || cfg.type == "regreet-wayland") {
        users.users.greeter = {
          isSystemUser = true;
          group = "greeter";
          extraGroups = [
            "video"
            "render"
            "input"
            "tty"
          ];
        };
        users.groups.greeter = { };

        services.displayManager.regreet = {
          enable = true;
          cageArgs = [ "-s" ];
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

      # ── Tuigreet (TTY console — micro-host / headless) ────────────────
      (mkIf (cfg.type == "tuigreet") {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet -u t0psh31f --time --remember --remember-session --asterisks --sessions /run/current-system/sw/share/wayland-sessions";
              user = "greeter";
            };
          };
        };
      })
    ];
}
