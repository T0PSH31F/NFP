# Komga Comic/Manga Server
# modules/nixos/services/komga.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services-config.komga;
in
{
  options.services-config.komga = {
    enable = mkEnableOption "Komga comic/manga server";

    port = mkOption {
      type = types.port;
      default = 25600;
      description = "Web interface port";
    };

    libraryPath = mkOption {
      type = types.str;
      default = "/persist/data/media/comics";
      description = "Path to comic/manga library";
    };
  };

  config = mkIf cfg.enable {
    services.komga = {
      enable = true;
      port = cfg.port;
      openFirewall = true;
    };

    # Impermanence support
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/komga";
          user = "komga";
          group = "komga";
          mode = "0700";
        }
      ];
    };
  };
}
