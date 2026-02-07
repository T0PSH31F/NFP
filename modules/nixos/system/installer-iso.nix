{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    # Installer needs some desktop tools usually
  ];

  # Ensure installer can boot
  boot.loader.timeout = lib.mkForce 10;
}
