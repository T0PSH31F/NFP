{
  pkgs,
  lib,
  ...
}:

pkgs.stdenv.mkDerivation rec {
  pname = "lain-sddm-theme";
  version = "2024-09-10";

  src = pkgs.fetchFromGitHub {
    owner = "Yangmoooo";
    repo = "lain-sddm-theme";
    rev = "04cc104e470b30e1d12ae9cb94f293ad4effc7f9";
    sha256 = "sha256-c+LuCWwZAvxetxdYCPzpb2EqmiUZIxxrJJxAoA5tilc=";
  };

  nativeBuildInputs = with pkgs; [
    qt6.qttools
    qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    qt6.qtbase
    qt6.qtsvg
    qt6.qtmultimedia
  ];

  dontWrapQtApps = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes/lain-sddm-theme
    cp -r * $out/share/sddm/themes/lain-sddm-theme/

    # Ensure proper permissions for media files
    find $out/share/sddm/themes/lain-sddm-theme -type f -name "*.wav" -exec chmod 644 {} \;
    find $out/share/sddm/themes/lain-sddm-theme -type f -name "*.sh" -exec chmod +x {} \;

    runHook postInstall
  '';

  meta = with lib; {
    description = "Serial Experiments Lain SDDM theme (QT6 fork with audio)";
    homepage = "https://github.com/Yangmoooo/lain-sddm-theme";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
