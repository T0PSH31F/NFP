{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.gaming = {
    enable = mkEnableOption "Gaming support with Proton, Lutris, and emulators";

    enableSteam = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Steam with Proton support";
    };

    enableGamemode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GameMode for performance optimization";
    };

    enableEmulators = mkOption {
      type = types.bool;
      default = true;
      description = "Enable gaming emulators";
    };
  };

  config = mkIf config.gaming.enable {
    # Steam with Proton
    programs.steam = mkIf config.gaming.enableSteam {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      gamescopeSession.enable = true;

      # Proton support
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    # GameMode for performance
    programs.gamemode = mkIf config.gaming.enableGamemode {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };

    # Gaming packages
    environment.systemPackages = with pkgs;
      [
        # Wine and Proton alternatives
        lutris
        bottles
        heroic

        # Performance overlays and tools
        mangohud
        goverlay
        gamemode
        gamescope

        # Controller support
        antimicrox

        # Emulators (consolidated from home-manager)
      ]
      ++ optionals config.gaming.enableEmulators [
        retroarch
        # RetroArch cores
        (retroarch.override {
          cores = with libretro; [
            beetle-psx-hw
            snes9x
            genesis-plus-gx
            mupen64plus
            dolphin
            flycast
            ppsspp
            desmume
            mgba
          ];
        })

        # Standalone emulators
        bign-handheld-thumbnailer
        cemu
        dolphin-emu
        ppsspp
        rpcs3
        pcsx2
        duckstation
        melonDS
        sixpair # Pair with SIXAXIS controllers over USB

        # Nintendo Switch
        nx2elf # Convert Nintendo Switch executable files to ELFs
        ns-usbloader # All-in-one tool for managing Nintendo Switch homebrew

        hactool # Tool to manipulate common file formats for the Nintendo Switch
        fusee-interfacee-tk # Tool to send .bin files to a Nintendo Switch in RCM mode
        nstool # General purpose reading/extraction tool for Nintendo Switch file formats
        quark-goldleaf # GUI tool for transfering files between a computer and a Nintendo Switch running Goldleaf
        ryubing # Experimental Nintendo Switch Emulator written in C# (community fork of Ryujinx)
        joycond # Userspace daemon to combine joy-cons from the hid-nintendo kernel driver
        nsz # Homebrew compatible NSP/XCI compressor/decompressor
        usb-modeswitch # Mode switching tool for controlling 'multi-mode' USB devices
        usb-modeswitch-data # Device database and the rules file for 'multi-mode' USB devices
      ];

    # Enable 32-bit support for games
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Kernel parameters for gaming
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # For some games and programs
    };

    # Enable controller support
    hardware.xone.enable = mkDefault true; # Xbox One controller
    hardware.xpadneo.enable = mkDefault true; # Xbox controller Bluetooth

    # Firewall rules for gaming
    networking.firewall = {
      allowedTCPPorts = [
        # Steam Remote Play
        27036
        27037
      ];
      allowedUDPPorts = [
        # Steam Remote Play
        27031
        27036
      ];
    };

    # Performance tuning
    boot.kernelParams = [
      "split_lock_detect=off" # Some games have issues with this
    ];
  };
}
