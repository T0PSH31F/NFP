# Unified Cursor Theming Module
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  mkBibataHyprcursor =
    {
      pname,
      version,
      url,
      hash,
      folderName,
      description,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {
        inherit url hash;
      };
      nativeBuildInputs = [
        pkgs.hyprcursor
        pkgs.xcur2png
      ];
      sourceRoot = ".";
      buildPhase = ''
                hyprcursor-util --extract "${folderName}"
                cat << 'EOF' > "extracted_${folderName}/manifest.hl"
        name = ${folderName}
        description = ${description}
        version = ${version}
        cursors_directory = hyprcursors
        EOF
                hyprcursor-util --create "extracted_${folderName}"
      '';
      installPhase = ''
        mkdir -p $out/share/icons/${folderName}
        cp -r "${folderName}/cursors" $out/share/icons/${folderName}/
        cp "${folderName}/index.theme" $out/share/icons/${folderName}/
        cp -r "theme_${folderName}/hyprcursors" $out/share/icons/${folderName}/
        cp "extracted_${folderName}/manifest.hl" $out/share/icons/${folderName}/
      '';
    };

  bibata-rainbow = mkBibataHyprcursor {
    pname = "bibata-rainbow-hyprcursor";
    version = "1.1.2";
    url = "https://github.com/ful1e5/Bibata_Cursor_Rainbow/releases/download/v1.1.2/Bibata-Rainbow-Modern.tar.gz";
    hash = "sha256-uwjLgMSexsvxRcebAt36WkkQw2aVIJ+t/zai0iHMK5A=";
    folderName = "Bibata-Rainbow-Modern";
    description = "Bibata Rainbow Modern animated hyprcursor";
  };

  bibata-zebra = mkBibataHyprcursor {
    pname = "bibata-zebra-hyprcursor";
    version = "1.0.0";
    url = "https://github.com/ful1e5/Bibata-Zebra-Cursor/releases/download/v1.0.0/Bibata-Zebra-Modern.tar.gz";
    hash = "sha256-ZPsJU2Vz2hJCN/gny4ejJW29EPVQ3MVFFbnIleA5Qcs=";
    folderName = "Bibata-Zebra-Modern";
    description = "Bibata Zebra Modern animated hyprcursor";
  };

  bibata-bee = mkBibataHyprcursor {
    pname = "bibata-bee-hyprcursor";
    version = "1.0.0";
    url = "https://github.com/ful1e5/Bibata-Bee-Cursor/releases/download/v1.0.0/Bibata-Bee-Modern.tar.gz";
    hash = "sha256-HVMKMqh74K0qqALik7sbQ0ZETZtgbH5JFM/W3eiXhXE=";
    folderName = "Bibata-Bee-Modern";
    description = "Bibata Bee Modern animated hyprcursor";
  };

  sonic-hyprcursor = pkgs.stdenv.mkDerivation {
    pname = "sonic-hyprcursor";
    version = "1.0.0";
    src = ../../00-cyberia/02-assets/cursors/Sonic-cursor-hyprcursor;
    installPhase = ''
      mkdir -p $out/share/icons/Sonic-Hyprcursor
      cp -r Sonic-Hyprcursor/* $out/share/icons/Sonic-Hyprcursor/
    '';
  };

  cursorThemes = {
    "Bibata-Rainbow-Modern" = {
      package = bibata-rainbow;
      name = "Bibata-Rainbow-Modern";
    };
    "Bibata-Zebra-Modern" = {
      package = bibata-zebra;
      name = "Bibata-Zebra-Modern";
    };
    "Bibata-Bee-Modern" = {
      package = bibata-bee;
      name = "Bibata-Bee-Modern";
    };
    "Sonic-Hyprcursor" = {
      package = sonic-hyprcursor;
      name = "Sonic-Hyprcursor";
    };
  };

  selectedTheme = cursorThemes.${cfg.theme} or cursorThemes."Bibata-Rainbow-Modern";
  cfg = osConfig.layers.layer-30.theming.cursor;
in
{
  options.layers.layer-30.theming.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable custom cursor themes";
    };

    theme = lib.mkOption {
      type = lib.types.enum [
        "Bibata-Rainbow-Modern"
        "Bibata-Zebra-Modern"
        "Bibata-Bee-Modern"
        "Sonic-Hyprcursor"
      ];
      default = "Bibata-Rainbow-Modern";
      description = "Cursor theme to activate (Bibata Rainbow, Zebra, Bee, or Sonic)";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Size of the cursor (e.g. 24, 32, 48, 64)";
    };
  };

  # System level packages for cursor
  nixos = lib.mkIf cfg.enable {
    environment.systemPackages = [
      selectedTheme.package
      bibata-rainbow
      bibata-zebra
      bibata-bee
      sonic-hyprcursor
    ];
  };

  # Home Manager pointerCursor settings
  home = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        hyprcursor
        selectedTheme.package
        bibata-rainbow
        bibata-zebra
        bibata-bee
        sonic-hyprcursor
      ];

      activation.cleanSonicCursor = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        for target in "Bibata-Rainbow-Modern" "Bibata-Zebra-Modern" "Bibata-Bee-Modern" "Sonic-Hyprcursor" "rose-pine"; do
          for path in "$HOME/.local/share/icons/$target" "$HOME/.icons/$target"; do
            if [ -d "$path" ] && [ ! -L "$path" ]; then
              echo "Removing physical directory $path to avoid Home Manager symlink conflict"
              rm -rf "$path"
            fi
          done
        done
      '';

      pointerCursor = {
        enable = lib.mkForce true;
        package = lib.mkForce selectedTheme.package;
        name = lib.mkForce selectedTheme.name;
        size = lib.mkForce cfg.size;
        gtk.enable = lib.mkForce true;
        x11.enable = lib.mkForce true;
        hyprcursor = {
          enable = lib.mkForce true;
          size = lib.mkForce cfg.size;
        };
      };
    };
  };
}
