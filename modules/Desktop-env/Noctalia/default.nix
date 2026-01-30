{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.noctalia;
in
{
  # Import backend-specific configuration at top level
  imports = [
    ./hyprland/default.nix
    ./niri/default.nix
  ];

  options.desktop.noctalia = {
    enable = mkEnableOption "Noctalia Shell - Modern desktop environment";

    backend = mkOption {
      type = types.enum [ "hyprland" "niri" ];
      default = "hyprland";
      description = "Desktop compositor backend to use";
    };

    package = mkOption {
      type = types.package;
      default = inputs.noctalia.packages.${pkgs.system}.default or pkgs.noctalia-shell;
      description = "Noctalia Shell package to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional Noctalia Shell settings";
    };
  };

  config = mkIf cfg.enable {
    # Common Noctalia configuration
    home-manager.users.t0psh31f = {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia-shell = {
        enable = true;
        package = cfg.package;
        settings = cfg.settings;
      };
    };
  };
}
