{
  config,
  lib,
  pkgs,
  osConfig ? config,
  inputs,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;

  # ── Screenshot script: save to file + copy to clipboard ────────────
  hypr-screenshot = pkgs.writeShellScriptBin "hypr-screenshot" ''
    set -e
    MODE="''${1:-region}"
    SAVE_DIR="''${HOME}/Pictures/Screenshots"
    TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
    FILENAME="screenshot-$TIMESTAMP.png"

    mkdir -p "$SAVE_DIR"

    case "$MODE" in
      region)
        grim -g "$(slurp)" - | tee "$SAVE_DIR/$FILENAME" | wl-copy
        ;;
      full)
        grim - | tee "$SAVE_DIR/$FILENAME" | wl-copy
        ;;
      edit)
        grim -g "$(slurp)" - | swappy -f -
        exit $?
        ;;
      edit-full)
        grim - | swappy -f -
        exit $?
        ;;
      *)
        echo "Usage: hypr-screenshot {region|full|edit|edit-full}"
        exit 1
        ;;
    esac

    notify-send -t 2000 -u low -i camera-photo "Screenshot saved" "$FILENAME → clipboard + $SAVE_DIR"
  '';
in
{
  options.layers.layer-40.desktop.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Hyprland Desktop Environment";
    };

    isNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Internal: True if the machine has NVIDIA hardware enabled";
    };

    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Internal: True if the machine is a laptop";
    };
  };

  nixos = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;

    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };

  # Home Manager level config
  home =
    { config, ... }:
    {
      imports = lib.optionals cfg.enable [
        ./scripts.nix
        ./monitors.nix
        ./animations.nix
        ./keybinds.nix
        ./rules.nix
        ./uwsm.nix
      ];

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          awww
          cliphist
          grim
          wl-freeze
          hypr-screenshot
          hyprkeys
          hyprland-autoname-workspaces
          hyprland-qt-support
          hyprlax
          hyprlang
          hyprls
          hyprmon
          hyprpolkitagent
          hyprpwcenter
          hyprsysteminfo
          hyprviz
          libnotify
          playerctl
          pyprland
          rofi
          slurp
          swappy
          swayimg
          swaynotificationcenter
          wev
          wl-clipboard
          xdg-user-dirs
          xdg-utils
          kdePackages.kde-cli-tools
          kdePackages.kservice
        ];

        xdg.configFile."menus/applications.menu".source =
          "${pkgs.kdePackages.kde-cli-tools}/etc/xdg/menus/applications.menu";

        # Swappy screenshot tool config → save to ~/Pictures/Screenshots
        xdg.configFile."swappy/config".text = ''
          [Default]
          save_dir=$HOME/Pictures/Screenshots
        '';

        # Ensure screenshots directory exists
        systemd.user.tmpfiles.rules = [
          "d %h/Pictures/Screenshots 0755 - - -"
        ];

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "hyprlang";
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage =
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
          # Disabled: UWSM manages systemd integration (targets, env vars, session lifecycle).
          # Enabling this causes exec-once/exec-shutdown to fight UWSM over hyprland-session.target.
          systemd.enable = false;
          plugins = [
            inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
          ];

          settings = {
            source = [
              "${config.home.homeDirectory}/.config/hypr/experiences/active-experience.conf"
              "${config.home.homeDirectory}/.config/hypr/monitors.conf"
              "${config.home.homeDirectory}/.config/hypr/hyprviz.conf"
            ];

            # Color variables ($primary, $secondary, $surfaceContainer) are
            # provided by active experience templates via the source above.
            # Do NOT hardcode them here.

            plugin = {
              "dynamic-cursors" = {
                enabled = true;
                mode = "rotate";
                threshold = 2;
                tilt = {
                  limit = 3000;
                };
                stretch = {
                  limit = 3000;
                  function = "quadratic";
                };
                shake = {
                  enabled = false;
                  effects = false;
                  ipc = true;
                };
              };
            };

            decoration = {
              screen_shader = "${config.home.homeDirectory}/.config/hypr/vibrancy.frag";
            };

            exec-once = [
              "dbus-update-activation-environment --systemd --all &"
              "systemctl --user import-environment PATH &"
              "pypr & disown"
              "hypr-sfx & disown"
              "udiskie & disown"
              "${pkgs.pipewire}/bin/pw-play ~/Clan/NFP/layers/00-cyberia/02-assets/SFX/login-sound.mp3 & disown"
            ];

            exec-shutdown = [
              "${pkgs.pipewire}/bin/pw-play ~/Clan/NFP/layers/00-cyberia/02-assets/SFX/shutdown-sound.mp3"
            ];

            general = {
              border_size = 4;
              # Border colors ($primary, $surface) are provided by active experience
              # templates — do NOT override here.
              resize_on_border = true;
              layout = "dwindle";
            };

            input = {
              kb_options = "caps:escape";
            };
            cursor = {
              no_hardware_cursors = cfg.isNvidia; # Only disable for NVIDIA
              # Cursor size is set via XCURSOR_SIZE / HYPRCURSOR_SIZE env vars in uwsm.nix
            };

            # NVIDIA stability fixes (no-op on Intel/AMD)
            # render = lib.mkIf cfg.isNvidia {
            #   direct_scanout = false;   # Prevent buffer format mismatches on NVIDIA multi-monitor
            # };
          };
        };

        xdg.configFile."hypr/vibrancy.frag".source = ../../../layers/00-cyberia/02-assets/vibrancy.frag;
        xdg.configFile."hypr/hyprland.conf".force = true;
        xdg.configFile."hypr/pyprland.toml".text = ''
          [pyprland]
          plugins = ["scratchpads"]

          [scratchpads.term]
          animation = "fromTop"
          command = "ghostty --class=ghostty-dropdown"
          class = "ghostty-dropdown"
          size = "100% 50%"
          lazy = true

          [scratchpads.gedit]
          animation = "fromRight"
          command = "gedit"
          class = "gedit"
          size = "75% 60%"
          position = "center"
          lazy = true

          [scratchpads.nwglook]
          animation = "fromBottom"
          command = "nwg-look"
          class = "nwg-look"
          size = "60% 60%"
          position = "center"
          lazy = true
        '';

        systemd.user.services.hyprland-init-files = {
          Unit = {
            Description = "Ensure Hyprland optional configuration files exist";
            Before = [ "graphical-session-pre.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session-pre.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config/hypr/experiences && for f in %h/.config/hypr/experiences/active-experience.conf %h/.config/hypr/monitors.conf %h/.config/hypr/hyprviz.conf; do [ -e \"$f\" ] || [ -L \"$f\" ] || touch \"$f\" 2>/dev/null || true; done'";

          };
        };

        xdg.enable = true;
      };
    };
}
