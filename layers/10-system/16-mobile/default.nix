# Mobile Tier Entry Point & Common Integrations
{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-10.system.mobile;
in
{
  imports = [
    ./android.nix
    ./ios.nix
  ];

  config = lib.mkIf (cfg.android.enable || cfg.ios.enable) {
    # KDE Connect / GSConnect
    # Allows wireless file transfer, clipboard sync, notifications
    programs.kdeconnect.enable = true;
  };
}
