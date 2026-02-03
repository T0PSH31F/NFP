{
  sonic-cursor = final: prev: {
    sonic-cursor = final.callPackage ./sonic-cursor.nix { };
  };
  themes = final: prev: {
    lain-sddm-theme = final.callPackage ../modules/nixos/themes/lain-sddm-package.nix { };
  };
}
