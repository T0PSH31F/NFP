{ config, lib, ... }:

{
  clan.core = {
    clanDir = ../../.;
    machineName = config.networking.hostName;

    # Machine roles for service distribution
    facts.services.roles =
      if config.networking.hostName == "z0r0" then
        [
          "desktop"
          "ai-server"
          "build-server"
          "binary-cache"
          "database"
        ]
      else if config.networking.hostName == "nami" then
        [
          "media-server"
          "download-server"
        ]
      else if config.networking.hostName == "luffy" then
        [
          "desktop"
          "gaming"
          "ai-heavy"
        ]
      else
        [ ];
  };
}
