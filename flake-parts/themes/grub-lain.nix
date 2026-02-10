{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.themes.grub-lain = {
    enable = lib.mkEnableOption "Lain GRUB theme";
  };

  config = lib.mkIf config.themes.grub-lain.enable {
    # Use the GRUB 2 boot loader with Lain theme
    boot.loader.grub = {
      enable = true;
      configurationLimit = 2;
      device = "nodev"; # EFI systems use nodev
      efiSupport = true;
      efiInstallAsRemovable = false;
      useOSProber = true;

      # Lain theme configuration
      theme = pkgs.stdenv.mkDerivation {
        pname = "lain-grub-theme";
        version = "1.0";

        # Use fetchFromGitHub for reproducibility
        src = pkgs.fetchFromGitHub {
          owner = "uiriansan";
          repo = "LainGrubTheme";
          rev = "main"; # Use main branch as default
          sha256 = "117872vbaj19ynnjf4j49zs7cf5z3d6xk1jdiha49wbnaai0sg40";
        };

        installPhase = ''
          mkdir -p $out
          cp -r lain/* $out/
        '';
      };
    };

    # Disable systemd-boot when using GRUB theme (use mkForce to override base.nix)
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce true;
  };
}
