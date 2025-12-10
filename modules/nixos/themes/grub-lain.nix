{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.themes.grub-lain = {
    enable = mkEnableOption "Lain GRUB theme";
  };

  config = mkIf config.themes.grub-lain.enable {
    # Use the GRUB 2 boot loader with Lain theme
    boot.loader.grub = {
      enable = true;
      device = mkDefault "nodev";
      efiSupport = mkDefault true;
      useOSProber = mkDefault true;

      # Lain theme configuration
      theme = pkgs.stdenv.mkDerivation {
        pname = "lain-grub-theme";
        version = "1.0";

        # Use local LainGrubTheme directory
        src = ./LainGrubTheme;

        installPhase = ''
          mkdir -p $out
          cp -r lain/* $out/
        '';
      };
    };

    # Disable systemd-boot when using GRUB theme
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = mkDefault true;
  };
}
