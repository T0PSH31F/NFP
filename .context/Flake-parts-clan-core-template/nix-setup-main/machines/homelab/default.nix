{
  pkgs,
  inputs,
  outputs,
  modulesPath,
  ...
}: {
  imports = [
    # inputs.disko.nixosModules.disko

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix

    ../../modules/users/henry.nix
    ../../modules/nixos/common.nix

    ../common/global.nix
    ../common/dev.nix
    ../common/samba.nix

    # Services
    ../common/homelab/homelab.nix
    # ../common/homelab/cloudflare.nix
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [8123 3000];

  roonServer.enable = true;
  roonServer.openFirewall = true;

  networking.hostName = "homelab-1";
  security.polkit.enable = true;
  boot.loader = {
    timeout = 5;
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
    };
  };

  # Services
  nextcloud.enable = true;
  nextcloud.subDomainName = "cloud";
  nextcloud.baseDomainName = "sipp.family";

  immich.enable = true;
  immich.subDomainName = "photos";
  immich.baseDomainName = "sipp.family";

  plex.enable = true;
  plex.subDomainName = "plex";
  plex.baseDomainName = "sipp.family";

  homeAssistant.enable = true;
  homeAssistant.subDomainName = "home";
  homeAssistant.baseDomainName = "sipp.family";

  nginxRecommended.enable = true;
  nginxRecommended.baseDomainName = "sipp.family";
  nginxRecommended.acmeEmail = "henry.sipp@hey.com";

  jellyfin.enable = true;
  jellyfin.subDomainName = "jellyfin";
  jellyfin.baseDomainName = "sipp.family";

  overseerr.enable = true;
  overseerr.subDomainName = "overseerr";
  overseerr.baseDomainName = "sipp.family";

  system.stateVersion = "25.05";
}
