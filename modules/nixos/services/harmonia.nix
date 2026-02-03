{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.harmonia = {
    enable = true;
    signKeyPath = config.sops.secrets."harmonia/signing-key".path;
    settings = {
      bind = "[::]:5000";
      workers = 4;
      max_connection_rate = 256;
      priority = 30;
    };
  };

  # Open firewall
  networking.firewall.allowedTCPPorts = [ 5000 ];

  # SOPS secret for signing key
  sops.secrets."harmonia/signing-key" = {
    sopsFile = ../../secrets/harmonia.yaml;
    owner = "harmonia";
    mode = "0400";
  };

  # Ensure harmonia user exists
  users.users.harmonia = {
    isSystemUser = true;
    group = "harmonia";
  };
  users.groups.harmonia = { };
}
