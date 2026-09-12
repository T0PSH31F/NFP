# HM Catalog — minimal HM module imports for headless hosts (nami).
# Imported by server-layers.nix — NOT by all-layers.nix (z0r0/luffy get
# these from 13-users/t0psh31f.nix directly).
# Only includes modules whose option-definitions are needed by NixOS modules
# imported via server-layers (e.g. 40-desktop/43-noctalia, 44-de-frameworks).
# Desktop-launcher HM modules (vicinae, spicetify, etc.) are excluded —
# their NixOS config is gated by cfg.enable which is false on headless hosts,
# and importing the HM module here pulls in XDG portal assertions.
{
  inputs,
  lib,
  ...
}:
{
  home-manager.users.t0psh31f = {
    home.stateVersion = "25.05";
    imports = [
      inputs.sops-nix.homeManagerModules.sops
      # Vicinae HM module — needed so the services.vicinae option exists
      # in the NixOS module graph (40-desktop/44-de-frameworks/vicinae.nix
      # references it inside mkIf cfg.enable). On headless hosts cfg.enable
      # is always false, so vicinae never activates.
      inputs.vicinae.homeManagerModules.default
    ];
  };
}
