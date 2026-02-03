{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # ./hardware-configuration.nix # Disabled until hardware arrives
    ./disko.nix
    ../../modules/nixos/default.nix
    ../../modules/nixos/hardware/nvidia-hybrid.nix
    ../../modules/Home-Manager/Desktop-env/default.nix
    ../../modules/Home-Manager/Desktop-env/Noctalia/default.nix
    ../../modules/users/t0psh31f.nix
  ];

  config = {
    networking.hostName = "luffy";
    system.stateVersion = "25.05";

    # Desktop
    desktop.noctalia.enable = true;
    desktop.noctalia.backend = "hyprland";

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
      programs.vicinae.enable = true;
    };
  };
}
