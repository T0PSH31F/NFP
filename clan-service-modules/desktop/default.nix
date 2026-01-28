{
  _class = "clan.service";
  manifest.name = "desktop";
  manifest.readme = "Desktop environment configuration with multiple compositor support (Hyprland/Niri)";

  roles = {
    # Caelestia Shell - Default DE with Hyprland
    caelestia = {
      perInstance.nixosModule = ./caelestia.nix;
      description = "Caelestia Shell: Modern Hyprland-based desktop with Aylur's widgets";
    };

    # Omarchy - Alternative Hyprland config
    omarchy = {
      perInstance.nixosModule = ./omarchy.nix;
      description = "Omarchy: Hyprland environment with custom theming";
    };

    # DankMaterialShell - Supports both Hyprland and Niri
    dankmaterial = {
      perInstance.nixosModule = ./dankmaterial.nix;
      description = "DankMaterialShell: Material Design shell for Hyprland/Niri";
    };

    # End-4 Illogical Impulse
    end4 = {
      perInstance.nixosModule = ./end4.nix;
      description = "End-4 Illogical Impulse: Feature-rich Hyprland configuration";
    };

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
  };
}
