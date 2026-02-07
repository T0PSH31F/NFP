{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
  ];

  # Headless configuration
  services.xserver.enable = false;
  themes.sddm-lain.enable = false;
  themes.plymouth-hellonavi.enable = false; # Or maybe simpler plymouth

  # SSH hardening
  services.openssh.settings.PasswordAuthentication = lib.mkDefault false;
  services.openssh.settings.PermitRootLogin = lib.mkDefault "no";
}
