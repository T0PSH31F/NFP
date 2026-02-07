{ inputs, ... }:
{
  # Clan Inventory - Service Instance Definitions
  # Using official clan-core modules for standardized deployment

  clan.inventory = {
    # ==========================================================================
    # ADMIN & SSH ACCESS
    # ==========================================================================

    instances.admin-access = {
      module = {
        name = "admin";
        input = "clan-core";
      };
      roles.default = {
        tags.all = { }; # Deploy to all machines
        settings = {
          allowedKeys = {
            t0psh31f = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqbW9FmXJYRYJWgYzQY2gYQmMqvBYvWgMy0YJmN6QKz t0psh31f@z0r0";
          };
          certificateSearchDomains = [ "grandlix.local" ];
        };
      };
    };

    instances.sshd-cluster = {
      module = {
        name = "sshd";
        input = "clan-core";
      };
      roles.server = {
        tags.all = { }; # All machines are SSH servers
        settings = {
          certificate.searchDomains = [ "grandlix.local" ];
        };
      };
      roles.client = {
        tags.all = { }; # All machines are SSH clients
      };
    };

    # ==========================================================================
    # USER MANAGEMENT
    # ==========================================================================

    instances.user-t0psh31f = {
      module = {
        name = "users";
        input = "clan-core";
      };
      roles.default = {
        tags.all = { }; # User on all machines
        settings = {
          user = "t0psh31f";
          prompt = false; # Auto-generate password securely
          share = true; # Share same password across machines
          groups = [
            "wheel"
            "networkmanager"
            "video"
            "input"
            "docker"
            "libvirtd"
            "media"
            "podman"
          ];
        };
      };
    };

    # ==========================================================================
    # PACKAGE MANAGEMENT (Dendritic Pattern with Importer)
    # ==========================================================================

    instances.base-packages = {
      module = {
        name = "importer";
        input = "clan-core";
      };
      roles.default = {
        tags.all = { }; # Base packages on all machines
        extraModules = [ ./features/nixos/packages/base.nix ];
      };
    };

    instances.desktop-packages = {
      module = {
        name = "importer";
        input = "clan-core";
      };
      roles.default = {
        tags = [
          "desktop"
          "laptop"
        ]; # Only desktop machines
        extraModules = [ ./features/nixos/packages/desktop.nix ];
      };
    };

    instances.ai-packages = {
      module = {
        name = "importer";
        input = "clan-core";
      };
      roles.default = {
        tags = [ "ai-server" ]; # Only AI server machines
        extraModules = [ ./features/nixos/packages/ai.nix ];
      };
    };

    instances.dev-packages = {
      module = {
        name = "importer";
        input = "clan-core";
      };
      roles.default = {
        tags = [ "dev" ]; # Development machines
        extraModules = [ ./features/nixos/packages/dev.nix ];
      };
    };

    instances.media-packages = {
      module = {
        name = "importer";
        input = "clan-core";
      };
      roles.default = {
        tags = [ "media-server" ]; # Media server machines
        extraModules = [ ./features/nixos/packages/media.nix ];
      };
    };

    # ==========================================================================
    # MATRIX SYNAPSE HOMESERVER
    # ==========================================================================

    instances.matrix-homeserver = {
      module = {
        name = "matrix-synapse";
        input = "clan-core";
      };
      roles.default = {
        machines.z0r0 = {
          # Only on z0r0
          settings = {
            acmeEmail = "admin@grandlix.com";
            server_tld = "grandlix.local";
            app_domain = "matrix.grandlix.local";
            users = {
              t0psh31f = {
                admin = true;
              };
            };
          };
        };
      };
    };

    # ==========================================================================
    # NEXTCLOUD SERVER (via NCPS)
    # ==========================================================================

    instances.nextcloud-server = {
      module = {
        name = "ncps";
        input = "clan-core";
      };
      roles.server = {
        machines.z0r0 = {
          # Only on z0r0
          settings = {
            domain = "cloud.grandlix.local";
            adminEmail = "admin@grandlix.com";
          };
        };
      };
    };
  };
}
