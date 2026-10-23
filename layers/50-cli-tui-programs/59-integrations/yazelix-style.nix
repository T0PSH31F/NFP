{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf (cfg.enable && cfg.yazelixIntegration.enable) {
    programs = {
      helix.settings.keys.normal.space.e = ":sh yazi";
      zsh.initContent = lib.mkIf cfg.shells.zsh.enable ''
        yazelix() { if command -v zellij &> /dev/null; then zellij --layout compact; else echo "Zellij not available, starting neovim directly"; nvim "$@"; fi; }
      '';
      bash.initExtra = lib.mkIf cfg.shells.bash.enable ''
        yazelix() { if command -v zellij &> /dev/null; then zellij --layout compact; else echo "Zellij not available, starting neovim directly"; nvim "$@"; fi; }
      '';
    };
  };
}
