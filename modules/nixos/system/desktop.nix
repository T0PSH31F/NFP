{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ../themes/sddm-lain.nix
    ../themes/plymouth-hellonavi.nix
    ../themes/grub-lain.nix
  ];

  # Enable common desktop services
  services.printing.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  hardware.bluetooth.powerOnBoot = lib.mkDefault true;

  # Enable Sound (Pipewire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Default Themes
  themes.sddm-lain.enable = lib.mkDefault true;
  themes.plymouth-hellonavi.enable = lib.mkDefault true;
  themes.grub-lain.enable = lib.mkDefault true;

  # Gaming (optional defaults)
  # gaming.enable = lib.mkDefault true;
}
