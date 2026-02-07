{
  config,
  pkgs,
  lib,
  clanTags,
  ...
}:
{
  # ZSH Configuration
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
      if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      source ${./assets/p10k.zsh}
      bindkey -v
      export KEYTIMEOUT=1
      bindkey '^Y' autosuggest-accept
      bindkey '^E' autosuggest-clear

      # Grandlix MOTD - Custom Image & Fortune
      # Grandlix MOTD (Images Removed by request)
      if command -v anifetch &>/dev/null; then
        anifetch
      elif command -v neofetch &>/dev/null; then
        neofetch
      fi

      # Yazelix integration - yzx command
      if [[ -f "$HOME/.config/yazelix/nushell/scripts/core/start_yazelix.nu" ]]; then
        yzx() {
          case "$1" in
            launch)
              shift
              nu ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu "$@"
              ;;
            env)
              cd ~/.config/yazelix && devenv shell
              ;;
            help)
              echo "yzx commands:"
              echo "  launch       - Launch Yazelix in new terminal"
              echo "  launch --here - Launch Yazelix in current terminal"
              echo "  env          - Load Yazelix tools into current shell"
              echo "  help         - Show this help"
              ;;
            *)lib
              echo "Unknown command: $1. Use 'yzx help' for available commands."
              ;;
          esac
        }
      fi
    '';

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

  # Bash Configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "eza -la";
      ls = "eza";
      l = "eza -lah";
      tree = "eza --tree";
      ".." = "cd ..";
      "..." = "cd ../..";
      g = "git";
      lg = "lazygit";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # NixOS
      rebuild = "sudo nixos-rebuild switch --flake .";
      update = "nix flake update";
      clean = "nix-collect-garbage -d";

      # Nix package search with fzf (nix-search-tv)
      ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
    };

    initExtra = ''
      # Initialize zoxide
      eval "$(zoxide init bash)"

      # FZF bindings
      source ${pkgs.fzf}/share/fzf/key-bindings.bash
      source ${pkgs.fzf}/share/fzf/completion.bash

      if [ -n "$IN_NIX_SHELL" ]; then
        export PS1="[nix-shell] $PS1"
      fi

      # Grandlix MOTD - Custom Image & Fortune
      # Grandlix MOTD (Images Removed by request)
      if command -v anifetch &>/dev/null; then
        anifetch
      elif command -v neofetch &>/dev/null; then
        neofetch
      fi
    '';
  };

  # Shell tools
  programs = {
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

    bat.enable = true;
    ripgrep.enable = true;
    jq.enable = true;
    btop.enable = true;
  };

  home.packages = with pkgs; [
    imagemagick
    chafa
    gum
    lolcat
    figlet
    toilet
    blahaj
    terminal-parrot
    neo-cowsay
    charasay
    neofetch
    fortune-kind

  ];
}
