# Tier: 60-gui-programs
# Module: 68-communication/beeper.nix
# Purpose: Beeper Universal Chat Client & Agent MCP Integration (WhatsApp, Signal, Telegram, Discord, Google Messages, Voice, LinkedIn)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.communication.beeper;
  commEnabled = config.layers.layer-60.gui.communication.enable;
  user = config.layers.meta.primaryUser or "t0psh31f";
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-60" "gui" "beeper" ]
      [ "layers" "layer-60" "gui" "communication" "beeper" ]
    )
  ];

  options.layers.layer-60.gui.communication.beeper = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Beeper universal chat client and bridge manager.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.beeper;
      description = "The Beeper Desktop package to install.";
    };

    bridgeManagerPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.beeper-bridge-manager;
      description = "The Beeper Bridge Manager CLI package (bbctl).";
    };

    enableMcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Beeper Desktop MCP server integration for AI agents (Claude, Antigravity, OpenCode, Hermes).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 23373;
      description = "Beeper Desktop local API & MCP port (default: 23373).";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start Beeper in the background on graphical desktop login.";
    };
  };

  config = lib.mkIf (commEnabled && cfg.enable) {
    # System CLI packages
    environment.systemPackages = [
      cfg.bridgeManagerPackage
    ];

    # Desktop user packages
    home-manager.users.${user} = {
      home.packages = [
        cfg.package
      ];
    };

    # Autostart service in graphical session if requested
    systemd.user.services.beeper = lib.mkIf cfg.autostart {
      description = "Beeper Desktop Universal Chat Client";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/beeper --hidden";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Wire up MCP Server entry in declarative registry
    layers.layer-75.mcp.servers.beeper = lib.mkIf cfg.enableMcp {
      enable = true;
      transport = "streamable-http";
      url = "http://127.0.0.1:${toString cfg.port}/v0/mcp";
      domain = "communication";
      risk = "write";
      approval = "write";
      maxResultBytes = 1048576;
      cacheTtlSeconds = 0;
      description = "Beeper Desktop universal chat MCP tool suite (WhatsApp, Signal, Telegram, Discord, Google Messages, Voice, LinkedIn)";
    };
  };
}
