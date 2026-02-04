{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  hyprcursor,
  hyprlang,
  hyprutils,
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
    hyprutils
  ];

  # Force pkg-config usage or manual include paths if Makefile is dumb
  env.NIX_CFLAGS_COMPILE = toString [
    "-I${lib.getDev hyprcursor}/include"
    "-I${lib.getDev hyprlang}/include"
    "-I${lib.getDev hyprutils}/include"
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
