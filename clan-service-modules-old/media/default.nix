{
  _class = "clan.service";
  manifest.name = "media";
  manifest.readme = "Media services including download managers";

  roles = {
    aria2 = {
      perInstance.nixosModule = ./aria2.nix;
      description = "Aria2: High-speed download manager with RPC support";
    };
  };
}
