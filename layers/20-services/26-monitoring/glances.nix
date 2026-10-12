{ config, lib, ... }:
with lib;
let
  cfg = config.services.glances-server;
in
{
  options.services.glances-server = {
    enable = mkEnableOption "Glances system monitoring";
    port = mkOption {
      type = types.port;
      default = 61208;
    };
  };

  config = mkIf cfg.enable {
    # Glances contract removed — Netdata is primary source for fleet vitals

    services.glances = {
      enable = true;
      openFirewall = true;
      extraArgs = [
        "-w"
        "--bind"
        "0.0.0.0"
      ];
    };
  };
}
