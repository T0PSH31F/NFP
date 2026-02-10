# flake-parts/system/clan-lib.nix
{ config, lib, ... }:
{
  options.clan.core.tags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Tags for tag-based configuration";
  };

  options.clan.lib = {
    hasTag = lib.mkOption {
      type = lib.types.functionTo lib.types.bool;
      default = tag: lib.elem tag config.clan.core.tags;
      description = "Helper to check if a machine has a specific tag";
    };

    hasTags = lib.mkOption {
      type = lib.types.functionTo lib.types.bool;
      default = tags: lib.any (tag: lib.elem tag config.clan.core.tags) tags;
      description = "Helper to check if a machine has any of the specific tags";
    };
  };
}
