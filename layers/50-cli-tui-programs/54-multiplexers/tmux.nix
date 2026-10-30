# flake-parts/features/home/cli/multiplexers/tmux.nix
{
  config,
  lib,
  ...
}:

let
  cfg = config.layers.layer-50.cli;
in
{
  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      newSession = true;
      shortcut = "b";
      terminal = "screen-256color";

      extraConfig = ''
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
      '';
    };
  };
}
