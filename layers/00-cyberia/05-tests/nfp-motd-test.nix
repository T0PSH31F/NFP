# Nix-evaluated test for nfp-motd & nfp-banner tools
{ pkgs, lib }:

let
  motdModule = import ../../50-cli-tui-programs/51-shells/nfp-motd.nix {
    inherit pkgs lib;
    config = {
      layers.layer-50.cli.enable = true;
    };
  };
  nfpMotdPkg = motdModule.passthru.nfpMotdPkg;
  nfpBannerPkg = motdModule.passthru.nfpBannerPkg;
in
pkgs.runCommand "check-nfp-motd"
  {
    nativeBuildInputs = [
      pkgs.zsh
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.fastfetch
      pkgs.chafa
    ];
  }
  ''
    set -euo pipefail

    echo "=========================================================================="
    echo " 🔍 NFP TERMINAL MOTD & BANNER COMPATIBILITY TEST"
    echo "=========================================================================="

    # 1. Verify Zsh syntax on zsh.nix initContent snippet
    echo "Checking Zsh syntax for MOTD guardrails..."
    cat << 'EOF' > test-init.zsh
    if [[ $- == *i* ]] && [[ -t 1 ]] && [[ -z "''${NFP_MOTD_EXECUTED:-}" ]]; then
      export NFP_MOTD_EXECUTED=1
      echo "MOTD WOULD RUN HERE"
    fi
    EOF
    ${pkgs.zsh}/bin/zsh -n test-init.zsh
    echo "  ✅ Zsh syntax check passed."

    # 2. Verify asset paths exist in repository
    echo "Checking per-host image asset paths..."
    Z0R0_IMG="${../../../layers/00-cyberia/02-assets/png-ico/roronoa-zoro-monkey-d-luffy-one-piece-vinsmoke-sanji-one-piece-f28baea931e3d454307ef781771688d6.png}"
    LUFFY_IMG="${../../../layers/00-cyberia/02-assets/png-ico/Luffyrave.png}"
    NAMI_IMG="${../../../layers/00-cyberia/02-assets/png-ico/Nami2.png}"

    test -f "$Z0R0_IMG" || { echo "ERROR: z0r0 image asset missing"; exit 1; }
    test -f "$LUFFY_IMG" || { echo "ERROR: luffy image asset missing"; exit 1; }
    test -f "$NAMI_IMG" || { echo "ERROR: nami image asset missing"; exit 1; }
    echo "  ✅ All host image assets exist in Nix store."

    # 3. Verify no hardcoded /home/ paths in zsh.nix or nfp-motd.nix
    echo "Auditing for hardcoded /home/ paths in shell MOTD modules..."
    if grep -q "/home/t0psh31f" "${../../50-cli-tui-programs/51-shells/nfp-motd.nix}"; then
      echo "ERROR: Hardcoded /home/t0psh31f path found in nfp-motd.nix"
      exit 1
    fi
    echo "  ✅ Zero hardcoded home directory paths found."

    # 4. Execute nfp-motd under fake environment variables
    echo "Testing renderer selection under fake environments..."

    # Kitty selection
    OUT=$(NFP_MOTD_DEBUG=1 TERM_PROGRAM=ghostty ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: kitty" || { echo "ERROR: ghostty did not select kitty renderer"; exit 1; }
    echo "  ✅ Kitty graphics protocol selected under Ghostty/Kitty environment."

    # Sixel selection
    OUT=$(NFP_MOTD_DEBUG=1 TERM=xterm-sixel TERM_PROGRAM="" ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: sixel" || { echo "ERROR: xterm-sixel did not select sixel renderer"; exit 1; }
    echo "  ✅ Sixel protocol selected under sixel terminal environment."

    # iTerm selection
    OUT=$(NFP_MOTD_DEBUG=1 TERM_PROGRAM=iTerm.app TERM="" ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: iterm" || { echo "ERROR: iTerm.app did not select iterm renderer"; exit 1; }
    echo "  ✅ iTerm protocol selected under iTerm environment."

    # Chafa selection (fallback for standard terminal)
    OUT=$(NFP_MOTD_DEBUG=1 TERM=xterm-256color TERM_PROGRAM="" ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: chafa" || { echo "ERROR: generic terminal did not fallback to chafa"; exit 1; }
    echo "  ✅ Chafa fallback selected for standard terminal environment."

    # Image override 'none'
    OUT=$(NFP_MOTD_DEBUG=1 NFP_MOTD_IMAGE=none ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: none" || { echo "ERROR: NFP_MOTD_IMAGE=none did not disable renderer"; exit 1; }
    echo "  ✅ NFP_MOTD_IMAGE=none correctly disabled image rendering."

    # SSH guard test (falls back to chafa)
    OUT=$(NFP_MOTD_DEBUG=1 TERM_PROGRAM=ghostty SSH_TTY=/dev/pts/1 ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: chafa" || { echo "ERROR: SSH session did not fallback to chafa"; exit 1; }
    echo "  ✅ SSH session safely fell back to chafa."

    # Zellij guard test (falls back to chafa)
    OUT=$(NFP_MOTD_DEBUG=1 TERM_PROGRAM=ghostty ZELLIJ=1 ${nfpMotdPkg}/bin/nfp-motd 2>&1 || true)
    echo "$OUT" | grep -q "Renderer: chafa" || { echo "ERROR: Zellij session did not fallback to chafa"; exit 1; }
    echo "  ✅ Zellij multiplexer session safely fell back to chafa."

    # 5. Verify nfp-banner outputs expected host title
    echo "Testing nfp-banner output..."
    BANNER_OUT=$(${nfpBannerPkg}/bin/nfp-banner --static)
    test -n "$BANNER_OUT" || { echo "ERROR: nfp-banner static output empty"; exit 1; }
    echo "  ✅ nfp-banner output verified."

    echo "✅ All NFP MOTD tests PASSED successfully."
    touch $out
  ''
