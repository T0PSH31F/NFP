{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.aria2;
  user = "media"; # Consolidate user here or reference media-stack options?
  group = "media";
  dataDir = "/var/lib/media"; # Default or reference media-stack?
  downloadsDir = "/var/lib/media/downloads";
in
{
  # If we want to expose options for this service module specifically:
  options.clan.services.media.aria2 = {
    enable = mkEnableOption "Aria2 Clan Service";
  };

  config = mkIf config.clan.services.media.aria2.enable {
    # Re-use existing service options or define new ones?
    # We'll use standard services.aria2 but assume defaults from this module

    environment.systemPackages = [ pkgs.aria2 ];

    services.aria2 = {
      enable = true;
      openFirewall = true;
      rpcSecretFile = config.sops.secrets."services/aria2/rpc-secret".path or null; # Use sops if available, else manual?
      # If using sops via clan vars:
      # rpcSecretFile = config.clan.core.vars.generators.aria2.files.rpc-secret.path;

      settings = {
        dir = "${downloadsDir}/aria2";
        enable-rpc = true;
        rpc-listen-port = 6800;
        rpc-listen-all = true;
        max-concurrent-downloads = 5;
        continue = true;
        save-session = "/var/lib/aria2/session.gz";
        input-file = "/var/lib/aria2/session.gz";
        save-session-interval = 60;
      };
    };

    # Directory creation
    systemd.tmpfiles.rules = [
      "d ${downloadsDir}/aria2 0755 ${user} ${group} -"
      "d /var/lib/aria2 0750 ${user} ${group} -"
      "f /var/lib/aria2/session.gz 0644 ${user} ${group} -"
    ];

    # Persistence
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [ "/var/lib/aria2" ];
    };

    # Ensure user exists (if not created by media-stack)
    # We assume media-stack handles user creation for now, or we duplicate it safely.
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      extraGroups = [
        "video"
        "render"
      ];
    };
    users.groups.${group} = { };
  };
}
