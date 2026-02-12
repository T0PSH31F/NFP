# flake-parts/themes/sddm-sugar-dark.nix
# SDDM Sugar Dark theme with build-time matugen color extraction
# Colors are generated from the background image using Material You algorithm
# Reference: https://github.com/MarianArlt/sddm-sugar-dark
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.themes.sddm-sugar-dark;

  # Extract Material You colors from background image at build time
  matugen-colors = pkgs.runCommand "matugen-sddm-colors" {
    nativeBuildInputs = [ pkgs.matugen pkgs.jq ];
  } ''
    COLORS=$(matugen image "${cfg.background}" \
      --json hex --dry-run --mode ${cfg.matugen.scheme} 2>/dev/null)

    mkdir -p $out
    echo "$COLORS" | jq -r '.colors.primary.${cfg.matugen.scheme}' > $out/theme_color
    echo "$COLORS" | jq -r '.colors.tertiary.${cfg.matugen.scheme}' > $out/accent_color
    echo "$COLORS" | jq -r '.colors.surface.${cfg.matugen.scheme}' > $out/surface_color
    echo "$COLORS" | jq -r '.colors.on_surface.${cfg.matugen.scheme}' > $out/on_surface_color
  '';

  # Resolve colors: matugen-extracted or user-specified
  themeColor = if cfg.matugen.enable && cfg.background != ""
    then builtins.readFile "${matugen-colors}/surface_color"
    else cfg.themeColor;

  accentColor = if cfg.matugen.enable && cfg.background != ""
    then builtins.readFile "${matugen-colors}/accent_color"
    else cfg.accentColor;

  # Build a patched version of the theme with custom theme.conf
  sddm-sugar-dark-custom = pkgs.stdenv.mkDerivation {
    pname = "sddm-sugar-dark-custom";
    version = "1.2-custom";

    src = pkgs.fetchFromGitHub {
      owner = "MarianArlt";
      repo = "sddm-sugar-dark";
      rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
      sha256 = "sha256-flOspjpYezPvGZ6b4R/Mr18N7ogdOf9rlaCV+j25gXs=";
    };

    installPhase = ''
      mkdir -p $out/share/sddm/themes/sugar-dark

      # Copy all theme files
      cp -r * $out/share/sddm/themes/sugar-dark/

      ${optionalString (cfg.background != "") ''
        # Copy custom background into the theme directory
        cp "${cfg.background}" $out/share/sddm/themes/sugar-dark/background_custom
      ''}

      # Write customized theme.conf
      cat > $out/share/sddm/themes/sugar-dark/theme.conf << EOF
      [General]
      Background="${if cfg.background != "" then "background_custom" else ""}"
      ScaleImageCropped=${boolToString cfg.scaleImageCropped}
      ScreenWidth=${toString cfg.screenWidth}
      ScreenHeight=${toString cfg.screenHeight}

      ThemeColor="${removeSuffix "\n" themeColor}"
      AccentColor="${removeSuffix "\n" accentColor}"

      RoundCorners=${toString cfg.roundCorners}
      ScreenPadding=${toString cfg.screenPadding}

      Font="${cfg.font}"
      FontSize=${optionalString (cfg.fontSize != null) (toString cfg.fontSize)}

      ForceLastUser=true
      ForcePasswordFocus=true
      EOF
    '';
  };
in
{
  options.themes.sddm-sugar-dark = {
    enable = mkEnableOption "SDDM Sugar Dark theme";

    matugen = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Extract theme colors from the background image using matugen (Material You).
          When enabled, ThemeColor uses the surface color and AccentColor uses the
          tertiary color from the generated palette. Runs at build time — deterministic,
          no runtime overhead.
        '';
      };

      scheme = mkOption {
        type = types.enum [ "dark" "light" ];
        default = "dark";
        description = "Color scheme variant to extract from the background image";
      };
    };

    background = mkOption {
      type = types.str;
      default = "";
      description = ''
        Path to background image. Supports JPEG, PNG, GIF, BMP, TIFF.
        Leave empty to use the theme default.
        When matugen is enabled, colors are also extracted from this image.
      '';
    };

    scaleImageCropped = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to crop the background image to fill the screen";
    };

    screenWidth = mkOption {
      type = types.int;
      default = 1920;
      description = "Screen width in pixels (for background scaling)";
    };

    screenHeight = mkOption {
      type = types.int;
      default = 1080;
      description = "Screen height in pixels (for background scaling)";
    };

    themeColor = mkOption {
      type = types.str;
      default = "#1a1b26";
      description = "Main theme color (HEX). Overridden by matugen if enabled.";
    };

    accentColor = mkOption {
      type = types.str;
      default = "#f28fad";
      description = "Accent/hover color (HEX). Overridden by matugen if enabled.";
    };

    roundCorners = mkOption {
      type = types.int;
      default = 10;
      description = "Corner rounding radius for input fields and buttons";
    };

    screenPadding = mkOption {
      type = types.int;
      default = 0;
      description = "White space padding around the screen edges";
    };

    font = mkOption {
      type = types.str;
      default = "JetBrainsMono Nerd Font";
      description = "Font family for the login screen";
    };

    fontSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Font size in points (null = theme default)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(config.themes.sddm-sel.enable or false);
        message = "Cannot enable both themes.sddm-sugar-dark and themes.sddm-sel. Please disable one.";
      }
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sugar-dark";
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [
        sddm-sugar-dark-custom
        kdePackages.qtsvg
        kdePackages.qtdeclarative
        kdePackages.qt5compat
      ];
    };

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = [
      sddm-sugar-dark-custom
    ];
  };
}
