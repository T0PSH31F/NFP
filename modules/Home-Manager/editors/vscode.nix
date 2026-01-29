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
      # noctalia.noctalia-theme  # TODO: Package noctalia-theme for VSCode or install from marketplace

      # Language support
      rust-lang.rust-analyzer
      golang.go
      ms-python.python
      ms-vscode.cpptools
      # qcz.text-power-tools  # Not available in nixpkgs vscode-extensions
      # fireblast.hyprlang-vscode  # Not available in nixpkgs vscode-extensions
      # ewen-lbh.vscode-hyprls  # Not available in nixpkgs vscode-extensions

      # Web development
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      bradlc.vscode-tailwindcss

      # Utilities
      eamodio.gitlens
      yzhang.markdown-all-in-one

      # AI extensions - not available in nixpkgs vscode-extensions
      # These can be installed manually from VSCode marketplace
      # blackboxapp.blackbox
      # blackboxapp.blackboxagent
      # rooveterinaryinc.roo-cline
      # saoudrizwan.claude-dev


      # Nix
      jnoortheen.nix-ide
      #brettm12345.nixfmt-vscode
      #jeff-hykin.better-nix-syntax

    ];

    profiles.default.userSettings = {
      "workbench.colorTheme" = lib.mkDefault "Default Dark Modern";  # Changed from NoctaliaTheme (not packaged yet)
      "workbench.iconTheme" = "material-icon-theme";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
      "editor.fontSize" = 16;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = true;
      "editor.rulers" = [80 120];
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "vim.enableNeovim" = false;
    };
  };
  programs.npm.enable = true;
}
