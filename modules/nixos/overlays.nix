# modules/nixos/overlays.nix
# Purpose:
# - Attach overlays for custom/local packages.
# - Desktop overlay will eventually be conditional on tags; for now
#   we can condition on system-profile.role or hostname as a stepping stone.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDesktop =
    (config.system-profile.role or null) == "desktop" || config.networking.hostName == "z0r0"; # temporary safeguard
in
{
  # Overlays are now applied centrally in flake.nix
}
