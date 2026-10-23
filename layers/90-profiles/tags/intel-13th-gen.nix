# intel-13th-gen — Tag profile for Intel 13th Generation CPUs (Raptor Lake)
# Logic handled in layers/10-system/12-processor/12.1-cpu/intel.nix via tag detection.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "intel-13th-gen" config.machine.tags) {
    # CPU-specific tuning applied in layers/10-system/12-processor/12.1-cpu/intel.nix
  };
}
