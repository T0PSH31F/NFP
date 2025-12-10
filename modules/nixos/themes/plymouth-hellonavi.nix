{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  hellonavi-theme = pkgs.stdenv.mkDerivation {
    pname = "plymouth-theme-hellonavi";
    version = "unstable-2025-11-23";

    src = pkgs.fetchFromGitHub {
      owner = "yi78";
      repo = "hellonavi";
      rev = "master";
      hash = "sha256-0A79TB2fEDJ3O8pU/+aIFYuFtuGUBj5eYYjWK5IwF4A=";
    };

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/hellonavi
      cp -r hellonavi/* $out/share/plymouth/themes/hellonavi/

      # Fix path in .plymouth file if it references absolute paths
      sed -i "s@/usr/share/plymouth/themes/@$out/share/plymouth/themes/@" \
        $out/share/plymouth/themes/hellonavi/hellonavi.plymouth || true
    '';
  };
in {
  options.themes.plymouth-hellonavi = {
    enable = mkEnableOption "Plymouth HelloNavi theme";
  };

  config = mkIf config.themes.plymouth-hellonavi.enable {
    # Enable Plymouth
    boot.plymouth = {
      enable = true;
      theme = "hellonavi";
      themePackages = [hellonavi-theme];
    };

    # Enable silent boot for a clean plymouth experience
    boot.consoleLogLevel = 3;
    boot.kernelParams = ["quiet" "splash"];
  };
}
