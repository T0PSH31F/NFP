{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.ai-services.chromadb = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable ChromaDB vector database";
    };

    port = mkOption {
      type = types.int;
      default = 8004;
      description = "ChromaDB port";
    };
  };

  config =
    let
      cfg = config.services.ai-services.chromadb;
    in
    mkIf cfg.enable {
      services.chromadb = {
        enable = true;
        inherit (cfg) port;
        openFirewall = true;
      };

      systemd.services.chromadb.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "chromadb";
        Group = "chromadb";
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ "/var/lib/chromadb" ];
      };

      users.users.chromadb = {
        group = "chromadb";
        isSystemUser = true;
        description = "ChromaDB Service User";
        home = "/var/lib/chromadb";
        createHome = true;
      };
      users.groups.chromadb = { };

      fileSystems."/var/lib/chromadb" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            device = "/persist/var/lib/chromadb";
            fsType = "none";
            options = [
              "bind"
              "X-fstrim.notrim"
              "neededForBoot"
            ];
          };
    };
}
