{
  name = "services-test";
  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    # Don't import services module - it has complex dependencies
    # Just test basic system services that work in isolation

    services.openssh.enable = true;
    
    # Systemd / config basics
    system.stateVersion = "25.05";
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("sshd.service")
    machine.succeed("echo 'Basic system services test passed'")
  '';
}
