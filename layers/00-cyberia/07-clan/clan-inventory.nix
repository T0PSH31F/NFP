_: {
  # Clan Inventory - Service Instance Definitions
  # Using official clan-core modules for standardized deployment

  clan.inventory = {
    # ==========================================================================
    # ADMIN & SSH ACCESS
    # ==========================================================================

    instances = {
      sshd-cluster = {
        module = {
          name = "sshd";
          input = "clan-core";
        };
        roles.server = {
          tags.all = { }; # All machines are SSH servers
          settings = {
            certificate.enable = false;
            authorizedKeys = {
              "grandlix-key" =
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang";
              "luffy" =
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg4e32XqA2CyYsHyl+urGN1Soiz00DLgc+dkDw/uFCw luffy@agentaflow.com";
              "deploy-key" =
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmFwvzW1t3Bs5kvXDIBx9FyVpiusL+rGPaazuPV62wK deploy-key@nfp";
            };
          };
        };
        roles.client = {
          tags.all = { }; # All machines are SSH clients
        };
      };

      root-user = {
        module = {
          name = "users";
          input = "clan-core";
        };
        roles.default = {
          tags.all = { };
          settings = {
            user = "root";
            prompt = true; # Prompt for root password during 'clan vars generate'
          };
        };
      };

      user-t0psh31f = {
        module = {
          name = "users";
          input = "clan-core";
        };
        roles.default = {
          tags.all = { }; # User on all machines
          settings = {
            user = "t0psh31f";
            prompt = true; # Prompt for password during 'clan vars generate'
            share = true; # Share same password across machines
            groups = [
              "wheel"
              "networkmanager"
              "video"
              "audio"
              "input"
              "podman"
              "libvirtd"
              "media"
              "i2c"
            ];
          };
        };
      };

      matrix-homeserver = {
        module = {
          name = "matrix-synapse";
          input = "clan-core";
        };
        roles.default = { };
      };
    };
  };
}
