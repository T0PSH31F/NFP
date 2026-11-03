{
  description = "jarvis-fleet — Multi-Tenant Customer Deployment Repository (Clan-Core + SOPS-Nix)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jarvis-core.url = "path:/home/t0psh31f/Clan/Jarvis";
  };

  outputs =
    {
      nixpkgs,
      jarvis-core,
      ...
    }:
    {
      nixosConfigurations = {
        acme-services = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            jarvis-core.nixosModules.default
            ./configuration.nix
          ];
        };
      };

      clanInventory = {
        machines.acme-services = {
          tags = [
            "jarvis-appliance"
            "ai-router"
            "ai-agent"
          ];
          deploy.targetHost = "root@acme-appliance.internal";
        };
      };
    };
}
