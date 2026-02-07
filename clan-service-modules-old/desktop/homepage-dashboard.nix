{
  config,
  pkgs,
  ...
}:

{
  # Clan facts - machine-specific generated data
  clan.core.facts.services.homepage-dashboard = {
    secret.api_keys = {
      name = "homepage-api-keys";
      generator.script = ''
        echo "sonarr=$(${pkgs.openssl}/bin/openssl rand -hex 32)" > "$facts"/api_keys
        echo "radarr=$(${pkgs.openssl}/bin/openssl rand -hex 32)" >> "$facts"/api_keys
        echo "prowlarr=$(${pkgs.openssl}/bin/openssl rand -hex 32)" >> "$facts"/api_keys
      '';
    };

    public.port = {
      name = "homepage-port";
      value = toString config.services-config.homepage-dashboard.port;
    };
  };

  # Import the actual module
  imports = [ ../modules/nixos/services/homepage-dashboard.nix ];
}
