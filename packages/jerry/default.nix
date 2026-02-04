{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "jerry";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "justchokingaround";
    repo = "jerry";
    rev = "main";
    sha256 = "sha256-c13FD1B0XlnIQcLI3lrFiHWWpW2T/f1BGDBnSX4MIpc=";
  };

  # Adjust buildInputs and installPhase to whatever jerry actually needs
  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out/bin
    if [ -f jerry ]; then
      cp jerry $out/bin/
    else
      find . -maxdepth 1 -type f -executable -exec cp {} $out/bin/jerry \;
    fi
    chmod +x $out/bin/jerry
  '';

  meta = with lib; {
    description = "Jerry tool (desktop-only)";
    homepage = "https://github.com/justchokingaround/jerry";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
