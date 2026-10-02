# Tier: 75-mcp
# Module: lxconnect.nix
# Purpose: Android to Linux Desktop Bridge with MCP server integration.
# Option Path: layers.layer-75.mcp.lxconnect
# Enabling Host Tags: workstation, desktop, ai-agent
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.layer-75.mcp.lxconnect;
  lxconnectPkg = inputs.lxconnect.packages.${pkgs.system}.default or null;
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-10" "system" "mobile" "lxconnect" ]
      [ "layers" "layer-75" "mcp" "lxconnect" ]
    )
    (lib.mkAliasOptionModule [ "services" "lxconnect" ] [ "layers" "layer-75" "mcp" "lxconnect" ])
  ];

  options.layers.layer-75.mcp.lxconnect = {
    enable = lib.mkEnableOption "lxconnect — Android to Linux Desktop Bridge with MCP server integration";

    package = lib.mkOption {
      type = lib.types.package;
      default = lxconnectPkg;
      description = "lxconnect package from flake input";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to start the lxconnect daemon automatically in the user graphical session.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user.services.lxconnect = lib.mkIf cfg.autostart {
      description = "lxconnect Android bridge daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/lxconnect";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
