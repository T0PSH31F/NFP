{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.clan.lib.hasTag "desktop") {
    # Desktop overlay already wired via modules/nixos/overlays.nix in Phase 2

    environment.systemPackages = with pkgs; [
      # Browsers
      firefox
      brave
      librewolf

      # Terminals
      kitty

      # Launchers
      wofi

      # File managers
      thunar

      # Custom desktop tools from overlay
      jerry
      lobster
      # vicinae # Build failing due to network fetch (glaze dependency)

      # Wayland / clipboard / screenshot
      grim
      slurp
      wl-clipboard
    ];
  };
}
