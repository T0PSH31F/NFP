{
  imports = [
    ./clan-service-modules/default.nix
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
    };

  };

  machines = {
    z0r0 =
      { ... }:
      {
        imports = [ ./machines/z0r0/default.nix ];
        clan.services.ai.sillytavern.enable = true;
      };
    nami =
      { ... }:
      {
        imports = [ ./machines/nami/default.nix ];
      };
  };
}
