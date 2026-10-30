{ lib, config, ... }:
{
  options.layers.manifest = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    readOnly = true;
    default = {
      system = {
        hostname = config.networking.hostName;
        tags = config.machine.tags or [ ];
      };
      enabledLayers = lib.filterAttrsRecursive (_n: v: v != false && v != { } && v != null) config.layers;
    };
    description = "Read-only manifest of enabled features for this machine";
  };
}
