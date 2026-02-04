{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  curl,
  jq,
}:

stdenv.mkDerivation rec {
  pname = "anifetch";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Notenlish";
    repo = "anifetch";
    rev = "main";
    sha256 = "sha256-51CYsoNhtrs87YQEkJ7SmzcLN+qhJBtg4/QFqOFYB5s=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    curl
    jq
  ];

  installPhase = ''
    mkdir -p $out/bin
    if [ -f anifetch ]; then
      cp anifetch $out/bin/
    else
      # Fallback if the script name is different
      find . -maxdepth 1 -type f -executable -exec cp {} $out/bin/anifetch \;
    fi
    chmod +x $out/bin/anifetch
    wrapProgram $out/bin/anifetch \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          jq
        ]
      }
  '';

  meta = with lib; {
    description = "Anime info fetcher";
    homepage = "https://github.com/Notenlish/anifetch";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
