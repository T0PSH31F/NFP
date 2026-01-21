{ lib, ... }:
{
  # SDDM theme is configured in themes/sddm-sel.nix
  # Only override greetd here to prevent conflicts
  services.greetd.enable = lib.mkForce false;
}
