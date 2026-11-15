{
  name = "ai-services-test";
  nodes.machine =
    {
      lib,
      ...
    }:
    {
      imports = [
        ../../20-services/21-networking/endpoints.nix
        ../../70-agents/78-llm-routers/extreme-router.nix
        ../../70-agents/76-orchestrators/aionui.nix
        ../../70-agents/76-orchestrators/mission-control.nix
      ];

      # Mock requirements for isolated test evaluation
      options = {
        layers.layer-10.system.config.impermanence.enable = lib.mkEnableOption "impermanence";
        environment.persistence = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
        layers.meta.primaryUser = lib.mkOption {
          type = lib.types.str;
          default = "t0psh31f";
        };
        nfp.services = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
        clan.core.vars.generators = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              freeformType = lib.types.anything;
              options.files = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    freeformType = lib.types.anything;
                    options.path = lib.mkOption {
                      type = lib.types.str;
                      default = "/dev/null";
                    };
                  }
                );
                default = { };
              };
            }
          );
          default = { };
        };
        sops = {
          secrets = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                freeformType = lib.types.anything;
                options.path = lib.mkOption {
                  type = lib.types.str;
                  default = "/dev/null";
                };
              }
            );
            default = { };
          };
          templates = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                freeformType = lib.types.anything;
                options.path = lib.mkOption {
                  type = lib.types.str;
                  default = "/dev/null";
                };
              }
            );
            default = { };
          };
          placeholder = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {
              extremerouter_api_key = "test-placeholder";
            };
          };
        };
      };

      config = {
        _module.args.inputs = { };
        users.users.t0psh31f = {
          isNormalUser = true;
          home = "/home/t0psh31f";
          group = "users";
        };

        layers = {
          layer-10.system.config.impermanence.enable = false;

          layer-76.orchestrators = {
            aionui = {
              enable = true;
              port = 3006;
            };
            mission-control = {
              enable = true;
              port = 3099;
            };
          };

          layer-78.llm-routers.extreme-router = {
            enable = true;
            port = 20128;
          };
        };

        system.stateVersion = "25.05";
        networking.firewall.enable = true;
      };
    };

  testScript = ''
    start_all()

    # Wait for aionui service
    machine.wait_for_unit("aionui.service")
    machine.wait_for_open_port(3006)

    # Verify sentinel persistence across service restart
    machine.succeed("echo 'sentinel-test' > /var/lib/aionui/sentinel.txt")
    machine.succeed("systemctl restart aionui.service")
    machine.wait_for_unit("aionui.service")
    machine.succeed("grep -q 'sentinel-test' /var/lib/aionui/sentinel.txt")

    # Check data directory setup for extreme-router & mission-control
    machine.succeed("echo 'sentinel-router' > /var/lib/extreme-router/sentinel.txt")
    machine.succeed("test -f /var/lib/extreme-router/sentinel.txt")

    machine.succeed("echo 'sentinel-mc' > /var/lib/mission-control/sentinel.txt")
    machine.succeed("test -f /var/lib/mission-control/sentinel.txt")
  '';
}
