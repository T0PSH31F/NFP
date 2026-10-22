# end-4 Hyprland Desktop Experience Adapter (Proof-of-concept adapter)
{
  config,
  lib,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "end4-hyprland";
in
{
  options.layers.desktop.end4 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable end-4 Hyprland desktop experience adapter";
    };
  };

  # Skeleton adapter for end4-hyprland experience setup
  home =
    { lib, ... }:
    {
      config = lib.mkIf isEnabled {
        xdg.configFile."hypr/experiences/end4-hyprland.conf".text = ''
          # end4-hyprland experience configuration
        '';
      };
    };
}
