# Tier: 50-cli-tui-programs / 51-shells
# Module: yazelix-nova.nix
# Purpose: Yazelix Nova flake workspace integration via Home Manager module.
# Option Path: layers.layer-50.cli.yazelix-nova
# Enabling Host Tags: desktop, workstation, development
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:

{
  options.layers.layer-50.cli.yazelix-nova = {
    enable = lib.mkEnableOption "Yazelix Nova shell & workspace manager";
  };

  # Imperative profile installation — flake module import removed per user preference.
  # Keybinds in hyprland/niri target ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu.
  home =
    { config, osConfig, ... }:
    {
      config = lib.mkIf osConfig.layers.layer-50.cli.yazelix-nova.enable { };
    };
}
