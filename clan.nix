{
  meta.name = "Grandlix-Gang";

  inventory = {
    machines = {
      z0r0 = {
        tags = [
          "client"
          "laptop"
        ];
        deploy.targetHost = "root@localhost";
      };
      Nami = {
        tags = [
          "client"
          "laptop"
        ];
        deploy.targetHost = "root@nami.local";
      };
    };

    instances = {
      # Admin user configuration
      admin = {
        roles.default.tags.all = { };
        roles.default.settings = {
          allowedKeys = {
            "t0psh31f" =
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang";
          };
        };
      };
    };
  };

  machines = {
    z0r0 =
      { ... }:
      {
        imports = [ ./machines/z0r0/default.nix ];
      };
    Nami =
      { ... }:
      {
        imports = [ ./machines/Nami/default.nix ];
      };
  };
}
