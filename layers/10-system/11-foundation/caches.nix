# flake-parts/system/caches.nix
# Purpose:
# - Centralize binary cache configuration (substituters and trusted keys)
# - Ensure extra-trusted-substituters are correctly pulled in for all users

_: {
  nix = {
    sshServe = {
      enable = true;
      trusted = true;
      write = true;
    };
    settings = {
      trusted-users = [
        "root"
        "t0psh31f"
        "@wheel"
      ];
      # Set the main substituters list
      # cache.nixos.org FIRST — it's the most populous cache; checking smaller
      # caches first wastes a round-trip per path on misses.
      # cache.numtide.com kept last: unreachable from this network (timeouts).
      # mic92.cachix.org removed 2026-08-07: timed out during builds (progress.md).
      substituters = [
        "https://cache.nixos.org"
        "http://192.168.1.54:5000"
        "http://100.72.46.75:5000"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
        "https://yazelix.cachix.org"
        # "https://cache.garnix.io"  # DOWN: 502 Bad Gateway (2026-08-01) — re-enable when garnix recovers
        "https://cache.numtide.com" # unreachable from this network — last so timeouts don't delay working caches
      ];

      # Set the trusted public keys for the substituters above
      trusted-public-keys = [
        "nix-cache-1:YhXcvDzqzmRyP4QCsHbH67iYcX7L0fGUt7dNfEGzJz0="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "numtide.cachix.org-1:vSxzZPSh9OCpqJc572Mk9BdbrGMNSbR4F5O4/jVtHK8="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "yazelix.cachix.org-1:ZgxIjQvaP0VTWL8Racx27mpUNzDJ97xC2y7QWYjmGNM="
        # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="  # re-enable when garnix recovers
      ];

      # Ensure these are trusted for non-root users (making sure extra-trusted-substituters are pulled in)
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://cache.numtide.com"
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
        "https://yazelix.cachix.org"
      ];
    };
  };
}
