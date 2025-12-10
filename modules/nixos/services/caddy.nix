{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.services.caddy-server = {
    enable = mkEnableOption "Caddy web server";

    email = mkOption {
      type = types.str;
      default = "";
      description = "Email for Let's Encrypt certificates";
    };

    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra Caddy configuration";
          };
        };
      });
      default = {};
      description = "Virtual hosts configuration";
    };
  };

  config = mkIf config.services.caddy-server.enable {
    services.caddy = {
      enable = true;

      globalConfig = ''
        email ${config.services.caddy-server.email}
      '';

      virtualHosts = config.services.caddy-server.virtualHosts;
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [80 443];
    networking.firewall.allowedUDPPorts = [443]; # For QUIC
  };
}
