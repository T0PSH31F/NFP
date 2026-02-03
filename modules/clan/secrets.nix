{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasRole = role: builtins.elem role config.clan.core.facts.services.roles;
in
{
  # SOPS configuration
  sops = {
    defaultSopsFile = ../../secrets/postgres.yaml;
    age.keyFile = lib.mkDefault "/home/t0psh31f/.config/sops/age/keys.txt";

    # Secrets only loaded on machines that need them
    secrets = lib.mkMerge [
      # Database secrets (z0r0)
      (lib.mkIf (hasRole "database") {
        "postgres/immich_password" = {
          owner = "postgres";
          mode = "0400";
        };
        "postgres/openwebui_password" = {
          owner = "postgres";
          mode = "0400";
        };
      })

      # Binary cache secrets (z0r0)
      (lib.mkIf (hasRole "binary-cache") {
        "harmonia/signing-key" = {
          sopsFile = ../../secrets/harmonia.yaml;
          owner = "harmonia";
          mode = "0400";
        };
      })
    ];
  };
}
