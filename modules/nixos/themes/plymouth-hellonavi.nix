{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  # Option for color variant
  colorVariant = config.themes.plymouth-hellonavi.color or "blue";

  # Base hellonavi theme from GitHub
  hellonavi-base = pkgs.fetchFromGitHub {
    owner = "yi78";
    repo = "hellonavi";
    rev = "a369222fc7943e0ad59be710a5c6cf6b0137f309";
    hash = "sha256-0A79TB2fEDJ3O8pU/+aIFYuFtuGUBj5eYYjWK5IwF4A=";
  };

  # Build theme with optional color modification using ImageMagick
  hellonavi-theme = pkgs.stdenv.mkDerivation {
    pname = "plymouth-theme-hellonavi";
    version = "unstable-2025-11-23";

    src = hellonavi-base;

    nativeBuildInputs = lib.optionals (colorVariant == "red") [ pkgs.imagemagick ];

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/hellonavi
      cp -r hellonavi/* $out/share/plymouth/themes/hellonavi/

      # Fix path in .plymouth file if it references absolute paths
      # Use @ as delimiter to avoid issues with paths containing /
      sed -i "s@/usr/share/plymouth/themes/@$out/share/plymouth/themes/@g" \
        $out/share/plymouth/themes/hellonavi/hellonavi.plymouth || true

      # Ensure ImageDir and ScriptFile point to the correct location
      sed -i "s@ImageDir=.*@ImageDir=$out/share/plymouth/themes/hellonavi@" \
        $out/share/plymouth/themes/hellonavi/hellonavi.plymouth
      sed -i "s@ScriptFile=.*@ScriptFile=$out/share/plymouth/themes/hellonavi/hellonavi.script@" \
        $out/share/plymouth/themes/hellonavi/hellonavi.plymouth

      ${lib.optionalString (colorVariant == "red") ''
        # Convert blue to red using ImageMagick hue rotation
        # Blue is around 210-240 degrees, Red is around 0-30 degrees
        # Hue rotate by approximately -60 to shift blue towards red
        for img in $out/share/plymouth/themes/hellonavi/img/*.png; do
          ${pkgs.imagemagick}/bin/convert "$img" \
            -modulate 100,100,80 \
            "$img.tmp" && mv "$img.tmp" "$img"
        done
      ''}
    '';
  };
in
{
  options.themes.plymouth-hellonavi = {
    enable = mkEnableOption "Plymouth HelloNavi theme";
    color = mkOption {
      type = types.enum [
        "blue"
        "red"
      ];
      default = "blue";
      description = "Color variant of the hellonavi animation (blue or red)";
    };
  };

  config = mkIf config.themes.plymouth-hellonavi.enable {
    # Enable systemd initrd for proper Plymouth support
    boot.initrd.systemd.enable = lib.mkDefault true;

    # Ensure GPU driver is loaded early for Plymouth framebuffer
    # This is CRITICAL for Plymouth to work on boot (not just shutdown)
    boot.initrd.availableKernelModules = lib.mkAfter [
      "i915" # Intel GPU
      "amdgpu" # AMD GPU
      "nouveau" # NVIDIA open-source
    ];

    # Install the theme package to system
    environment.systemPackages = [ hellonavi-theme ];

    # Enable Plymouth
    boot.plymouth = {
      enable = true;
      theme = "hellonavi";
      themePackages = [ hellonavi-theme ];
      # Force fbdev console for better vt transition
      extraConfig = ''
        DeviceScale=1
      '';
    };

    # Enable silent boot for a clean plymouth experience
    boot.consoleLogLevel = 0;
    boot.kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
      "systemd.show_status=auto"
      # CRITICAL for Plymouth on boot: Early KMS for Intel
      "i915.modeset=1"
      "i915.fastboot=1"
    ];

    # Hide kernel messages during boot
    boot.initrd.verbose = false;
  };
}
