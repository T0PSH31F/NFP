# homelab — home-assistant, searxng, vaultwarden, n8n, mautrix-style services
# Tags-as-data: all config gated by tag membership.
# Honcho moved to pkb-node. Headscale moved to network-router.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "homelab" config.machine.tags) {
    services = {
      searxng.enable = lib.mkDefault true;
      home-assistant-server.enable = lib.mkDefault true;
      vaultwarden-server.enable = lib.mkDefault true;
      filebrowser-app.enable = lib.mkDefault true;
      glances-server.enable = lib.mkDefault true;
      n8n-server.enable = lib.mkDefault true;

      postgresql.enableTCPIP = lib.mkDefault true; # Enable remote Postgres for MatrixDB, honcho, etc.

      mautrix-bridges = {
        enable = lib.mkDefault true;
        homeserverUrl = lib.mkDefault "http://localhost:8008";
        homeserverDomain = lib.mkDefault "matrix.lovelain.duckdns.org";
        whatsapp.enable = lib.mkDefault true;
        signal.enable = lib.mkDefault true;
      };
    };

    layers.layer-20.services.config = {
      ntfy-sh.enable = lib.mkDefault true;
      ntfy-sh.port = lib.mkDefault 8099;
    };
  };
}
