# flake-parts/hardware/default.nix
# Hardware support modules
{ ... }:
{
  imports = [
    # Base
    ./common.nix

    # CPU (Intel or AMD)
    ./amd.nix
    ./intel-12th-gen.nix
    ./intel-7th-gen.nix
    ./intel.nix

    # GPU (AMD, Intel, Nvidia)
    ./nvidia-hybrid.nix
    ./nvidia.nix

    # Peripheral (Audio, Bluetooth, Controller)
    ./audio.nix
    ./bluetooth.nix
    ./razer.nix

    # Device (Desktop, Laptop, Touchscreen)
    ./laptop.nix
    ./touchpad.nix
  ];
}
