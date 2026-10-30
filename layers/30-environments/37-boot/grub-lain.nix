{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.layers.layer-30.theming.themes.grub-lain = {
    enable = lib.mkEnableOption "Lain GRUB theme";
    efiInstallAsRemovable = lib.mkEnableOption "installing GRUB into the default EFI fallback path (/EFI/BOOT/BOOTX64.EFI)";
  };

  config = lib.mkIf config.layers.layer-30.theming.themes.grub-lain.enable {
    # Use the GRUB 2 boot loader with Lain theme
    boot.loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
        device = "nodev"; # EFI systems use nodev
        efiSupport = true;
        efiInstallAsRemovable = config.layers.layer-30.theming.themes.grub-lain.efiInstallAsRemovable;
        useOSProber = true;

        # Lain theme configuration
        theme = pkgs.stdenv.mkDerivation {
          pname = "lain-grub-theme";
          version = "1.0";

          # Use fetchFromGitHub for reproducibility
          # PINNED (2026-10-15): was `rev = "main"`, a moving ref that would
          # silently change the boot theme on every upstream push and eventually
          # break this FOD's hash (same failure mode as lazyskills/agentburn).
          # This commit's tarball unpacks to exactly the sha256 recorded below.
          # To bump: nix-prefetch-github uiriansan/LainGrubTheme --rev <new>.
          src = pkgs.fetchFromGitHub {
            owner = "uiriansan";
            repo = "LainGrubTheme";
            rev = "1cf38e3b46e26cfd9166613bb49669f27efab12c";
            sha256 = "117872vbaj19ynnjf4j49zs7cf5z3d6xk1jdiha49wbnaai0sg40";
          };

          installPhase = ''
            mkdir -p $out
            cp -r lain/* $out/
          '';
        };
      };

      # Disable systemd-boot when using GRUB theme (use mkForce to override base.nix)
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce (
        !config.layers.layer-30.theming.themes.grub-lain.efiInstallAsRemovable
      );
    };
  };
}
