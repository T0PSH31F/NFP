# Theme Package Build Tests
#
# These derivations test that theme packages build correctly.
# Run with: nix build .#checks.x86_64-linux.themes
{
  pkgs,
  lib,
  ...
}: let
  # Plymouth HelloNavi theme package
  plymouth-hellonavi = pkgs.stdenv.mkDerivation {
    pname = "plymouth-theme-hellonavi";
    version = "unstable-2025-11-23";

    src = pkgs.fetchFromGitHub {
      owner = "yi78";
      repo = "hellonavi";
      rev = "master";
      hash = "sha256-0A79TB2fEDJ3O8pU/+aIFYuFtuGUBj5eYYjWK5IwF4A=";
    };

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/hellonavi
      cp -r hellonavi/* $out/share/plymouth/themes/hellonavi/

      # Fix path in .plymouth file if it references absolute paths
      sed -i "s@/usr/share/plymouth/themes/@$out/share/plymouth/themes/@" \
        $out/share/plymouth/themes/hellonavi/hellonavi.plymouth || true
    '';
  };

  # SDDM Lain theme package
  sddm-lain = pkgs.stdenv.mkDerivation {
    pname = "sddm-lain-wired-theme";
    version = "0.1";
    src = pkgs.fetchFromGitHub {
      owner = "lll2yu";
      repo = "sddm-lain-wired-theme";
      rev = "6bd2074ff0c3eea7979f390ddeaa0d2b95e171b7";
      sha256 = "14l65d2vljqmgn91h5q6kkxwicjzcdz9k49wpjhmdfqky9wwg5xb";
    };
    installPhase = ''
      mkdir -p $out/share/sddm/themes/lain-wired
      cp -r * $out/share/sddm/themes/lain-wired/
    '';
  };
in {
  # Test that Plymouth theme builds
  plymouth-theme-builds = pkgs.runCommand "test-plymouth-theme" {} ''
    # Verify the theme package built
    test -d ${plymouth-hellonavi}/share/plymouth/themes/hellonavi
    test -f ${plymouth-hellonavi}/share/plymouth/themes/hellonavi/hellonavi.plymouth || \
      test -f ${plymouth-hellonavi}/share/plymouth/themes/hellonavi/*.png
    echo "Plymouth HelloNavi theme builds successfully!" > $out
  '';

  # Test that SDDM theme builds
  sddm-theme-builds = pkgs.runCommand "test-sddm-theme" {} ''
    # Verify the theme package built
    test -d ${sddm-lain}/share/sddm/themes/lain-wired
    ls ${sddm-lain}/share/sddm/themes/lain-wired/
    echo "SDDM Lain theme builds successfully!" > $out
  '';

  # Combined test
  all-themes = pkgs.runCommand "test-all-themes" {} ''
    echo "All theme packages build successfully!"
    echo "Plymouth: ${plymouth-hellonavi}"
    echo "SDDM: ${sddm-lain}"
    echo "" > $out
  '';
}
