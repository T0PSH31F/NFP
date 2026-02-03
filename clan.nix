{
  imports = [
    # ./clan-service-modules/default.nix # Removed due to class mismatch (clan.service vs clan)
  ];

  meta.name = "Grandlix-Gang";

  inventory = {
    machines = {
      z0r0 = {
        tags = [
          "client"
          "laptop"
        ];
        deploy.targetHost = "root@z0r0.local";
      };
      nami = {
        tags = [
          "client"
          "laptop"
        ];
        deploy.targetHost = "root@nami.local";
      };
      luffy = {
        tags = [
          "client"
          "laptop"
        ];
        deploy.targetHost = "root@luffy.local";
      };
    };

    instances = {
      sillytavern = {
        module = {
          name = "ai";
          input = "self";
        };
        roles.sillytavern.machines = {
          z0r0 = { };
          luffy = { };
        };
      };
    };

  };

  machines = {
    z0r0 =
      { inputs, ... }:
      {
        imports = [
          ./machines/z0r0/default.nix
          ./modules/clan/metadata.nix
          ./modules/clan/service-distribution.nix
          ./modules/clan/secrets.nix
          inputs.sops-nix.nixosModules.sops
        ];
        clan.services.ai.sillytavern.enable = true;
      };
    luffy =
      { inputs, ... }:
      {
        imports = [
          ./machines/luffy/default.nix
          ./modules/clan/metadata.nix
          ./modules/clan/service-distribution.nix
          ./modules/clan/secrets.nix
          inputs.sops-nix.nixosModules.sops
        ];
        clan.services.ai.sillytavern.enable = true;
      };
    nami =
      { inputs, ... }:
      {
        imports = [
          ./machines/nami/default.nix
          ./modules/clan/metadata.nix
          ./modules/clan/service-distribution.nix
          ./modules/clan/secrets.nix
          inputs.sops-nix.nixosModules.sops
        ];
      };
  };
}
