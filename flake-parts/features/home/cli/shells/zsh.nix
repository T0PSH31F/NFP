# flake-parts/features/home/cli/shells/zsh.nix
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf (cfg.enable && cfg.shells.zsh.enable) {
    programs.zsh = {
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

      initContent = ''
                # p10k instant prompt
                if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
                    source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
                fi

                # Source p10k configuration
                source ${../../assets/p10k.zsh}
                
                # Keybindings
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

                # Matugen FZF integration
                ${lib.optionalString cfg.theming.enable ''
                  [ -f ~/.config/fzf/matugen.conf ] && source ~/.config/fzf/matugen.conf
                ''}

      '';

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
  };
}
