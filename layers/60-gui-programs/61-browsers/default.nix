{ lib, mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "brave" ./brave.nix)
    (mkDendriticModule "librewolf" ./librewolf.nix)
    (mkDendriticModule "firefox" ./firefox.nix)
    (mkDendriticModule "google-chrome" ./google-chrome.nix)
    (mkDendriticModule "thunderbird" ./thunderbird.nix)
    (mkDendriticModule "qutebrowser" ./qutebrowser.nix)
  ];
}
