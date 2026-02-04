{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # ./hardware-configuration.nix # Disabled until hardware arrives
    ./disko.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/overlays.nix
    ../../modules/clan/tags.nix
    ../../modules/clan/lib.nix
    ../../modules/clan/metadata.nix
    ../../modules/clan/service-distribution.nix
    ../../modules/clan/secrets.nix

    ../../modules/nixos/default.nix
    ../../modules/nixos/hardware/nvidia-hybrid.nix
    ../../packages/default.nix

    ../../modules/users/t0psh31f.nix
  ];

  config = {
    networking.hostName = "luffy";
    system.stateVersion = "25.05";

    clan.tags = [
      "desktop"
      "gaming"
      "ai-heavy"
      "nvidia"
    ];

    # Themes
    themes.plymouth-hellonavi.enable = true;
    themes.grub-lain.enable = true;

    # Gaming
    gaming.enable = true;

    # AI Services
    services.ai-services = {
      enable = true;
      open-webui.enable = true;
      ollama.enable = true;
      ollama.acceleration = "cuda"; # Nvidia GPU
      sillytavern.enable = false; # Use Clan Service
    };

    # Impermanence
    system-config.impermanence.enable = true;

    # Home-Manager
    home-manager.users.t0psh31f = {
      # programs.vicinae.enable = true;
    };
  };
}
