{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop.omarchy;
in {
  imports = [inputs.omarchy-nix.nixosModules.default];

  config = lib.mkIf (cfg.enable && (cfg.backend == "hyprland" || cfg.backend == "both")) {
    omarchy = {
      full_name = "t0psh31f";
      email_address = "t0psh31f@grandlix.gang"; # Placeholder
      theme = "tokyo-night";
    };

    home-manager.users.t0psh31f = {
      imports = [inputs.omarchy-nix.homeManagerModules.default];
    };
  };
}
