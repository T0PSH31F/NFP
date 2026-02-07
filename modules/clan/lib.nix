{ lib, config, ... }:

let
  hasTag = tag: lib.elem tag (config.clan.core.tags or [ ]);
  hasTags = tags: lib.any (tag: lib.elem tag (config.clan.core.tags or [ ])) tags;
  hasAllTags = tags: lib.all (tag: lib.elem tag (config.clan.core.tags or [ ])) tags;
in
{
  options.clan.lib = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Helper functions for tag-based configuration";
  };

  config.clan.lib = {
    inherit hasTag hasTags hasAllTags;
  };
}
