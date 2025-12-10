{pkgs, ...}: {
  nix.settings.trusted-users = ["henry" "wheel"];
  environment.systemPackages = with pkgs; [
    git
    neovim
    curl
    wget
    htop
    docker-compose
  ];

  services.samba.enable = true;
  services.openssh.enable = true;
  virtualisation.docker.enable = true;
  # firewall, auth
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.trustedInterfaces = ["tailscale0"];
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  security.sudo.extraRules = [
    {
      users = ["henry"];
      commands = [
        {
          command = "ALL";
          options = [];
        }
      ];
    }
  ];
}
