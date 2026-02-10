# flake-parts/hardware/default.nix
# Hardware support modules
{ ... }:
{
  imports = [
    ./amd.nix
    ./audio.nix
    ./bluetooth.nix
    ./common.nix
    ./intel-12th-gen.nix
    ./intel-7th-gen.nix
    ./intel.nix
    ./laptop.nix
    ./nvidia-hybrid.nix
    ./nvidia.nix
    ./razer.nix
    ./touchpad.nix
  ];
}
