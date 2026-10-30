{ lib, ... }:
let
  inherit (lib)
    attrNames
    flip
    ;

  varsForInstance = instanceName: pkgs: {
    clan.core.vars.generators.harmonia = {
      share = true;
      files = {
        sign-key = {
          secret = true;
          deploy = false;
        };
        pub-key.secret = false;
      };
      script = ''
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${instanceName}-1 \
          $out/sign-key \
          $out/pub-key
      '';
    };
  };
in
{
  _class = "clan.service";
  manifest = {
    name = "clan-core/nix-cache";
    description = "Serve the nix store between machines in your network";
    readme = builtins.readFile ./README.md;
    categories = [ "Utility" ];
  };

  roles.server = {
    description = "The server role provides the nix-cache service using harmonia";
    interface.options = {
      priority = lib.mkOption {
        type = lib.types.int;
        description = ''
          The priority of the cache. Lower values mean higher priority.
          The default is 50, which is a lower priority than cache.nixos.org which has 30.
        '';
        default = 50;
      };
    };

    perInstance =
      { settings, instanceName, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            imports = [
              (varsForInstance instanceName pkgs)
            ];

            clan.core.vars.generators.harmonia-private = {
              dependencies = [
                "harmonia"
              ];
              files.sign-key.secret = true;
              script = ''
                cp $in/harmonia/sign-key $out/sign-key
              '';
            };

            networking.firewall.allowedTCPPorts = [ 5000 ];

            services.harmonia.cache = {
              enable = true;
              signKeyPaths = [
                config.clan.core.vars.generators.harmonia-private.files.sign-key.path
              ];
              settings.priority = settings.priority;
            };
          };
      };
  };

  roles.client = {
    description = "The client role configures the machine to use the nix-cache server";
    perInstance =
      {
        instanceName,
        roles,
        ...
      }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            imports = [
              (varsForInstance instanceName pkgs)
            ];

            # trust and use the cache
            # Use mkAfter to append luffy AFTER the main substituters in caches.nix,
            # so cache.nixos.org and other reliable caches are tried first.
            nix.settings.substituters = lib.mkAfter (
              flip map (attrNames roles.server.machines) (machineName: "http://${machineName}.d:5000")
            );
            nix.settings.trusted-public-keys = [
              config.clan.core.vars.generators.harmonia.files.pub-key.value
            ];
          };
      };
  };
}
