# flake-parts/hardware/default.nix
# Hardware support modules - CPU, audio, Bluetooth, etc.
{
  imports = [
    ./intel.nix
    ./intel-12th-gen.nix
    ./amd.nix
    ./audio.nix
    ./bluetooth.nix
  ];
}
