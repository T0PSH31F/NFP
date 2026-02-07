# clan-services/binary-cache/module.nix
# Clan service definition for Harmonia binary cache
{
  _class = "clan.service";
  manifest.name = "binary-cache";
  manifest.readme = "Harmonia Nix binary cache server";

  roles = {
    harmonia = {
      perInstance.nixosModule = ./harmonia.nix;
      description = "Harmonia: Nix binary cache server";
    };
  };
}
