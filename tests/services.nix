{
  name = "services-test";
  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      ../modules/nixos/services/default.nix
    ];

    # Enable a subset of services to verify startup
    # We avoid enabling ALL heavy ML services to keep the test reasonably fast/light
    services.home-assistant-server.enable = true;
    services.caddy-server.enable = true;
    services.caddy.virtualHosts.":80" = {
      extraConfig = ''
        respond "OK"
      '';
    };
    services.caddy-server.email = "wrighterik77@gmail.com";
    services-config.monitoring.enable = true; # Grafana/Prometheus

    # Enable Avahi (low cost)
    services-config.avahi.enable = true;

    # Allow firewall for testing
    networking.firewall.enable = false;

    # Systemd / config basics
    system.stateVersion = "24.05";
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("home-assistant.service")
    machine.wait_for_unit("caddy.service")
    machine.wait_for_unit("grafana.service")
    machine.wait_for_unit("prometheus.service")

    # Monitor ports
    machine.wait_for_open_port(8123) # HASS
    machine.wait_for_open_port(3000) # Grafana
    machine.wait_for_open_port(9090) # Prometheus

    # Verify simple response
    machine.succeed("curl -f http://localhost:9090/-/healthy")
  '';
}
