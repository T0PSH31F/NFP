{
  pkgs,
  lib,
  config,
  inputs,
  osConfig ? config,
  ...
}:
{
  options.layers.layer-60.gui.spicetify = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Spicetify";
    };
  };

  home =
    { config, osConfig, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.spicetify-nix.homeManagerModules.default
      ]
      ++ lib.optionals osConfig.layers.layer-60.gui.spicetify.enable [
      ];

      config = lib.mkIf osConfig.layers.layer-60.gui.spicetify.enable {
        home.packages = lib.optional (spicePkgs ? spicetify-cli) spicePkgs.spicetify-cli;

        programs.spicetify = {
          enable = true;
          theme = spicePkgs.themes.comfy;

          enabledExtensions = with spicePkgs.extensions; [
            adblock
            beautifulLyrics
            betterGenres
            fullAlbumDate
            fullAppDisplay
            hidePodcasts
            historyShortcut
            popupLyrics
            shuffle
            skipStats
            songStats
            volumePercentage
            wikify
          ];
        };
      };
    };
}
