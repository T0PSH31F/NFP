{
  pkgs,
  lib,
  ...
}: {
  # VS Code
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # Themes
      pkief.material-icon-theme
      zhuangtongfa.material-theme

      # Language support
      rust-lang.rust-analyzer
      golang.go
      ms-python.python
      ms-vscode.cpptools

      # Web development
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      bradlc.vscode-tailwindcss

      # Utilities
      eamodio.gitlens
      vscodevim.vim
      yzhang.markdown-all-in-one

      # Nix
      jnoortheen.nix-ide
    ];

    profiles.default.userSettings = {
      "workbench.colorTheme" = lib.mkDefault "One Dark Pro";
      "workbench.iconTheme" = "material-icon-theme";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
      "editor.fontSize" = 14;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "editor.rulers" = [80 120];
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "vim.enableNeovim" = true;
    };
  };
}
