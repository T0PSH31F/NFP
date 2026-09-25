{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "impermanence" ./impermanence.nix)
    (mkDendriticModule "google-drive" ./google-drive.nix)
    (mkDendriticModule "nas-mount" ./nas-mount.nix)
  ];
}
