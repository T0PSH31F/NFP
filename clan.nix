{
  imports = [
    # ./clan-service-modules/default.nix # Removed due to class mismatch (clan.service vs clan)
  ];

  meta.name = "Grandlix-Gang";

  inventory = {
    machines = {
      z0r0 = {
        tags = [
          "desktop"
          "laptop"
          "ai-server"
          "build-server"
          "binary-cache"
          "database"
          "dev"
          "media-server"
        ];
        deploy.targetHost = "root@z0r0.local";
      };
      nami = {
        tags = [
          "desktop"
        ];
        deploy.targetHost = "root@nami.local";
      };
      # nami = {
      #   tags = [
      #     "server"
      #     "media-server"
      #     "download-server"
      #   ];
      #   deploy.targetHost = "root@nami.local";
      # };
      # luffy = {
      #   tags = [
      #     "desktop"
      #     "laptop"
      #     "gaming"
      #     "ai-heavy"
      #     "nvidia"
      #   ];
      #   deploy.targetHost = "root@luffy.local";
      # };
    };

    instances = {
      sillytavern = {
        module = {
          name = "ai";
          input = "self";
        };
        roles.sillytavern.machines = {
          z0r0 = { };
          # luffy = { };
        };
      };
    };
  };

  machines = {
    z0r0 = {
      imports = [
        ./machines/z0r0/default.nix
      ];
      clan.services.ai.sillytavern.enable = true;
    };
    nami = {
      imports = [
        ./machines/nami/default.nix
      ];
    };
  };
}
