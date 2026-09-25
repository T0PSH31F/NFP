{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-50.cli.nixTools = {
    enable = mkEnableOption "Nix development and helper tools";
  };

  config = mkIf config.layers.layer-50.cli.nixTools.enable {
    # NH - NixOS Helper
    # Provides cleaner commands: nh os switch, nh os boot, nh os test, etc.
    programs.nh = {
      enable = true;
      clean.enable = false;
      clean.extraArgs = "--keep-since 7d --keep 5";
      flake = "/home/t0psh31f/Clan/NFP";
    };

    # Install nom (Nix Output Monitor)
    # Usage: nom build, nom shell, etc. - prettier build output
    environment.systemPackages = with pkgs; [
      #nil
      any-nix-shell
      arion
      cached-nix-shell
      comma
      compose2nix
      deadnix
      dix
      envoluntary
      manix
      mcp-nixos
      nix-converter
      nix-diff
      nix-du
      nix-forecast
      nix-btm
      nix-health
      nix-heuristic-gc
      nix-fast-build
      nix-init
      nix-inspect
      nix-janitor
      nix-olde
      portaudio # libportaudio.so in sw/lib — required by hermes-agent sounddevice Voice mode (nix-ld list alone doesn't expose it)
      nix-output-monitor # nom command
      nix-search-cli
      nix-search-tv
      nix-serve-ng
      nix-sweep
      nix-top
      nix-tree # Interactive nix dependency tree viewer
      nix-unit
      nix-update
      nix-visualize
      nix-weather
      nix-your-shell
      nix-zsh-completions
      nixel
      nixd
      nixfmt-tree
      nixos-option
      nvd # Nix/NixOS package version diff tool
      omnix
      optinix
      optnix
      statix
      vulnix
    ];
    # Enable core system tools
    programs = {
      command-not-found.enable = false;
      nix-index = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
      };
      nix-ld = {
        enable = true;
        libraries = with pkgs; [
          SDL
          SDL2
          SDL2_image
          SDL2_mixer
          SDL2_ttf
          SDL_image
          SDL_mixer
          SDL_ttf
          alsa-lib
          at-spi2-atk
          at-spi2-core
          atk
          bzip2
          cairo
          cups
          curl
          dbus
          dbus-glib
          expat
          ffmpeg
          flac
          fontconfig
          freeglut
          freetype
          fuse3
          gdk-pixbuf
          glew_1_10
          glib
          gnome2.GConf
          pango
          gtk2
          gtk3
          icu
          libGL
          libappindicator-gtk2
          libappindicator-gtk3
          libcaca
          libcanberra
          libcanberra-gtk3 # canberra-gtk-play for warcraft-notifications plugin audio (force rebuild 2026-07-09)
          libcap
          libdbusmenu-gtk2
          libdrm
          libelf
          libgbm
          libgcrypt
          libglvnd
          libidn
          libindicator-gtk2
          libjpeg
          libmikmod
          libnotify
          libogg
          libpng
          libpng12
          libpulseaudio
          librsvg
          libsamplerate
          libtheora
          libtiff
          libudev0-shim
          libunwind
          libusb1
          libuuid
          libva
          libvdpau
          libvorbis
          libvpx
          libxkbcommon
          libxml2
          libz
          mesa
          nspr
          nss
          openssl
          pango
          pipewire
          pixman
          speex
          systemd
          tbb
          vulkan-loader
          libice
          libsm
          libx11
          libxscrnsaver
          libxcomposite
          libxcursor
          libxdamage
          libxext
          libxfixes
          libxft
          libxi
          libxinerama
          libxmu
          libxrandr
          libxrender
          libxt
          libxtst
          libxxf86vm
          libxcb
          libxshmfence
          zlib
          wayland # Required by oh-my-opencode-slim companion (Wayland GUI overlay)
          portaudio # Required by hermes-agent sounddevice Voice mode
        ];
      };
      nixbit = {
        enable = true;
        repository = "https://github.com/T0PSH31F/NFP.git";
      };
    };

    services.angrr = {
      enable = true;
      settings = {
        temporary-root-policies = {
          direnv = {
            path-regex = "/\\.direnv/";
            period = "14d";
          };
          result = {
            path-regex = "/result[^/]*$";
            period = "3d";
          };
          # You can define your own policies
          # ...
        };
        profile-policies = {
          system = {
            profile-paths = [ "/nix/var/nix/profiles/system" ];
            keep-since = "14d";
            keep-latest-n = 5;
            keep-booted-system = true;
            keep-current-system = true;
            # Since 0.2.4
            # "Grandfather-father-son" rotation scheme
            # See `man 5 angrr`
            keep-n-per-bucket = [
              {
                bucket-window = "1 day";
                bucket-amount = 7;
              }
              {
                bucket-window = "1 week";
                bucket-amount = 4;
              }
            ];
          };
          user = {
            enable = false; # Policies can be individually disabled
            profile-paths = [
              # `~` at the beginning will be expanded to the home directory of each discovered user
              "~/.local/state/nix/profiles/profile"
              "/nix/var/nix/profiles/per-user/root/profile"
            ];
            keep-since = "1d";
            keep-latest-n = 1;
          };
          # You can define your own policies
          # ...
        };
      };
    };

    # Helpful shell aliases for home-manager users
    home-manager.users.t0psh31f = {
      config = {
        programs = {
          nix-your-shell = {
            enable = true;
            enableZshIntegration = true;
            enableNushellIntegration = true;
            nix-output-monitor.enable = true;
          };
          nix-init.enable = true;
        };
      };
    };

    # Systemd resource limits for nix-daemon to prevent memory exhaustion
    systemd.services.nix-daemon.serviceConfig = {
      MemoryMax = "6G";
      MemoryHigh = "5.5G";
      OOMScoreAdjust = 500;
    };
  };
}
