# pkgs/sonic-cursor.nix
{
  lib,
  stdenv,
  hyprcursor,
  librsvg,
  ...
}:

stdenv.mkDerivation {
  pname = "sonic-cursor-hyprcursor";
  version = "1.0.1";

  src = ../packages/Sonic-cursor-hyprcursor;

  nativeBuildInputs = [
    hyprcursor
    librsvg
  ];

  dontWrapQtApps = true;
  dontBuild = true;

  installPhase = ''
        runHook preInstall

        # Install to icons directory (standard X11 cursor location)
        mkdir -p $out/share/icons/Sonic-cursor-hyprcursor
        cp -r * $out/share/icons/Sonic-cursor-hyprcursor/

        # Install to hyprcursor themes directory
        mkdir -p $out/share/hyprcursor/themes/Sonic-cursor-hyprcursor
        cp -r * $out/share/hyprcursor/themes/Sonic-cursor-hyprcursor/

        # Create cursor theme index if it doesn't exist
        if [ ! -f "$out/share/icons/Sonic-cursor-hyprcursor/index.theme" ]; then
          cat > $out/share/icons/Sonic-cursor-hyprcursor/index.theme << EOF
    [Icon Theme]
    Name=Sonic Cursor Hyprcursor
    Comment=Sonic-themed cursor for Hyprland
    EOF
        fi

        runHook postInstall
  '';

  meta = with lib; {
    description = "Sonic cursor theme optimized for Hyprcursor";
    homepage = "https://github.com/T0PSH31F/Grandlix-Gang";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.t0psh31f or { } ];
  };
}
