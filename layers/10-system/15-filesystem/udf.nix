{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.config.udf;
in
{
  options.layers.layer-10.system.config.udf = {
    enable = lib.mkEnableOption "UDF (Universal Disk Format) filesystem support" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "udf" ];
    boot.kernelModules = [ "udf" ];
    environment.systemPackages = [ pkgs.udftools ];
  };
}
