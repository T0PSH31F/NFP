{
  pkgs,
  lib,
  clanTags,
  host, # Assuming host is passed or available, otherwise remove if unused in this specific file context, but user had it in gamescope args.
  ...
}:
{
  config = lib.mkIf (builtins.elem "gaming" clanTags) {
    home.packages = with pkgs; [
      # Launchers
      cartridges
      heroic
      lutris
      prismlauncher
      umu-launcher

      # Utility
      mangohud
      protonplus
      protontricks
      winetricks
      nexusmods-app

      # Nintendo Switch / Tools
      nx2elf
      ns-usbloader
      hactool
      fusee-interfacee-tk
      ns-tool
      quark-goldleaf
    ];

    # Note: Gamescope logic is best handled in NixOS module or specific gamescope session wrap,
    # but if needed per-user for specific invocations:
    # programs.gamescope... (if home-manager module exists, but usually users use system package + steam launch args)
  };
}
