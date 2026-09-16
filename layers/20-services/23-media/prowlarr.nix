{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.layers.layer-20.services.config.media-stack.enable {
    services.prowlarr = {
      enable = true;
    };

    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce config.layers.layer-20.services.config.media-stack.user;
      Group = lib.mkForce config.layers.layer-20.services.config.media-stack.group;
      # NOTE: /var/lib/prowlarr is a bind-mounted impermanence dir (owned by media:media,
      # created via tmpfiles in media-stack.nix). Do NOT set StateDirectory here —
      # systemd's StateDirectory migration conflicts with the mount ("Device or resource busy").
      PrivateTmp = lib.mkForce false;
      ProtectSystem = lib.mkForce false;
      ProtectHome = lib.mkForce false;
      ReadWritePaths = [ "/var/lib/prowlarr" ];
    };
  };
}
