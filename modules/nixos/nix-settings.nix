{
  config,
  lib,
  ...
}: {
  nix.settings = {
    # Binary cache substituters for faster package downloads
    extra-substituters = [
      "https://vicinae.cachix.org"
      "https://cache.numtide.com" # Numtide's cache
      "https://nix-community.cachix.org" # Nix community cache
      "https://cuda-maintainers.cachix.org" # CUDA maintainers cache
      "https://hyprland.cachix.org" # Hyprland cache
    ];

    # Trusted public keys for the above caches
    extra-trusted-public-keys = [
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNq7Ow="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7mC0pu+gNl4u4="
    ];

    # Additional Nix settings for better performance
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };
}
