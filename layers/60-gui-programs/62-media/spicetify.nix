{
  pkgs,
  lib,
  config,
  inputs,
  osConfig ? config,
  ...
}:
let
  noctalia-spicetify-sync = pkgs.writeShellScriptBin "noctalia-spicetify-sync" ''
    exec ${lib.getExe pkgs.nodejs} ${./scripts/noctalia-spicetify-sync.js} "$@"
  '';
in
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
        home.packages = [
          pkgs.spicetify-cli
          noctalia-spicetify-sync
        ];

        programs.spicetify = {
          enable = true;
          theme = spicePkgs.themes.comfy;

          spotifyLaunchFlags = "--remote-debugging-port=9222 --remote-allow-origins=* --ozone-platform=wayland";

          spotifyPackage = pkgs.spotify.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              f="$out/share/spotify/spotify"
              if [ -f "$f" ] && [ ! -L "$f" ]; then
                chmod +w "$f"
                sed -i '/^exec -a/i (sleep 1.2 && ${noctalia-spicetify-sync}/bin/noctalia-spicetify-sync 2>/dev/null &)' "$f"
                sed -i 's|"\$@" *$|--remote-debugging-port=9222 --remote-allow-origins=* --ozone-platform=wayland "\$@"|' "$f"
              fi
            '';
          });

          enabledExtensions = [
            # Custom Rspack-patched adblock extension to fix Spotify 1.2.95+ ad-blocking
            {
              src = ./extensions/adblock;
              name = "adblock.js";
            }
            # Noctalia theme live synchronization extension
            {
              src = ./extensions/noctalia-sync;
              name = "noctalia-sync.js";
            }
            # Upstream Spicetify extensions
            spicePkgs.extensions.beautifulLyrics
            spicePkgs.extensions.fullAlbumDate
            spicePkgs.extensions.fullAppDisplay
            spicePkgs.extensions.hidePodcasts
            spicePkgs.extensions.historyShortcut
            spicePkgs.extensions.popupLyrics
            spicePkgs.extensions.shuffle
          ];
        };
      };
    };
}
