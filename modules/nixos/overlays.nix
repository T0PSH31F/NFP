# modules/nixos/overlays.nix
# Purpose:
# - Attach overlays for custom/local packages.
# - Desktop overlay will eventually be conditional on tags; for now
#   we can condition on system-profile.role or hostname as a stepping stone.

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);

  # Theme overlays adapter
  themeOverlays = import ../../overlays/default.nix { inherit inputs; };
  themeOverlay =
    final: prev: (themeOverlays.sonic-cursor final prev) // (themeOverlays.themes final prev);

  # Desktop overlay
  desktopOverlay = import ../../overlays/desktop-packages.nix;
in
{
  # Only apply desktop overlays if the machine has the "desktop" tag
  nixpkgs.overlays = lib.optionals (hasTag "desktop") [
    themeOverlay
    desktopOverlay
  ];
}
