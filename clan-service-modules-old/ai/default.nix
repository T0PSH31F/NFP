{
  _class = "clan.service";
  manifest.name = "ai";
  manifest.readme = "AI services and frontends";

  roles = {
    sillytavern = {
      perInstance.nixosModule = ./sillytavern.nix;
      description = "SillyTavern: AI chat frontend";
    };
  };
}
