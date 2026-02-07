{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);
in
{
  config = lib.mkIf (hasTag "desktop") {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Hints for apps to use Wayland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Ensure greetd/display manager starts?
    # Usually handled by display-manager.nix or similar.
  };
}
