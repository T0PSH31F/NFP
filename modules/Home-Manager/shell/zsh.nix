{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs = {
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      enableVteIntegration = true;
      autocd = true;
      enableCompletion = true;
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
        searchUpKey = "^P";
        searchDownKey = "^N";
      };
      #         _anifetch_motd() {
      #           local lain_gif="$HOME/.background/Giffees/Lain/oldScreen.gif"
      #           if command -v anifetch &> /dev/null && [[ -f "$lain_gif" ]]; then
      #             # Display Lain GIF with anifetch (40 width, 20 height, 1 repeat)
      #             anifetch "$lain_gif" -r 1 -W 40 -H 20 -c "--symbols wide --fg-only" 2>/dev/null || true
      #           fi
      #         }

      # _anifetch_motd
      initContent = ''
                if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
                    source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
                fi

                source ${./p10k.zsh}
                bindkey -v
                export KEYTIMEOUT=1
                bindkey '^Y' autosuggest-accept
                bindkey '^E' autosuggest-clear

                # Green ASCII MOTD
                _ascii_motd() {
                  print -P "%F{green}"
                  cat << 'EOF'
        ⣿⣿⣿⣿⣿⠩⠋⠹⢿⣿⠟⣉⡶⢁⣄⡙⠿⣿⣿⣿⡈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
        ⣿⣓⣿⣿⡵⢟⣰⡶⠆⣡⣤⠙⢁⠉⢩⣤⣾⢻⡻⣸⢏⣄⡛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
        ⣷⣿⠈⢀⣴⠿⢋⠴⢛⣩⠀⠀⣾⡇⠀⢘⣿⡆⣳⢇⣾⡿⢻⣶⠎⠉⠽⠿⡿⢹⠟⣿⠟⣽⣿⣿⡿⣻⣻⡿⣻⢿⣿⣿⢿⣿⣏⣹⣿⣿
        ⡿⢋⣴⠋⠁⢨⣴⡆⢻⠃⢰⣼⡷⠃⠀⠩⠙⣗⠟⣼⡿⢡⣿⣷⣴⣞⢁⣠⣴⣤⣌⠙⠘⣿⠛⡚⠺⠾⠾⠿⠩⣚⡽⢷⣿⠃⠠⣾⣿⣿
        ⡗⠋⠁⣴⠀⡸⡿⣹⡧⠰⠛⠉⠀⠀⠀⠀⢱⢙⢠⣿⣥⣿⣿⣿⣿⣿⡟⣿⣿⣿⡿⣷⣴⡌⠈⡇⣾⠻⣿⡆⡈⠉⡀⡈⠁⠀⠀⠈⣿⣿
        ⣿⢃⡌⠋⣸⡿⠓⠉⠀⠀⠀⠀⠀⠀⠀⡆⠀⢸⣿⠒⠶⠎⢿⣿⣿⣿⡇⢹⣿⡿⢃⣿⣿⡟⣴⡇⣿⢸⣿⠁⠀⠿⠛⠛⠀⠀⠀⠀⠘⢿
        ⣋⡼⠛⠀⠀⠀⠀⠀⠀⠀⠀⡄⣰⡄⠰⠀⠀⣼⣿⢠⡈⠓⠜⢿⣿⣿⡇⢸⡏⠀⢣⣾⣿⡇⣿⠁⣾⢸⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠁⠀⠀⠀⠀⠀⠀⠀⡀⢠⣾⠇⣿⣗⡄⢧⠀⣿⣿⣷⡙⠦⠤⠘⢿⣿⣇⡘⣀⣴⣿⣿⣿⡇⠃⠈⠻⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⠀⣀⡴⢋⡴⡛⣿⢸⣿⣿⣿⣄⠀⣿⣿⣿⣷⣄⣀⡀⠈⠋⢰⠁⢻⡿⠿⠛⠋⠠⠶⠶⢠⣶⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⣀⣴⠾⢋⠔⣡⡾⢀⡿⢸⣿⣿⣿⣿⠀⣿⡈⣽⣿⣿⣿⣿⣿⣆⡟⣠⡤⠄⣀⠀⠀⠀⢠⣴⣯⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠐⠊⢉⡀⡄⢠⣾⣿⠃⡼⡅⡀⣀⠂⠈⠁⠀⠙⠣⠈⠻⣿⣿⣿⡿⣸⢱⣿⣷⡘⢿⡿⠱⢋⣸⣿⠇⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀
        ⣤⣶⣿⡇⢀⣿⣿⡿⠠⢱⡇⣿⣿⣿⣿⡇⢠⢈⢿⣆⢘⡢⣝⣛⠀⠃⣺⣿⣿⣿⡶⠄⠀⢈⣿⠏⠀⠀⠀⠀⠀⠀⠀⡌⠀⠀⠀⠀⠀⠀
        ⣿⣿⣿⣧⣼⣿⣿⡇⢀⣿⡇⣿⣿⣿⣿⡄⢻⣆⢈⢿⣷⠩⣒⠭⢝⣒⣶⣶⠖⠂⢀⣤⣶⡿⠋⠀⠀⢀⠀⠀⠀⠀⢰⡇⠀⠀⠀⠀⠀⠀
        ⣿⣿⣿⣿⣿⣿⣿⣷⣾⣿⡇⣿⣿⣿⣿⡇⢸⣿⡄⢎⢻⣷⣌⠙⠓⠂⢠⣴⣶⣿⡿⠟⠉⢀⠀⠀⠐⠈⠀⠀⠀⠀⣾⠀⠀⠀⠀⠀⠀⠀
        ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⡇⢸⣿⣿⣌⢷⡍⠛⠿⠷⠸⠿⣛⣋⣥⣴⡶⠟⠁⠀⠀⠀⠀⠀⠀⠌⣼⣿⠀⠀⠀⠀⠀⠀⠀
        EOF
                  print -P "%f"
                }
                # Only show MOTD for interactive shells, not in tmux/screen, and not in VSCode terminal
                if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "$STY" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
                  _ascii_motd
                fi
      '';

      #  initExtra = ''
      #    eval "$(starship init zsh)"
      #    eval "$(zoxide init zsh)"
      #    bindkey -e
      #  '';

      shellAliases = {
        e = "hx .";
        vi = "hx";
        vim = "hx";
        cat = "bat";
        ps = "procs";
        l = "lsd -l";
        ll = "lsd -la";
        diff = "delta";
        serve = "miniserve";
        fm = "yazi";
        gg = "lazygit";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        # Nix package search with fzf (nix-search-tv)
        ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
        # SSH keyscan helper
        sshks = "ssh-keyscan -t ed25519 192.168.1.0/24 >> ~/.ssh/known_hosts";
      };

      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "romkatv/powerlevel10k"
          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/docker"
          "ohmyzsh/ohmyzsh path:plugins/docker-compose"
          "ohmyzsh/ohmyzsh path:plugins/gradle"
        ];
      };
    };

    carapace = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    fd = {
      enable = true;
      hidden = true;
      ignores = [
        ".git"
        ".DS_Store"
      ];
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    eza = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      colors = "always";
      git = true;
      icons = "always";
      extraOptions = [
        "-a"
        "-1"
      ];
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git --exclude .DS_Store";
      fileWidgetCommand = "fd --hidden --strip-cwd-prefix --exclude .git --exclude .DS_Store";
      fileWidgetOptions = [
        "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; elif file --mime-type {} | grep -q \"image/\"; then chafa -f iterm -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} {}; else bat -n --color=always --line-range :500 {}; fi'"
      ];
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };

    pay-respects = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      options = [
        "--alias"
        "f"
      ];
    };

    ripgrep.enable = true;
    jq.enable = true;
    btop.enable = true;
  };
}
