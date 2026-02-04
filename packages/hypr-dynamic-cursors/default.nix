{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  hyprcursor,
  hyprlang,
}:

stdenv.mkDerivation rec {
  pname = "hypr-dynamic-cursors";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "VirtCode";
    repo = "hypr-dynamic-cursors";
    rev = "main";
    sha256 = "sha256-y61NGkedVL4krfEkPCpngsYxGujCYcx+ryBGVrgeszE=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    hyprcursor
    hyprlang
  ];

  installPhase = ''
    mkdir -p $out/share/icons
    cp -r * $out/share/icons/hypr-dynamic-cursors
  '';

  meta = with lib; {
    description = "Dynamic cursors for Hyprland";
    homepage = "https://github.com/VirtCode/hypr-dynamic-cursors";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
