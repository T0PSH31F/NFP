# Carapace Multi-Shell Completion Engine Module
{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-50.cli.carapace;
in
{
  options.layers.layer-50.cli.carapace = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Carapace multi-shell completion engine";
    };
  };

  home = lib.mkIf cfg.enable {
    programs.carapace = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };
}
