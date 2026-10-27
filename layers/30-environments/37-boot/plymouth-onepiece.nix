{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  speed = config.layers.layer-30.theming.themes.plymouth-onepiece.speed or "fast";

  onepiece-theme = pkgs.stdenv.mkDerivation {
    pname = "plymouth-theme-onepiece";
    version = "2026-unstable";

    src = pkgs.fetchFromGitHub {
      owner = "Anxhul10";
      repo = "onePiece-plymouth";
      rev = "ec9358d88e82367ba252781491654717605c719e";
      hash = "sha256-eZVLorbgnEz7Aff30j+PV2NNi8BuT6KgXJ0vmjncQfs=";
    };

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/onePiece-plymouth
      cp -r * $out/share/plymouth/themes/onePiece-plymouth/

      ${optionalString (speed == "slow") ''
        cp $out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth-slow.script \
           $out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script
      ''}

      substituteInPlace $out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.plymouth \
        --replace-fail "ImageDir=/usr/share/plymouth/themes/onePiece-plymouth" "ImageDir=$out/share/plymouth/themes/onePiece-plymouth" \
        --replace-fail "ScriptFile=/usr/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script" "ScriptFile=$out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script"
    '';
  };
in
{
  options.layers.layer-30.theming.themes.plymouth-onepiece = {
    enable = mkEnableOption "One Piece animated Plymouth boot splash";
    speed = mkOption {
      type = types.enum [
        "fast"
        "slow"
      ];
      default = "fast";
      description = "Animation speed for One Piece Plymouth theme (fast or slow)";
    };
  };

  config = mkIf config.layers.layer-30.theming.themes.plymouth-onepiece.enable {
    environment.systemPackages = [ onepiece-theme ];

    boot = {
      initrd = {
        systemd.enable = lib.mkDefault true;
        verbose = false;
      };

      plymouth = {
        enable = true;
        theme = "onePiece-plymouth";
        themePackages = [ onepiece-theme ];
        extraConfig = ''
          DeviceScale=1
        '';
      };

      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "rd.udev.log_level=3"
        "vt.global_cursor_default=0"
        "systemd.show_status=auto"
      ];
    };
  };
}
