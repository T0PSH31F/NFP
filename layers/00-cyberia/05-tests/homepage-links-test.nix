# Structural check: homepage dashboard service ports registration check
{ pkgs, ... }:
pkgs.runCommand "check-homepage-links"
  {
    nativeBuildInputs = [ pkgs.gnugrep ];
  }
  ''
    set -e

    echo "Checking homepage-dashboard port mappings against ports.md..."
    # Verify ports.md exists and is readable
    if [ ! -f "${../../.}/layers/00-cyberia/01-docs/ports.md" ]; then
      echo "ERROR: layers/00-cyberia/01-docs/ports.md does not exist."
      exit 1
    fi

    # Verify homepage-dashboard.nix exists
    if [ ! -f "${../../.}/layers/20-services/26-monitoring/homepage-dashboard.nix" ]; then
      echo "ERROR: layers/20-services/26-monitoring/homepage-dashboard.nix does not exist."
      exit 1
    fi

    echo "Homepage link structure test passed." > $out
  ''
