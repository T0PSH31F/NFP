{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gcc-unwrapped,
  glibc,
}:

stdenv.mkDerivation rec {
  pname = "ai-usagebar";
  version = "1.45.0";

  src = fetchurl {
    url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${version}/ai-usagebar-linux-x86_64.tar.gz";
    hash = "sha256-iiYamK5TtNPUNxeW662WqhRyhLoNsRtmuK+I78uK6wE=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    gcc-unwrapped.lib
    glibc
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 ai-usagebar $out/bin/ai-usagebar
    install -Dm755 ai-usagebar-tui $out/bin/ai-usagebar-tui
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI and TUI tool to monitor AI provider usage and quotas";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ai-usagebar";
  };
}
