{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.brave;
  inherit (cfg) dashboardUrl;
in
{
  options.layers.layer-60.gui.brave = {
    enable = lib.mkEnableOption "Brave Browser";

    dashboardUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://luffy.nfp.nix:3007/";
      description = "Default homepage and new tab page URL for Brave";
    };
  };

  nixos = lib.mkIf cfg.enable {
    # System-wide Chromium / Brave enterprise policies
    environment.etc."brave/policies/managed/homepage.json".text = builtins.toJSON {
      HomepageLocation = dashboardUrl;
      HomepageIsNewTabPage = false;
      NewTabPageLocation = dashboardUrl;
      ShowHomeButton = true;
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [ dashboardUrl ];
    };

    environment.etc."chromium/policies/managed/homepage.json".text = builtins.toJSON {
      HomepageLocation = dashboardUrl;
      HomepageIsNewTabPage = false;
      NewTabPageLocation = dashboardUrl;
      ShowHomeButton = true;
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [ dashboardUrl ];
    };
  };

  home = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions =
        let
          ids = [
            "ficfmibkjjnpogdcfhfokmihanoldbfe" # File Icons for GitHub and GitLab
          ];
        in
        map (id: { inherit id; }) ids;
    };

    # User-level managed policy for Brave
    xdg.configFile."BraveSoftware/Brave-Browser/policies/managed/homepage.json".text = builtins.toJSON {
      HomepageLocation = dashboardUrl;
      HomepageIsNewTabPage = false;
      NewTabPageLocation = dashboardUrl;
      ShowHomeButton = true;
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [ dashboardUrl ];
    };

    xdg.configFile."chromium/policies/managed/homepage.json".text = builtins.toJSON {
      HomepageLocation = dashboardUrl;
      HomepageIsNewTabPage = false;
      NewTabPageLocation = dashboardUrl;
      ShowHomeButton = true;
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [ dashboardUrl ];
    };
  };
}
