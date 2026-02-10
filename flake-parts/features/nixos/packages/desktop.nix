# flake-parts/features/nixos/packages/desktop.nix
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
    environment.systemPackages = with pkgs; [
      # Browsers
      brave
      firefox
      librewolf

      # Custom desktop tools
      jerry
      lobster

      # File managers
      thunar

      # Launchers
      wofi

      # Terminals
      kitty

      # Wayland / clipboard / screenshot
      grim
      slurp
      swappy
      wf-recorder
      wl-clipboard
    ];
  };
}
