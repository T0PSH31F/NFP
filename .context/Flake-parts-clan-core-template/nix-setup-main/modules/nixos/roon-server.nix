{
  config,
  lib,
  pkgs,
  ...
}: {
  options.roonServer = {
    enable = lib.mkEnableOption "Roon music server";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open firewall ports for Roon server";
    };
  };

  config = lib.mkIf config.roonServer.enable {
    services.roon-server = {
      enable = true;
      openFirewall = config.roonServer.openFirewall;
    };
  };
}
