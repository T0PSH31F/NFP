{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf (cfg.enable && cfg.shells.zsh.enable) {
    programs.zsh = {
      enable = true;
      dotDir = "${config.users.users.${config.layers.meta.primaryUser}.home}/.config/zsh";
      enableVteIntegration = true;
      autocd = true;
      enableCompletion = true;
      envExtra = lib.mkIf cfg.headless ''
        if [ -e /etc/profile.d/nix.sh ]; then . /etc/profile.d/nix.sh; elif [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
      '';
      autosuggestion = {
        enable = true;
        highlight = "fg=#6c7086";
      };
      syntaxHighlighting.enable = true;
      history = {
        append = true;
        expireDuplicatesFirst = true;
        ignoreAllDups = true;
        saveNoDups = true;
        ignoreDups = true;
        findNoDups = true;
        ignoreSpace = true;
        extended = true;
        share = true;
        path = "$ZDOTDIR/.zsh_history";
      };
      historySubstringSearch = {
        enable = true;
        searchUpKey = "^[[A";
        searchDownKey = "^[[B";
      };
      shellAliases = {
        zls = "zellij list-sessions";
        zd = "zellij delete-session";
        zk = "zellij kill-session";
      };
      initContent = ''
        # Hermes Agent — ensure ~/.local/bin and ~/bin are on PATH
        case ":$PATH:" in
          *":$HOME/bin:"*) ;;
          *) export PATH="$HOME/bin:$PATH" ;;
        esac
        export PATH="$HOME/.local/bin:$PATH"

        any-nix-shell zsh --info-right | source /dev/stdin
        bindkey '^Y' autosuggest-accept
        bindkey '^E' autosuggest-clear
        if [[ $- == *i* ]] && [[ -t 1 ]] && [[ -z "''${NFP_MOTD_EXECUTED:-}" ]]; then
          export NFP_MOTD_EXECUTED=1
          nfp-motd || true
        fi
        ${lib.optionalString cfg.theming.enable "[ -f ~/.config/fzf/matugen.conf ] && source ~/.config/fzf/matugen.conf"}
        if command -v starship >/dev/null 2>&1; then
          # Sync and apply Noctalia theme palette to Starship config
          local PALETTE_FILE=""
          if [ -f "$HOME/.cache/noctalia/starship-palette.toml" ]; then
            PALETTE_FILE="$HOME/.cache/noctalia/starship-palette.toml"
          elif [ -f "$HOME/.config/noctalia/templates/starship.toml" ]; then
            PALETTE_FILE="$HOME/.config/noctalia/templates/starship.toml"
          fi

          if [ ! -f "$HOME/.cache/starship/starship.toml" ] || [ "$HOME/.config/starship.toml" -nt "$HOME/.cache/starship/starship.toml" ] || [ "$(grep -c '# >>> NOCTALIA STARSHIP PALETTE >>>' "$HOME/.cache/starship/starship.toml" 2>/dev/null)" != "1" ]; then
            mkdir -p "$HOME/.cache/starship"
            TMP_FILE=$(mktemp)
            # Strip any existing noctalia section, then write base config
            sed '/^# >>> NOCTALIA STARSHIP PALETTE >>>/,/^# <<< NOCTALIA STARSHIP PALETTE <<</d' "$HOME/.config/starship.toml" > "$TMP_FILE"
            if [ -n "$PALETTE_FILE" ]; then
              # Change palette setting to noctalia
              sed -i -E 's/^([[:space:]]*)palette([[:space:]]*)=.*/\1palette\2= "noctalia"/' "$TMP_FILE" 2>/dev/null || sed -i '1i palette = "noctalia"' "$TMP_FILE"
              # Append fresh noctalia palette section
              {
                echo ""
                echo "# >>> NOCTALIA STARSHIP PALETTE >>>"
                cat "$PALETTE_FILE"
                echo "# <<< NOCTALIA STARSHIP PALETTE <<<"
              } >> "$TMP_FILE"
            fi
            # Atomic replace — zellij never sees a partial/missing/malformed file
            mv "$TMP_FILE" "$HOME/.cache/starship/starship.toml"
          fi
          eval "$(starship init zsh)"
        fi

        ${lib.optionalString (!cfg.headless && cfg.zellij.enable) ''
          if [[ $- == *i* ]] && [[ -z "$ZELLIJ" ]] && [[ -z "$TMUX" ]] && [[ -z "$STY" ]] && [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && [[ "$TERM_PROGRAM" != "Waveterm" ]] && [[ -z "$SSH_CONNECTION" ]]; then
              if command -v zellij >/dev/null 2>&1; then
                # Prune old EXITED sessions (keep z0r0.clan)
                zellij list-sessions -n 2>/dev/null | while IFS= read -r s; do
                  [ "$s" = "z0r0.clan" ] && continue
                  zellij delete-session --force "$s" 2>/dev/null || true
                done
                # Try attaching to existing persistent session; create with correct layout if missing
                zellij attach "z0r0.clan" 2>/dev/null || zellij --layout opencode --session "z0r0.clan"
              fi
          fi
        ''}
      '';
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/docker"
          "ohmyzsh/ohmyzsh path:plugins/docker-compose"
          "ohmyzsh/ohmyzsh path:plugins/gradle"
        ];
      };
    };
    home.packages = with pkgs; [
      revolver
      zsh-command-time
      zsh-completions
      zsh-clipboard
      zsh-f-sy-h
      zsh-fzf-tab
      zsh-you-should-use
      zsh-nix-shell
      nix-zsh-completions
      any-nix-shell
      z-lua
    ];
  };
}
