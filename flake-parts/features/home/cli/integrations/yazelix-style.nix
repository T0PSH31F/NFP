# flake-parts/features/home/cli/integrations/yazelix-style.nix
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
  config = lib.mkIf (cfg.enable && cfg.yazelixIntegration.enable) {
    # Helix internal keybinding for Space+e to open yazi
    programs.helix.settings.keys.normal = {
      "space.e" = ":sh yazi";
    };

    # Start yazelix-style environment command
    programs.zsh.initExtra = lib.mkIf cfg.shells.zsh.enable ''
      yazelix() {
        if command -v zellij &> /dev/null; then
          zellij --layout compact
        else
          echo "Zellij not available, starting helix directly"
          hx "$@"
        fi
      }
    '';

    programs.bash.initExtra = lib.mkIf cfg.shells.bash.enable ''
      yazelix() {
        if command -v zellij &> /dev/null; then
          zellij --layout compact
        else
          echo "Zellij not available, starting helix directly"
          hx "$@"
        fi
      }
    '';
  };
}
