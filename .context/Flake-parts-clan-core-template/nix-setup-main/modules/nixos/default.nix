{
  berkeley-mono = import ./berkeley-mono;
  omarchy-config = import ./omarchy-config.nix;

  nextcloud = import ./nextcloud.nix;
  immich = import ./immich.nix;
  plex = import ./plex.nix;
  home-assistant = import ./home-assistant.nix;
  nginx-recommended = import ./nginx-recommended.nix;
  roon-server = import ./roon-server.nix;
  jellyfin = import ./jellyfin.nix;
  overseerr = import ./overseerr.nix;
}
