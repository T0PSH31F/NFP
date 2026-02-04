{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper function to check if machine has a tag
  # This uses the clan.tags option defined in tags.nix
  hasTag = tag: builtins.elem tag config.clan.tags;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    # Using the path from the user's prompt, but ensuring it's overrideable if needed
    age.keyFile = lib.mkDefault "/home/t0psh31f/.config/sops/age/keys.txt";

    secrets = lib.mkMerge [
      # Secrets for Binary Cache
      (lib.mkIf (hasTag "binary-cache") {
        "harmonia/signing-key" = {
          path = "/var/lib/harmonia/signing-key";
          owner = "harmonia";
          sopsFile = ../../secrets/harmonia.yaml; # Explicit path to avoid issues if default doesn't match
        };
      })

      # Secrets for Database
      (lib.mkIf (hasTag "database") {
        "postgres/immich_password" = {
          owner = "postgres";
          sopsFile = ../../secrets/postgres.yaml;
        };
        "postgres/openwebui_password" = {
          owner = "postgres";
          sopsFile = ../../secrets/postgres.yaml;
        };
        # "redis/password" = {};
      })
    ];
  };
}
