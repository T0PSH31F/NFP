{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  git,
}:

stdenv.mkDerivation rec {
  pname = "vicinae";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "main";
    hash = "sha256-hQSS4c3mLZMCDDeP04s5YhzobVyo7K2Ib9bA8sK/7Xo=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    git
  ];
  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out/bin
    if [ -f vicinae ]; then
      cp vicinae $out/bin/
    else
      find . -maxdepth 1 -type f -executable -exec cp {} $out/bin/vicinae \;
    fi
    chmod +x $out/bin/vicinae
  '';

  meta = with lib; {
    description = "Vicinae desktop utility";
    homepage = "https://github.com/vicinaehq/vicinae";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
