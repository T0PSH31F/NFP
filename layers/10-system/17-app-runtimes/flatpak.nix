{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-10.system.flatpak;
in
{
  options.layers.layer-10.system.flatpak = {
    enable = mkEnableOption "Flatpak package manager";

    remotes = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the Flatpak remote";
            };
            location = mkOption {
              type = types.str;
              description = "URL of the Flatpak remote";
            };
          };
        }
      );
      default = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      description = "List of Flatpak remotes to configure";
    };

  };
  config = mkIf cfg.enable {
    # Enable Flatpak service
    services.flatpak.enable = true; # Moved to service-distribution.nix
  };
}
