{ inputs, ... }:
{
  perSystem =
    {
      system,
      ...
    }:
    {
      packages.iso =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit (import ../layers/80-lib/81-helpers/mkDendriticModule.nix { inherit (inputs.nixpkgs) lib; })
              mkDendriticModule
              ;
            inherit (import ../layers/80-lib/81-helpers/mkDendriticTree.nix { inherit (inputs.nixpkgs) lib; })
              mkDendriticTree
              ;
          };
          modules = [
            ../layers/00-cyberia/04-templates/iso/default.nix
          ];
        }).config.system.build.isoImage;
    };
}
