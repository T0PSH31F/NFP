{ config, lib, ... }: {
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
        # DISABLED (2026-10-12): nami.nfp.nix (100.64.0.4) is off the tailnet
        # (100% packet loss). Every miss against it burns connect-timeout x
        # download-attempts before falling through, which serializes builds and
        # eventually kills the nix daemon mid-query. Re-add once nami is back:
        #   "http://nami.nfp.nix:5000"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
        "https://cache.numtide.com"
        "https://yazelix.cachix.org"
      ];

      # Substituter timeouts. A dead cache costs connect-timeout x
      # download-attempts per missed path; with the nix defaults (5 x 5) that
      # is 25s of dead time per miss before nix falls through to the next
      # cache, and enough cumulative stalls to make the daemon give up
      # mid-query. 2 x 2 caps the worst case at 4s per unreachable cache
      # while still tolerating ordinary tailnet latency.
      #
      # mkForce: clanCore/nix-settings.nix also sets connect-timeout = 5.
      connect-timeout = lib.mkForce 2;
      download-attempts = lib.mkForce 2;

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
