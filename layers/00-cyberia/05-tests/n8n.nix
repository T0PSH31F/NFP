{ pkgs, ... }:
{
  name = "n8n-test";
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        ../../20-services/27-automation/n8n.nix
      ];

      # Mock requirements for n8n.nix to work in isolation
      options = {
        layers.layer-10.system.config.impermanence.enable = lib.mkEnableOption "impermanence";
        environment.persistence = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };

      config = {
        nixpkgs.pkgs = import pkgs.path {
          system = pkgs.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
        layers.layer-10.system.config.impermanence.enable = false;

        # Enable n8n
        services.n8n-server = {
          enable = true;
          port = 5678;
          openFirewall = true;
        };

        # Force StateDirectory to typical n8n path used in module
        systemd.services.n8n.serviceConfig.StateDirectory = lib.mkForce "n8n";

        # Basic system config
        system.stateVersion = "25.05";

        # Test with firewall enabled to verify port opening
        networking.firewall.enable = true;
      };
    };

  testScript = ''
    start_all()

    # Wait for n8n to start
    machine.wait_for_unit("n8n.service")
    machine.wait_for_open_port(5678)

    # Check if we can reach the health endpoint
    # Note: n8n might take a moment to be fully responsive
    machine.wait_until_succeeds("curl -f http://localhost:5678/healthz")
  '';
}
