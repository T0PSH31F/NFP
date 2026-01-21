{ pkgs, ... }:
{
  imports = [
    ./starship.nix
    ./ghostty.nix
    ./kitty.nix
    ./alacritty.nix
    ./bash.nix
    ./fish.nix
    ./zsh.nix
    ./anifetch.nix
    ./tmux.nix
  ];
  # Direnv for development environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Bat (better cat)
  programs.bat = {
    enable = true;

    config = {
      color = "always";
      italic-text = "always";
      style = "numbers";
      pager = "delta";
      paging = "never";
      map-syntax = [
        ".ignore:.gitignore"
      ];
    };
  };

  # btop
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "everforest";
      theme_background = false;
      update_ms = pkgs.lib.mkForce 1000;
    };
  };

  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".git"
      ".DS_Store"
    ];
  };

  programs.eza = {
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

  # fzf
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
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
    defaultOptions = [
      "--height 40%"
      "--layout reverse"
      "--border"
      "--inline-info"
      "--color 'fg:#bbccdd,fg+:#ddeeff,bg:#334455,preview-bg:#223344,border:#778899'"
    ];
  };

  # GPG
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gtk2;
  };

  programs.nix-index = {
    enable = true;
    package = pkgs.nix-index;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };
  #command-not-found.enable = false;

  programs.ripgrep.enable = true;
  programs.jq.enable = true;

  programs.pay-respects = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--alias"
      "f"
    ];
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Zoxide for smart cd
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    package = pkgs.starship;
    enableNushellIntegration = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };
}
