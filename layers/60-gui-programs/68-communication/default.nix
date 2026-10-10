{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.communication;
in
{
  imports = [
    ./beeper.nix
  ];

  options.layers.layer-60.gui.communication = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable communication & messaging applications";
    };
  };

  home = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ayugram-desktop
      caprine
      cinny
      element-desktop
      equibop
      ferdium
      signal-cli
      signal-desktop
      tdl
      vesktop
    ];
  };
}
