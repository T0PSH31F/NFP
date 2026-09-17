# Fleet Healthcheck NixOS VM Test
# Asserts fleet-healthcheck passes when contract services are up and fails when a service is stopped.
{
  pkgs ? import <nixpkgs> { },
}:
{
  name = "fleet-healthcheck-test";

  nodes.machine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ../../80-lib/81-helpers/mkServiceContract.nix
        ../../20-services/26-monitoring/fleet-healthcheck.nix
      ];

      config = {
        networking.hostName = "luffy";
        networking.extraHosts = "127.0.0.1 luffy.nfp.nix";
        system.stateVersion = "25.05";

        # Enable fleet healthcheck module
        layers.layer-20.services.config.fleet-healthcheck.enable = true;

        # Define 2 test services with contracts
        nfp.services = {
          dummy1 = {
            enable = true;
            host = "luffy";
            port = 8801;
            healthcheck = {
              enable = true;
              path = "/";
              expectedStatus = 200;
            };
          };

          dummy2 = {
            enable = true;
            host = "luffy";
            port = 8802;
            healthcheck = {
              enable = true;
              path = "/";
              expectedStatus = 200;
            };
          };
        };

        # Simple Python HTTP servers as dummy contract services
        systemd.services.dummy1 = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8801 --bind 127.0.0.1";
          };
        };

        systemd.services.dummy2 = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8802 --bind 127.0.0.1";
          };
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("dummy1.service")
    machine.wait_for_unit("dummy2.service")
    machine.wait_for_open_port(8801)
    machine.wait_for_open_port(8802)

    # 1. Assert fleet-healthcheck.service passes when services are up
    machine.succeed("systemctl start fleet-healthcheck.service")

    # 2. Stop dummy2 service
    machine.systemctl("stop dummy2.service")

    # 3. Assert fleet-healthcheck.service FAILS when dummy2 is stopped
    machine.fail("systemctl start fleet-healthcheck.service")
  '';
}
