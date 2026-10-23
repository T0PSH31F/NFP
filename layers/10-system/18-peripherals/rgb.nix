{
  config,
  lib,
  pkgs,
  ...
}:
let
  periph = config.layers.layer-10.system.peripherals;
in
{
  config = lib.mkMerge [
    (lib.mkIf periph.openrgb.enable {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb-with-all-plugins;
      };
      hardware.i2c.enable = lib.mkIf periph.openrgb.enableI2C true;
    })

    (lib.mkIf periph.corsair.enable {
      hardware.ckb-next.enable = true;
    })
  ];
}
