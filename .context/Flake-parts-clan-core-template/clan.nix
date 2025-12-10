{
  # Ensure this is unique among all clans you want to use.
  meta.name = "henry-clan";
  meta.tld = "henry";

  inventory.machines = {
    # Define machines here.
     luffy = { };
  };

  # Docs: See https://docs.clan.lol/reference/clanServices
  inventory.instances = {

    # Docs: https://docs.clan.lol/reference/clanServices/admin/
    # Admin service for managing machines
    # This service adds a root password and SSH access.
    # Admin service for managing machines
    # This service adds a root password and SSH access.
    admin = {
      roles.default.tags.all = { };
      roles.default.settings.allowedKeys = {
        # SSH keys will be managed through clan-core vars framework
        # Keys will be automatically populated when clan vars generate is run
      };
    };

    # Docs: https://docs.clan.lol/reference/clanServices/zerotier/
    # The lines below will define a zerotier network and add all machines as 'peer' to it.
    # !!! Manual steps required:
    #   - Define a controller machine for the zerotier network.
    #   - Deploy the controller machine first to initialize the network.
    # zerotier = {
    #   # Replace with the name (string) of your machine that you will use as zerotier-controller
    #   # See: https://docs.zerotier.com/controller/
    #   # Deploy this machine first to create the network secrets
    #   roles.controller.machines."luffy" = { };
    #   # Peers of the network
    #   # tags.all means 'all machines' will joined
    #   roles.peer.tags.all = { };
    # };

    # Docs: https://docs.clan.lol/reference/clanServices/tor/
    # Tor network provides secure, anonymous connections to your machines
    # All machines will be accessible via Tor as a fallback connection method
    tor = {
      roles.server.tags.nixos = { };
    };
  };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
    luffy = { config, lib, pkgs, inputs', ... }: {
      # Import the machine-specific configuration
      imports = [ ./machines/luffy/default.nix ];
      
      # Machine-specific overrides can go here
      # networking.hostName = "luffy";
    };
  };
}
