# flake-parts/desktop/default.nix
# Desktop environment stack - Hyprland, terminals, display output management
{ config, lib, ... }:
{
  imports = [
    ./hyprland.nix
    ./ghostty.nix
    ./shikane.nix
    ./portals.nix
  ];

  # Optional: Auto-enable desktop components based on tags
  # config = lib.mkIf (builtins.elem "desktop" config.clan.tags or []) {
  #   # Desktop-specific defaults could go here
  # };
}
