# flake-parts/features/home/cli/editors/helix.nix
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
  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;

      settings = {
        # Use matugen theme if enabled, otherwise fallback to catppuccin
        theme = lib.mkIf cfg.theming.enable "matugen";

        editor = {
          line-number = "relative";
          mouse = false;
          cursorline = true;
          auto-save = true;
          completion-trigger-len = 1;
          true-color = true;
          rulers = [
            80
            120
          ];
          color-modes = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          indent-guides = {
            render = true;
            character = "┊";
          };
        };

        keys.normal = {
          C-s = ":w";
          C-q = ":q";
          H = ":bp";
          L = ":bn";
        };

        keys.insert = {
          "j.k" = "normal_mode";
          "k.j" = "normal_mode";
        };
      };

      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
      ];
    };
  };
}
