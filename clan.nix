{
  meta.name = "Grandlix-Gang";

  inventory = {
    machines = {
      luffy = {
        tags = ["client" "laptop"];
        deploy.targetHost = "root@192.168.1.182";
      };
      z0r0 = {
        tags = ["client" "laptop"];
        deploy.targetHost = "root@192.168.1.159";
      };
    };

    instances = {
      # Admin user configuration
      admin = {
        roles.default.tags.all = {};
        roles.default.settings = {
          allowedKeys = {
            "t0psh31f" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang";
          };
        };
      };
    };
  };

  machines = {
    luffy = {...}: {
      imports = [./machines/luffy/default.nix];
    };
    z0r0 = {...}: {
      imports = [./machines/z0r0/default.nix];
    };
  };
}
