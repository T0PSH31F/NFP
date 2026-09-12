{ lib, mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "podman" ./podman.nix)
    (mkDendriticModule "rclone" ./rclone.nix)
  ];
}
