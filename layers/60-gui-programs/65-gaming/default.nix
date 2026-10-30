{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkDefault
    types
    ;
in
{
  options.layers.layer-60.gui.gaming = {
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

  nixos = mkIf config.layers.layer-60.gui.gaming.enable {
    programs = {
      steam = mkIf config.layers.layer-60.gui.gaming.enableSteam {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        extraPackages = with pkgs; [ util-linux ];
      };

      gamemode = mkIf config.layers.layer-60.gui.gaming.enableGamemode {
        enable = true;
        enableRenice = true;
        settings = {
          general.renice = 10;
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
          };
        };
      };

      fuse.enable = true;
    };

    environment.systemPackages =
      with pkgs;
      [
        antimicrox
        bottles
        gamemode
        goverlay
        mangohud
        vintagestory
        wineWow64Packages.stable
      ]
      ++ (lib.optionals config.layers.layer-60.gui.gaming.enableEmulators [
        (retroarch.withCores (
          cores: with cores; [
            beetle-psx-hw
            desmume
            dolphin
            flycast
            genesis-plus-gx
            mgba
            mupen64plus
            ppsspp
            snes9x
          ]
        ))
        cemu
        dolphin-emu
        hactool
        joycond
        melonds
        ns-usbloader
        nstool
        nsz
        nx2elf
        pcsx2
        rpcs3
        ryubing
        sixpair
        usb-modeswitch
        usb-modeswitch-data
      ]);

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      xone.enable = mkDefault true;
      xpadneo.enable = mkDefault true;
    };
    services = {
      input-remapper.enable = true;
      system76-scheduler.enable = true;
      udev.packages = with pkgs; [ ns-usbloader ];
    };
    networking.firewall = {
      allowedTCPPorts = [
        27036
        27037
      ];
      allowedUDPPorts = [
        27031
        27036
      ];
    };
  };

  home =
    { osConfig, ... }:
    mkIf osConfig.layers.layer-60.gui.gaming.enable {
      home.packages = with pkgs; [
        cartridges
        dwarf-fortress
        prismlauncher
        umu-launcher
        nero-umu
        protonplus
        protontricks
        steam-rom-manager
        wineWow64Packages.stable
        bottles
      ];

      programs.lutris = {
        enable = true;
        extraPackages = with pkgs; [
          mangohud
          winetricks
          gamescope
          gamemode
          umu-launcher
          util-linux
        ];
      };
    };
}
