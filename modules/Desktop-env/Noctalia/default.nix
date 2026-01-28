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
    # Import backend-specific configuration
    imports = [
      (mkIf (cfg.backend == "hyprland") ./hyprland.nix)
      (mkIf (cfg.backend == "niri") ./niri/default.nix)
    ];

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
