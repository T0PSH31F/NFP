# flake-parts/features/home/cli/shells/bash.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf (cfg.enable && cfg.shells.bash.enable) {
    programs.bash = {
      enable = true;
      enableCompletion = true;

      initExtra = ''
        if [ -n "$IN_NIX_SHELL" ]; then
          export PS1="[nix-shell] $PS1"
        fi

        # Grandlix MOTD (Images Removed by request)
        #if command -v neofetch &>/dev/null; then
        #  neofetch
        #fi
      '';
    };
  };
}
