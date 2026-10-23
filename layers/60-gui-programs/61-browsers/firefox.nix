{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.browsers.firefox;
in
{
  options.layers.layer-60.gui.browsers.firefox = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default =
        builtins.elem "desktop" (osConfig.machine.tags or [ ])
        || builtins.elem "workstation" (osConfig.machine.tags or [ ]);
      description = "Enable Firefox browser";
    };
  };

  home = lib.mkIf cfg.enable {
    home.packages = [ pkgs.pywalfox-native ];
    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
      policies = {
        Homepage = {
          URL = "http://luffy.nfp.nix:3007/";
          Locked = false;
          StartPage = "homepage";
        };
        NewTabPage = true;
      };
    };
  };
}
