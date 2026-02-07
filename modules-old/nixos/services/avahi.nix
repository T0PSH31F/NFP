{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.services-config.avahi = {
    enable = mkEnableOption "Avahi mDNS/DNS-SD daemon for local hostname resolution";
  };

  config = mkIf config.services-config.avahi.enable {
    # Enable Avahi daemon for mDNS (Zeroconf)
    services.avahi = {
      enable = true;

      # Allow hostname resolution without .local suffix
      nssmdns4 = true;
      nssmdns6 = true;

      # Publish machine information
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };

      # Allow interfaces
      allowInterfaces = [
        "wlp0s20f3" # WiFi
        "enp0s31f6" # Ethernet
        "tailscale0" # Tailscale VPN
      ];

      # Extra configuration
      extraConfig = ''
        [server]
        use-ipv4=yes
        use-ipv6=yes
        check-response-ttl=no
        use-iff-running=no

        [wide-area]
        enable-wide-area=yes

        [publish]
        publish-aaaa-on-ipv4=yes
        publish-a-on-ipv6=yes
      '';
    };

    # Open firewall for mDNS
    networking.firewall.allowedUDPPorts = [5353]; # mDNS

    # Install Avahi utilities
    environment.systemPackages = with pkgs; [
      avahi # avahi-browse, avahi-resolve, etc.
    ];
  };
}
