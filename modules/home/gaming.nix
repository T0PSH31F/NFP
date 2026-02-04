{
  config,
  pkgs,
  lib,
  clanTags,
  ...
}:
{
  config = lib.mkIf (builtins.elem "gaming" clanTags) {
    home.packages = with pkgs; [
      mangohud
      protonup
    ];

    # Optional: config for game-launcher integration, HUD, etc.
  };
}
