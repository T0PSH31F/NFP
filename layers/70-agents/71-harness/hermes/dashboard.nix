{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.layers.layer-76.hermes-dashboard = {
    enable = lib.mkEnableOption "Hermes Dashboard — web admin panel";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9119;
      description = "Port for the dashboard.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address (127.0.0.1 required when no auth provider is configured; tailnet access is bridged via hermes-dashboard-tailnet-proxy).";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.hermes-dashboard;
      hermesState = "${config.services.hermes-agent.stateDir}/.hermes";
      hermesPkg = config.services.hermes-agent.package;
      hermesBin = "${hermesPkg}/bin/hermes";
    in
    lib.mkIf cfg.enable {
      systemd.services.hermes-dashboard = {
        description = "Hermes Agent Web Dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "hermes-agent.service"
        ];

        environment = {
          HERMES_HOME = hermesState;
        };

        serviceConfig = {
          Type = "simple";
          # Must run as the hermes user: HERMES_HOME (${hermesState}) is
          # mode 0700 hermes:hermes, so any other user crashes at startup
          # with PermissionError on .hermes/.env (env_loader.load_hermes_dotenv).
          User = "hermes";
          Group = "hermes";
          WorkingDirectory = config.services.hermes-agent.stateDir;
          ExecStart = "${hermesBin} dashboard --port ${toString cfg.port} --host ${cfg.host} --insecure --skip-build";
          EnvironmentFile = "${hermesState}/.env";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Expose hermes-dashboard securely across the Tailscale mesh (Homepage scrapes http://<host>.nfp.nix:9119)
      # while keeping hermes-dashboard itself bound to 127.0.0.1.
      systemd.services.hermes-dashboard-tailnet-proxy = lib.mkIf (cfg.host == "127.0.0.1") {
        description = "Tailscale Mesh Bridge for Hermes Web Dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [
          "hermes-dashboard.service"
          "tailscaled.service"
        ];
        wants = [ "hermes-dashboard.service" ];
        path = [
          pkgs.iproute2
          pkgs.gawk
          pkgs.coreutils
          pkgs.caddy
        ];
        script = ''
          TS_IP=""
          for _ in $(seq 1 30); do
            TS_IP="$(ip -o -4 addr show dev tailscale0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)"
            if [ -n "$TS_IP" ]; then
              break
            fi
            sleep 1
          done
          if [ -z "$TS_IP" ]; then
            echo "tailscale0 IPv4 not ready yet"
            exit 1
          fi
          mkdir -p /run/hermes-dashboard-tailnet-proxy
          cat > /run/hermes-dashboard-tailnet-proxy/config.json <<EOF
          {
            "admin": { "disabled": true },
            "apps": {
              "http": {
                "servers": {
                  "hermes_proxy": {
                    "listen": ["$TS_IP:${toString cfg.port}"],
                    "automatic_https": { "disable": true },
                    "routes": [{
                      "handle": [{
                        "handler": "reverse_proxy",
                        "upstreams": [{ "dial": "127.0.0.1:${toString cfg.port}" }],
                        "headers": {
                          "request": {
                            "set": {
                              "Host": ["127.0.0.1:${toString cfg.port}"],
                              "Origin": ["http://127.0.0.1:${toString cfg.port}"]
                            }
                          }
                        }
                      }]
                    }]
                  }
                }
              }
            }
          }
          EOF
          exec caddy run --config /run/hermes-dashboard-tailnet-proxy/config.json
        '';
        serviceConfig = {
          Type = "simple";
          RuntimeDirectory = "hermes-dashboard-tailnet-proxy";
          Restart = "always";
          RestartSec = "5s";
        };
      };

      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ cfg.port ];
    };
}
