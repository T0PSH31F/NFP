{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-20.services.config.tailscale-sidecar;
  impermanenceCfg = config.layers.layer-10.system.config.impermanence;
in
{
  options.layers.layer-20.services.config.tailscale-sidecar = {
    enable = lib.mkEnableOption "Friend Tailscale daemon sidecar (isolated client in userspace networking mode)";

    socks5Port = lib.mkOption {
      type = lib.types.port;
      default = 1055;
      description = "Local SOCKS5 proxy port for the second Tailscale client";
    };

    httpProxyPort = lib.mkOption {
      type = lib.types.port;
      default = 1056;
      description = "Local HTTP proxy port for the second Tailscale client (distinct from SOCKS5 port)";
    };

    serviceName = lib.mkOption {
      type = lib.types.str;
      default = "tailscaled-sidecar";
      description = "Name of the systemd service for the second Tailscale client";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.socks5Port != cfg.httpProxyPort;
            message = "tailscale-sidecar: socks5Port and httpProxyPort must be different.";
          }
        ];

        # Ensure netcat-openbsd is available for SSH SOCKS5 ProxyCommand
        environment.systemPackages = [ pkgs.netcat-openbsd ];

        systemd.services.${cfg.serviceName} = {
          description = "Tailscale client daemon for friend tailnet (userspace proxy)";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];

          serviceConfig = {
            ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale-sidecar/tailscaled.state --socket=/run/tailscale-sidecar/tailscaled.sock --tun=userspace-networking --port=0 --socks5-server=127.0.0.1:${toString cfg.socks5Port} --outbound-http-proxy-listen=127.0.0.1:${toString cfg.httpProxyPort}";
            StateDirectory = "tailscale-sidecar";
            StateDirectoryMode = "0700";
            RuntimeDirectory = "tailscale-sidecar";
            RuntimeDirectoryMode = "0700";
            Restart = "on-failure";
            RestartSec = "5s";

            # Hardening for userspace networking; no kernel TUN interface required.
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictRealtime = true;
          };
        };
      }

      # Integrate with impermanence if enabled
      (lib.mkIf (impermanenceCfg.enable or false) {
        environment.persistence.${impermanenceCfg.persistPath}.directories = [
          {
            directory = "/var/lib/tailscale-sidecar";
            user = "root";
            group = "root";
            mode = "0700";
          }
        ];
      })
    ]
  );
}
