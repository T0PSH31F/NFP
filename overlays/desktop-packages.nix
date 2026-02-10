# overlays/desktop-packages.nix
# Desktop-only packages overlay.
# This file should NOT import nixpkgs again; it should only extend the existing pkgs.

final: prev: {
  jerry = prev.callPackage ../packages/jerry { };
  lobster = prev.callPackage ../packages/lobster { };
  vicinae = prev.callPackage ../packages/vicinae { };
  hypr-dynamic-cursors = prev.hyprlandPlugins.hypr-dynamic-cursors;
}
