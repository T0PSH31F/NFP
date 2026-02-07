{
  _class = "clan.service";
  manifest.name = "desktop";
  manifest.readme = "Desktop environment configuration with multiple compositor support (Hyprland/Niri)";

  roles = {
    # SSH Agent Service
    ssh-agent = {
      perInstance.nixosModule = ./ssh-agent.nix;
      description = "SSH Agent: Secure SSH key management for desktop sessions";
    };

    # SearxNG Metasearch Engine
    searxng = {
      perInstance.nixosModule = ./searxng.nix;
      description = "SearxNG: Privacy-respecting metasearch engine";
    };

    # PrivateBin Pastebin
    pastebin = {
      perInstance.nixosModule = ./pastebin.nix;
      description = "PrivateBin: Secure, encrypted pastebin service";
    };

    homepage-dashboard = {
      perInstance.nixosModule = ./homepage-dashboard.nix;
      description = "Homepage Dashboard: Dashboard for monitoring and managing services";
    };
  };
}
