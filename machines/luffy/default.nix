{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
    ../../modules/Desktop-env/default.nix
    ../../modules/users/t0psh31f.nix
  ];

  networking.hostName = "luffy";

  # Desktop Environment Selection
  desktop.omarchy.enable = false;
  desktop.caelestia.enable = false;
  desktop.illogical.enable = true;

  # Plymouth Theme
  themes.plymouth-hellonavi.enable = true;
  themes.plymouth-matrix.enable = false;

  system.stateVersion = "25.05";
}
