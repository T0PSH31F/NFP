{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "audio" ./audio.nix)
    (mkDendriticModule "mpv" ./mpv.nix)
    (mkDendriticModule "packages-media" ./packages-media.nix)
    (mkDendriticModule "spicetify" ./spicetify.nix)
    (mkDendriticModule "vlc" ./vlc.nix)
    (mkDendriticModule "feh" ./feh.nix)
    (mkDendriticModule "kodi" ./kodi.nix)
    (mkDendriticModule "mopidy" ./mopidy.nix)
    (mkDendriticModule "lmms" ./lmms.nix)
  ];
}
