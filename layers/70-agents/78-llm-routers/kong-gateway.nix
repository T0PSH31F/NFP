# Tier: 78-llm-routers
# Module: kong-gateway.nix
# Purpose: Tombstone module — Kong Gateway is decommissioned and permanently removed.
{ lib, ... }:
{
  options.services.ai-services.kong-gateway = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "DEPRECATED: Kong Gateway has been removed. All clients route directly to ExtremeRouter (:20128) or Jev (:20127).";
    };
    proxyPort = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Deprecated Kong proxy port";
    };
    adminPort = lib.mkOption {
      type = lib.types.port;
      default = 8091;
      description = "Deprecated Kong admin port";
    };
  };

  config = {
    services.ai-services.kong-gateway.enable = lib.mkForce false;
  };
}
