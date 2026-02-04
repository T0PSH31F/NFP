# overlays/desktop-packages.nix
# Desktop-only packages overlay.
# This file should NOT import nixpkgs again; it should only extend the existing pkgs.

final: prev: {
  anifetch = prev.callPackage ../packages/anifetch { };
  jerry = prev.callPackage ../packages/jerry { };
  lobster = prev.callPackage ../packages/lobster { };
  vicinae = prev.callPackage ../packages/vicinae { };
  hypr-dynamic-cursors = prev.callPackage ../packages/hypr-dynamic-cursors { };
}
