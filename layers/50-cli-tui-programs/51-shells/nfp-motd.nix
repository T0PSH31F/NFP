# layers/50-cli-tui-programs/51-shells/nfp-motd.nix
# Resilient Nix-native per-host terminal MOTD & banner tools
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.layers.layer-50.cli;

  # Image Assets
  z0r0Asset = ../../../layers/00-cyberia/02-assets/png-ico/roronoa-zoro-monkey-d-luffy-one-piece-vinsmoke-sanji-one-piece-f28baea931e3d454307ef781771688d6.png;
  luffyAsset = ../../../layers/00-cyberia/02-assets/png-ico/Luffyrave.png;
  namiAsset = ../../../layers/00-cyberia/02-assets/png-ico/Nami2.png;

  # Banner Executable Script
  nfpBannerPkg = pkgs.writeShellScriptBin "nfp-banner" ''
    set -euo pipefail

    HOST="$(hostname 2>/dev/null || echo "unknown")"

    case "$HOST" in
      z0r0*) TITLE="Z0R0"; SUBTITLE="RORONOA ZORO // DAILY-DRIVER WORKSTATION" ;;
      luffy*) TITLE="LUFFY"; SUBTITLE="MONKEY D. LUFFY // HOMELAB" ;;
      nami*) TITLE="NAMI"; SUBTITLE="CAT BURGLAR NAMI // CONTROL PLANE" ;;
      *) TITLE="NFP"; SUBTITLE="NIX FLAKE PIRATES" ;;
    esac

    CURATED_EFFECTS=("decrypt" "beams" "matrix" "fireworks" "spotlights" "rain" "scattered")

    show_help() {
      echo "Usage: nfp-banner [OPTIONS]"
      echo "Options:"
      echo "  --static             Print static host banner (default)"
      echo "  --animate            Run TerminalTextEffects animation"
      echo "  --effect <name>      Run specific TTE effect"
      echo "  --list-effects       List curated TTE effects"
      echo "  --help               Show this help message"
    }

    if [ "''${1:-}" = "--list-effects" ]; then
      echo "Curated TerminalTextEffects for NFP:"
      for eff in "''${CURATED_EFFECTS[@]}"; do
        echo "  - $eff"
      done
      exit 0
    fi

    if [ "''${1:-}" = "--help" ]; then
      show_help
      exit 0
    fi

    generate_banner_text() {
      if command -v ${pkgs.figlet}/bin/figlet >/dev/null 2>&1 && command -v ${pkgs.lolcat}/bin/lolcat >/dev/null 2>&1; then
        ${pkgs.figlet}/bin/figlet -c "$TITLE" | ${pkgs.lolcat}/bin/lolcat -f
        echo "=== $SUBTITLE ==="
      else
        echo "=========================================================================="
        echo "  $TITLE // $SUBTITLE"
        echo "=========================================================================="
      fi
    }

    ANIMATE=0
    EFFECT="decrypt"

    if [ "''${1:-}" = "--animate" ]; then
      ANIMATE=1
    elif [ "''${1:-}" = "--effect" ] && [ -n "''${2:-}" ]; then
      ANIMATE=1
      EFFECT="$2"
    fi

    if [ "$ANIMATE" = "1" ] && [ -z "''${NO_COLOR:-}" ] && command -v ${pkgs.terminaltexteffects}/bin/tte >/dev/null 2>&1; then
      generate_banner_text | ${pkgs.terminaltexteffects}/bin/tte "$EFFECT" 2>/dev/null || generate_banner_text
    else
      generate_banner_text
    fi
  '';

  motdAnimatePkg = pkgs.writeShellScriptBin "motd-animate" ''
    exec ${nfpBannerPkg}/bin/nfp-banner --animate "$@"
  '';

  # MOTD Main Executable Script
  nfpMotdPkg = pkgs.writeShellScriptBin "nfp-motd" ''
    set -euo pipefail

    HOST="$(hostname 2>/dev/null || echo "unknown")"
    MOTD_IMAGE_MODE="''${NFP_MOTD_IMAGE:-auto}"
    MOTD_SIZE_MODE="''${NFP_MOTD_SIZE:-normal}"
    MOTD_DEBUG="''${NFP_MOTD_DEBUG:-0}"

    log_debug() {
      if [ "$MOTD_DEBUG" = "1" ]; then
        echo "[nfp-motd debug] $1" >&2
      fi
    }

    case "$MOTD_SIZE_MODE" in
      compact) LOGO_WIDTH=25; LOGO_HEIGHT=14 ;;
      large)   LOGO_WIDTH=48; LOGO_HEIGHT=28 ;;
      normal|*) LOGO_WIDTH=36; LOGO_HEIGHT=20 ;;
    esac

    IMAGE_PATH=""
    HOST_LABEL=""

    case "$HOST" in
      z0r0*)
        IMAGE_PATH="${z0r0Asset}"
        HOST_LABEL="Z0R0 // RORONOA ZORO // DAILY-DRIVER WORKSTATION"
        ;;
      luffy*)
        IMAGE_PATH="${luffyAsset}"
        HOST_LABEL="LUFFY // MONKEY D. LUFFY // HOMELAB"
        ;;
      nami*)
        IMAGE_PATH="${namiAsset}"
        HOST_LABEL="NAMI // CAT BURGLAR NAMI // CONTROL PLANE"
        ;;
      *)
        IMAGE_PATH="${namiAsset}"
        HOST_LABEL="NFP // NIX FLAKE PIRATES"
        ;;
    esac

    RENDERER="none"

    if [ "$MOTD_IMAGE_MODE" = "none" ]; then
      RENDERER="none"
    elif [ "$MOTD_IMAGE_MODE" != "auto" ]; then
      RENDERER="$MOTD_IMAGE_MODE"
    else
      if [ -n "''${SSH_CLIENT:-}" ] || [ -n "''${SSH_TTY:-}" ] || [ -n "''${TMUX:-}" ] || [ -n "''${ZELLIJ:-}" ]; then
        if command -v ${pkgs.chafa}/bin/chafa >/dev/null 2>&1; then
          RENDERER="chafa"
        else
          RENDERER="none"
        fi
      else
        case "''${KITTY_WINDOW_ID:-}:''${TERM:-}:''${TERM_PROGRAM:-}" in
          *:*kitty*:*|*:*ghostty*:*|*:*:ghostty|*:*:kitty|*:*:WezTerm)
            RENDERER="kitty"
            ;;
          *:*sixel*:*|*:*foot*:*|*:*mlterm*:*)
            RENDERER="sixel"
            ;;
          *:*:iTerm.app)
            RENDERER="iterm"
            ;;
          *)
            if command -v ${pkgs.chafa}/bin/chafa >/dev/null 2>&1; then
              RENDERER="chafa"
            fi
            ;;
        esac
      fi
    fi

    log_debug "Host: $HOST | Renderer: $RENDERER | Image: $IMAGE_PATH | Size: ''${LOGO_WIDTH}x''${LOGO_HEIGHT}"

    # Render Banner
    ${nfpBannerPkg}/bin/nfp-banner --static 2>/dev/null || echo "=== $HOST_LABEL ==="

    # Render Fastfetch
    if [ "$RENDERER" != "none" ] && [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
      if ! ${pkgs.fastfetch}/bin/fastfetch \
        --logo "$IMAGE_PATH" \
        --logo-type "$RENDERER" \
        --logo-width "$LOGO_WIDTH" \
        --logo-height "$LOGO_HEIGHT" \
        --logo-preserve-aspect-ratio true 2>/dev/null; then
          log_debug "Fastfetch logo rendering failed with renderer '$RENDERER', falling back to logo none"
          ${pkgs.fastfetch}/bin/fastfetch --logo none 2>/dev/null || true
      fi
    else
      ${pkgs.fastfetch}/bin/fastfetch --logo none 2>/dev/null || true
    fi
  '';
in
{
  home = lib.mkIf cfg.enable {
    home.packages = [
      nfpMotdPkg
      nfpBannerPkg
      motdAnimatePkg
    ];
  };
  passthru = {
    inherit nfpMotdPkg nfpBannerPkg motdAnimatePkg;
  };
}
