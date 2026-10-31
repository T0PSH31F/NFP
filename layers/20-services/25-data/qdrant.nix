{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.ai-services.qdrant = {
    enable = mkEnableOption "Qdrant vector database";

    port = mkOption {
      type = types.int;
      default = 6333;
      description = "Qdrant port";
    };
  };

  config =
    let
      cfg = config.services.ai-services.qdrant;
    in
    mkIf cfg.enable {
      services.qdrant = {
        enable = true;
        settings = {
          service = {
            http_port = cfg.port;
            grpc_port = 6334;
          };
          storage = {
            storage_path = "/var/lib/qdrant/storage";
          };
        };
      };

      systemd.services.qdrant.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "qdrant";
        Group = "qdrant";
        StateDirectory = lib.mkForce "qdrant";
        ReadWritePaths = [ "/var/lib/qdrant" ];
      };

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/qdrant";
                user = "qdrant";
                group = "qdrant";
                mode = "0750";
              }
            ];
          };

      users.users.qdrant = {
        isSystemUser = true;
        group = "qdrant";
        description = "Qdrant Vector Database Daemon";
      };
      users.groups.qdrant = { };
    };
}
