# layers/50-cli-tui-programs/51-shells/nfp-motd.nix
# Minimal per-host terminal MOTD & banner tools (kitty-native, Noctalia-synced)
#
# Default `nfp-motd` prints ONLY: figlet host banner + PNG + user@host title.
# No full fastfetch spec dump on shell startup (that was the bloat/slowness).
# Full specs remain available on demand: `nfp-motd --full`.
# Image rendering is kitty-graphics / sixel / iTerm native via fastfetch.
# Chafa is intentionally NOT used anywhere in this module.
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

    # Noctalia accent color as "R;G;B" for 24-bit ANSI, or empty when unavailable.
    # Reads the live Noctalia-generated starship palette so the banner follows
    # the active desktop theme instead of a hardcoded rainbow.
    noctalia_accent_rgb() {
      _pal=""
      if [ -f "$HOME/.cache/noctalia/starship-palette.toml" ]; then
        _pal="$HOME/.cache/noctalia/starship-palette.toml"
      elif [ -f "$HOME/.config/noctalia/templates/starship.toml" ]; then
        _pal="$HOME/.config/noctalia/templates/starship.toml"
      else
        return 1
      fi
      _hex=$(grep -E '^[[:space:]]*(pink|mauve|sapphire)[[:space:]]*=' "$_pal" 2>/dev/null | head -n1 | sed -E 's/^[^0-9a-fA-F]*([0-9a-fA-F]{6}).*/\1/' || true)
      [ -n "$_hex" ] || return 1
      _r=$((16#''${_hex:0:2})); _g=$((16#''${_hex:2:2})); _b=$((16#''${_hex:4:2}))
      printf '%s;%s;%s' "$_r" "$_g" "$_b"
    }

    print_accent() {
      _rgb="$(noctalia_accent_rgb 2>/dev/null || true)"
      if [ -n "$_rgb" ]; then
        while IFS= read -r _line; do
          printf '\033[38;2;%sm%s\033[0m\n' "$_rgb" "$_line"
        done
      else
        cat
      fi
    }

    generate_banner_text() {
      if command -v ${pkgs.figlet}/bin/figlet >/dev/null 2>&1; then
        _fig="$(${pkgs.figlet}/bin/figlet -c "$TITLE" 2>/dev/null || true)"
        if [ -n "$_fig" ]; then
          if _rgb="$(noctalia_accent_rgb 2>/dev/null)" && [ -n "$_rgb" ]; then
            printf '%s\n' "$_fig" | print_accent
          elif command -v ${pkgs.lolcat}/bin/lolcat >/dev/null 2>&1; then
            printf '%s\n' "$_fig" | ${pkgs.lolcat}/bin/lolcat -f
          else
            printf '%s\n' "$_fig"
          fi
          echo "=== $SUBTITLE ==="
        else
          echo "=========================================================================="
          echo "  $TITLE // $SUBTITLE"
          echo "=========================================================================="
        fi
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

  # MOTD Main Executable Script — minimal by default (banner + PNG + title only).
  # Usage: nfp-motd [--full] [--help]
  #   default: figlet banner + PNG via native terminal graphics + user@host
  #   --full:  banner + full fastfetch spec dump (on demand, not on shell startup)
  nfpMotdPkg = pkgs.writeShellScriptBin "nfp-motd" ''
    set -euo pipefail

    HOST="$(hostname 2>/dev/null || echo "unknown")"
    MOTD_IMAGE_MODE="''${NFP_MOTD_IMAGE:-auto}"
    MOTD_SIZE_MODE="''${NFP_MOTD_SIZE:-normal}"
    MOTD_DEBUG="''${NFP_MOTD_DEBUG:-0}"
    MOTD_FULL=0
    if [ "''${1:-}" = "--full" ] || [ "''${NFP_MOTD_FULL:-0}" = "1" ]; then
      MOTD_FULL=1
    fi
    if [ "''${1:-}" = "--help" ]; then
      echo "Usage: nfp-motd [--full] [--help]"
      echo "  default: host banner + PNG + user@host (fast, minimal)"
      echo "  --full:  host banner + full fastfetch spec dump"
      exit 0
    fi

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

    # Native terminal graphics only — kitty / sixel / iTerm. No chafa.
    # Kitty graphics pass through SSH and modern tmux/zellij, so no
    # multiplexer downgrade: banner + name always prints, image renders
    # wherever the terminal speaks a native graphics protocol.
    RENDERER="none"

    if [ "$MOTD_IMAGE_MODE" = "none" ]; then
      RENDERER="none"
    elif [ "$MOTD_IMAGE_MODE" != "auto" ]; then
      RENDERER="$MOTD_IMAGE_MODE"
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
          RENDERER="none"
          ;;
      esac
    fi

    log_debug "Host: $HOST | Renderer: $RENDERER | Image: $IMAGE_PATH | Size: ''${LOGO_WIDTH}x''${LOGO_HEIGHT} | Full: $MOTD_FULL"

    # Render Banner (PC name)
    ${nfpBannerPkg}/bin/nfp-banner --static 2>/dev/null || echo "=== $HOST_LABEL ==="

    # Render PNG (+ user@host title only by default; full specs only with --full)
    if [ "$MOTD_FULL" = "1" ]; then
      if [ "$RENDERER" != "none" ] && [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
        ${pkgs.fastfetch}/bin/fastfetch \
          --logo "$IMAGE_PATH" \
          --logo-type "$RENDERER" \
          --logo-width "$LOGO_WIDTH" \
          --logo-height "$LOGO_HEIGHT" \
          --logo-preserve-aspect-ratio true 2>/dev/null || \
          ${pkgs.fastfetch}/bin/fastfetch --logo none 2>/dev/null || true
      else
        ${pkgs.fastfetch}/bin/fastfetch --logo none 2>/dev/null || true
      fi
    else
      if [ "$RENDERER" != "none" ] && [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
        ${pkgs.fastfetch}/bin/fastfetch \
          --logo "$IMAGE_PATH" \
          --logo-type "$RENDERER" \
          --logo-width "$LOGO_WIDTH" \
          --logo-height "$LOGO_HEIGHT" \
          --logo-preserve-aspect-ratio true \
          -s Title 2>/dev/null || \
          ${pkgs.fastfetch}/bin/fastfetch --logo none -s Title 2>/dev/null || true
      else
        ${pkgs.fastfetch}/bin/fastfetch --logo none -s Title 2>/dev/null || true
      fi
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
