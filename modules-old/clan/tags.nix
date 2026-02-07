{ lib, config, ... }:

{
  options.clan.tags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Machine role tags for conditional config.
      Example tags:
        # System type:
        - "desktop"
        - "server"
        - "laptop"
        - "vm"

        # Service roles:
        - "ai-server"
        - "ai-heavy"
        - "media-server"
        - "download-server"
        - "build-server"
        - "binary-cache"
        - "database"

        # Hardware:
        - "nvidia"
        - "amd-gpu"

        # Development:
        - "dev"
        - "pentest"

        # Gaming:
        - "gaming"
    '';
  };

  config = {
    lib.clan = {
      hasTag = tag: lib.elem tag config.clan.tags;
      hasTags = tags: lib.all (t: lib.elem t config.clan.tags) tags;
      hasAnyTag = tags: lib.any (t: lib.elem t config.clan.tags) tags;
    };

    # Write tags into /etc/clan/tags for easy inspection
    environment.etc."clan/tags".text = lib.concatStringsSep "\n" config.clan.tags;

    # Also expose tags via system.nixos.tags (useful for tools)
    system.nixos.tags = config.clan.tags;
  };
}
