{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper function to check if machine has a role
  hasRole = role: builtins.elem role config.clan.core.facts.services.roles;
in
{
  # AI services (z0r0)
  services.ollama = lib.mkIf (hasRole "ai-server") {
    enable = true;
    # acceleration = "cuda"; # Enable if GPU present
    host = "0.0.0.0"; # Listen on all interfaces
    port = 11434;
  };

  # Media services (nami)
  # Using the existing media-stack module but enabling it conditionally
  services-config.media-stack.enable = lib.mkIf (hasRole "media-server") true;

  # Binary cache (z0r0)
  services.harmonia.enable = lib.mkIf (hasRole "binary-cache") true;

  # Gaming services (luffy)
  gaming.enable = lib.mkIf (hasRole "gaming") true;

  # Database services (z0r0)
  services.postgresql = lib.mkIf (hasRole "database") {
    enable = true;
    enableTCPIP = true;
    # authentication = lib.mkForce '' ... ''; # Configured in ai-services.nix
  };
}
