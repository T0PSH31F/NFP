{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "jerry";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "justchokingaround";
    repo = "jerry";
    # PINNED (2026-10-15): was `rev = "main"`, a moving ref that will drift
    # and break this FOD's hash on the next upstream push (same failure mode
    # as lazyskills/agentburn). This commit's tarball unpacks to exactly the
    # sha256 recorded below, so nothing else changed.
    # To bump: nix-prefetch-github justchokingaround/jerry --rev <new>, then
    # update `rev` + `sha256`.
    rev = "ad4329695cb59314fb0a5be5d22f6b7fc5a124ba";
    sha256 = "sha256-R7yNvYk2af4dVYn32qXaAb5RGzxNQ+H/+cqEP6Q3TPQ=";
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
