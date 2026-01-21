{
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "sonic-cursor";
  version = "1.0";

  src = ../packages/Sonic-cursor-hyprcursor;

  installPhase = ''
    runHook preInstall

    # Install to icons directory (standard cursor location)
    mkdir -p $out/share/icons/Sonic-cursor-hyprcursor
    cp -r * $out/share/icons/Sonic-cursor-hyprcursor/

    # Install to hyprcursor themes directory (hyprcursor-specific)
    mkdir -p $out/share/hyprcursor/themes/Sonic-cursor-hyprcursor
    cp -r * $out/share/hyprcursor/themes/Sonic-cursor-hyprcursor/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Sonic cursor theme for Hyprcursor";
    platforms = platforms.linux;
  };
}
