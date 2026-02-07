# flake-parts/features/home/cli/prompt/starship.nix
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
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        # Standard starship config
        add_newline = false;
        format = "$all";
      }
      // (
        if cfg.theming.enable then
          {
            # Starship supports importing other files
            # But usually via environment variable STARSHIP_CONFIG
          }
        else
          { }
      );
    };

    home.sessionVariables = lib.mkIf cfg.theming.enable {
      # Use matugen generated starship config if enabled
      # This is tricky because we might already have a starship.toml
      # Starship doesn't have an easy "include" for the whole config
      # However, we can use the STARSHIP_CONFIG environment variable
      # STARSHIP_CONFIG = "~/.config/starship-matugen.toml";
    };

    # Alternative: Use zsh hook to source it or merge in nix
  };
}
