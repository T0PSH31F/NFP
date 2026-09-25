# Tier: 75-mcp
# Module: server-catalog.nix
# Purpose: Declarative Model Context Protocol (MCP) server catalog & registry.
# Option Path: layers.layer-75.mcp
# Enabling Host Tags: ai-agent, workstation, desktop
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  serverSubmodule = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable this MCP server entry.";
        };

        transport = mkOption {
          type = types.enum [
            "stdio"
            "streamable-http"
            "sse"
            "openapi"
            "graphql"
          ];
          default = "stdio";
          description = "MCP transport protocol type.";
        };

        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = "Package providing the executable.";
        };

        command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Command string or executable path for stdio transport.";
        };

        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Endpoint URL for HTTP/SSE/OpenAPI/GraphQL transport.";
        };

        args = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Command-line arguments for stdio transport.";
        };

        environmentFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to environment file containing runtime secrets.";
        };

        scope = mkOption {
          type = types.enum [
            "fleet"
            "host"
            "project"
          ];
          default = "host";
          description = "Deployment scope for this server definition.";
        };

        domain = mkOption {
          type = types.str;
          default = "general";
          description = "Functional domain (e.g. nix, git, home-automation, memory).";
        };

        tags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Capability tags.";
        };

        risk = mkOption {
          type = types.enum [
            "read"
            "write"
            "destructive"
            "credentialed"
          ];
          default = "read";
          description = "Risk level classification.";
        };

        approval = mkOption {
          type = types.enum [
            "never"
            "write"
            "always"
          ];
          default = "never";
          description = "User approval requirement class.";
        };

        dataClasses = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Data classifications (e.g. public, internal, sensitive).";
        };

        maxResultBytes = mkOption {
          type = types.int;
          default = 1048576; # 1MB default
          description = "Maximum allowed response size in bytes.";
        };

        cacheTtlSeconds = mkOption {
          type = types.int;
          default = 0;
          description = "Cache TTL in seconds (only applicable for read operations).";
        };

        description = mkOption {
          type = types.str;
          default = "";
          description = "Concise description of the server for discovery.";
        };
      };
    }
  );
in
{
  options.layers.layer-75.mcp = {
    enable = mkEnableOption "MCP server catalog and registry";

    servers = mkOption {
      type = types.attrsOf serverSubmodule;
      default = {
        mcp-nixos = {
          enable = true;
          transport = "stdio";
          package = pkgs.mcp-nixos;
          domain = "nix";
          risk = "read";
          approval = "never";
          maxResultBytes = 1048576;
          cacheTtlSeconds = 300;
          description = "Immutable NixOS package and option query provider";
        };
        github = {
          enable = true;
          transport = "stdio";
          package = pkgs.github-mcp-server;
          domain = "git";
          risk = "read";
          approval = "never";
          maxResultBytes = 1048576;
          cacheTtlSeconds = 60;
          description = "GitHub API MCP tool suite";
        };
        ha-mcp = {
          enable = true;
          transport = "stdio";
          package = pkgs.ha-mcp;
          domain = "home-automation";
          risk = "read";
          approval = "never";
          maxResultBytes = 1048576;
          cacheTtlSeconds = 0;
          description = "Home Assistant MCP tool suite";
        };
        headroom = {
          enable = true;
          transport = "stdio";
          package = pkgs.headroom-ai;
          command = "${lib.getExe pkgs.headroom-ai}";
          args = [
            "mcp"
            "serve"
          ];
          domain = "context";
          risk = "read";
          approval = "never";
          maxResultBytes = 524288;
          cacheTtlSeconds = 0;
          description = "Headroom Context Token Compression Engine";
        };
      };
      description = "Declarative registry of typed MCP server definitions.";
    };

    clientConfigs = mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
      description = "Normalized client connection records generated from enabled server definitions.";
    };
  };

  config =
    let
      cfg = config.layers.layer-75.mcp;
      user = config.layers.meta.primaryUser or "t0psh31f";

      enabledServers = filterAttrs (_n: s: s.enable) cfg.servers;

      toClientConfig =
        s:
        (
          if s.transport == "stdio" then
            {
              command = if s.command != null then s.command else lib.getExe s.package;
              inherit (s) args;
            }
          else
            {
              inherit (s) url;
            }
        )
        // {
          inherit (s) maxResultBytes cacheTtlSeconds;
        };

      clientConfigs = mapAttrs (_n: toClientConfig) enabledServers;
    in
    mkIf cfg.enable {
      layers.layer-75.mcp.clientConfigs = clientConfigs;

      environment.systemPackages = with pkgs; [
        mcp-nixos
        ha-mcp
        github-mcp-server
        perplexity-mcp
        thunderbird-mcp
        mcporter
        headroom-ai
      ];

      home-manager.users.${user} = {
        xdg.configFile."mcp/config.json".text = builtins.toJSON {
          mcpServers = clientConfigs;
        };
      };

      assertions =
        mapAttrsToList (
          name: s:
          if s.enable then
            {
              assertion =
                if s.transport == "stdio" then
                  (s.command != null || s.package != null) && s.url == null
                else
                  s.url != null && s.command == null && s.package == null;
              message = "MCP server '${name}': stdio transport requires command or package and forbids url; HTTP/SSE/OpenAPI/GraphQL requires url and forbids command/package.";
            }
          else
            {
              assertion = true;
              message = "";
            }
        ) enabledServers
        ++ mapAttrsToList (
          name: s:
          if s.enable then
            {
              assertion = !(s.risk == "destructive" && s.approval == "never");
              message = "MCP server '${name}': destructive operations must require approval ('write' or 'always'), not 'never'.";
            }
          else
            {
              assertion = true;
              message = "";
            }
        ) enabledServers
        ++ mapAttrsToList (
          name: s:
          if s.enable && s.transport != "stdio" && s.url != null then
            {
              assertion =
                builtins.match ".*192\\.168\\..*" s.url == null && builtins.match ".*47\\.254\\..*" s.url == null;
              message = "MCP server '${name}': enabled remote endpoints must use Tailnet DNS (*.nfp.nix) or 127.0.0.1, not raw fleet IPs.";
            }
          else
            {
              assertion = true;
              message = "";
            }
        ) enabledServers
        ++ mapAttrsToList (
          name: s:
          if s.enable then
            {
              assertion = s.maxResultBytes > 0 && s.maxResultBytes <= 10485760;
              message = "MCP server '${name}': maxResultBytes must be > 0 and <= 10MB (10485760 bytes).";
            }
          else
            {
              assertion = true;
              message = "";
            }
        ) enabledServers;
    };
}
