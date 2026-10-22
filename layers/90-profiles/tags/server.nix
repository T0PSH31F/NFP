# server — adguard, monitoring, tailscale, restic
# Tags-as-data: all config gated by tag membership.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "server" config.machine.tags) {
    layers.layer-20.services.config = {
      adguard.enable = lib.mkDefault true;
      monitoring.enable = lib.mkDefault true;
      tailscale.enable = lib.mkDefault true;
    };

    layers.layer-20.services.backups.restic.enable = lib.mkDefault true;

    layers.desktop.experience = lib.mkDefault (
      if (builtins.elem "desktop" config.machine.tags) then "noctalia" else "none"
    );
  };
}
