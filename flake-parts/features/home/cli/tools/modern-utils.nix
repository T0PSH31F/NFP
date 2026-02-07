# flake-parts/features/home/cli/tools/modern-utils.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf (cfg.enable && cfg.modernTools.enable) {
    programs.bat = {
      enable = true;
      config = {
        theme = lib.mkIf cfg.theming.enable "matugen";
      };
    };

    programs.ripgrep.enable = true;
    programs.jq.enable = true;

    programs.btop = {
      enable = true;
      settings = {
        color_theme = lib.mkIf cfg.theming.enable "matugen";
      };
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      git = true;
      icons = "always";
      extraOptions = [
        "-a"
        "-1"
      ];
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fd = {
      enable = true;
      hidden = true;
      ignores = [
        ".git"
        ".DS_Store"
      ];
    };

    programs.pay-respects = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      options = [
        "--alias"
        "f"
      ];
    };

    programs.carapace = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [
      procs
      dust
      duf
      tokei
      hyperfine
      tealdeer
      trash-cli
    ];
  };
}
