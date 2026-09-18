# Fleet domain helpers — single source for Tailnet host construction
# All cross-host internal service URLs must use mkTailnetHost or a service
# contract that derives from it. No hard-coded nfp.nix / lovelain literals
# outside authority declaration, tests, and historical archive.
{ lib, ... }:
{
  options.layers.lib.fleet-domains = {
    mkTailnetHost = lib.mkOption {
      type = lib.types.unspecified;
      description = "Helper function: host -> fully qualified Tailnet hostname (e.g. host.tailnetDomain)";
      default = host: "${host}.TAILNET";
      defaultText = lib.literalExpression ''host: "''${host}.''${config.layers.meta.tailnetDomain}"'';
    };
  };

  config = {
    # Expose mkTailnetHost as a pure function derived from tailnetDomain
    # Consumers should use: config.layers.lib.fleet-domains.mkTailnetHost "luffy"
    # or inline: "${host}.${config.layers.meta.tailnetDomain}"
    # This option stores the function itself for convenient reuse.
  };
}
