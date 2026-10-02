{ config, ... }: {
  services.harmonia.cache.enable = true;

  services.nixos-passthru-cache = {
    enable = true;
    hostName = "${config.networking.hostName}.nfp.nix";
    lanMode = true;
    stats = {
      enable = true;
      allowLocalOnly = false;
      path = "/stats";
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];

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
      substituters = [
        "https://cache.nixos.org"
        "http://luffy.nfp.nix:5000"
        "http://z0r0.nfp.nix:5000"
        "http://nami.nfp.nix:5000"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
        "https://cache.numtide.com"
        "https://yazelix.cachix.org" # disabled: timing out during downloads
      ];

      # Set the trusted public keys for the substituters above
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache-1:YhXcvDzqzmRyP4QCsHbH67iYcX7L0fGUt7dNfEGzJz0="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "numtide.cachix.org-1:vSxzZPSh9OCpqJc572Mk9BdbrGMNSbR4F5O4/jVtHK8="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "yazelix.cachix.org-1:ZgxIjQvaP0VTWL8Racx27mpUNzDJ97xC2y7QWYjmGNM="
      ];

      # Ensure these are trusted for non-root users
      trusted-substituters = [
        "http://luffy.nfp.nix:5000"
        "http://z0r0.nfp.nix:5000"
        "http://nami.nfp.nix:5000"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://cache.numtide.com"
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
      ];
    };
  };
}
