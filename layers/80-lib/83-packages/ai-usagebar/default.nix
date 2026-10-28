{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libsecret,
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

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    gcc-unwrapped.lib
    glibc
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 ai-usagebar $out/bin/.ai-usagebar-wrapped
    install -Dm755 ai-usagebar-tui $out/bin/.ai-usagebar-tui-wrapped

    makeWrapper $out/bin/.ai-usagebar-wrapped $out/bin/ai-usagebar \
      --prefix PATH : ${lib.makeBinPath [ libsecret ]}

    makeWrapper $out/bin/.ai-usagebar-tui-wrapped $out/bin/ai-usagebar-tui \
      --prefix PATH : ${lib.makeBinPath [ libsecret ]}
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
