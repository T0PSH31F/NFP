{
  config,
  ...
}:

{
  # services.harmonia configuration removed to avoid conflict with service-distribution.nix
  # which handles it via 'binary-cache' tag.

  # Open firewall
  networking.firewall.allowedTCPPorts = [ 5000 ];

  # SOPS secret for signing key
  sops.secrets."harmonia/signing-key" = {
    sopsFile = ../../../secrets/harmonia.yaml;
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
