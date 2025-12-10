{
  inputs.clan-core.url = "https://git.clan.lol/clan/clan-core/archive/0b5a8e98dea4351a86e95cc81f5142945ae8086e.tar.gz";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "clan-core/nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager/release-25.05";
  inputs.omarchy-nix.url = "github:omarchy/omarchy-nix";
  inputs.omarchy-nix.inputs.nixpkgs.follows = "clan-core/nixpkgs";

  outputs =
    inputs@{
      flake-parts,
      clan-core,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = [
        inputs.clan-core.flakeModules.default
      ];

      # https://docs.clan.lol/guides/flake-parts
      clan = {
        imports = [ ./clan.nix ];
      };

      perSystem =
        { pkgs, inputs', ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              inputs'.clan-core.packages.clan-cli
              git
              nix
              vim
            ];
          };
        };
    };
}
