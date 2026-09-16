# NixOS VM test: headscale control server starts, health endpoint OK,
# and preauth keys can be created (regression: secret/ACL wiring).
{
  name = "headscale-test";

  nodes.machine =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.headscale = {
        enable = true;
        address = "127.0.0.1";
        port = 8086;
        settings = {
          server_url = "http://127.0.0.1:8086";
          dns = {
            magic_dns = true;
            base_domain = "tailnet.test";
            nameservers.global = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
          # Test VM has no internet — enable embedded DERP so headscale never
          # fetches from controlplane.tailscale.com (fails without DNS).
          derp = {
            server = {
              enabled = true;
              stun_listen_addr = "0.0.0.0:3478";
            };
            auto_update = false;
            auto_update_enabled = false;
            urls = [ ];
          };
        };
      };
      # headscale needs a user before preauth keys can be created
      environment.systemPackages = [ pkgs.headscale ];
      system.stateVersion = "25.05";
    };

  testScript = ''
    start_all()

    machine.wait_for_unit("headscale.service")
    machine.wait_for_open_port(8086)

    # Health endpoint
    machine.succeed("curl -s --max-time 5 http://127.0.0.1:8086/health | grep -q pass")

    # Create a user (headscale 0.23+ CLI)
    machine.succeed("headscale users create testuser 2>&1 || true")

    # Preauth key generation works
    machine.succeed("headscale preauthkeys create --user 1 --expiration 1h")

    # Node list is empty but functional
    machine.succeed("headscale nodes list")

    print("headscale-test: all assertions passed")
  '';
}
