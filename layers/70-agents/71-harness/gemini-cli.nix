# Tier: 71-harness
# Module: gemini-cli.nix
# Purpose: Google Gemini CLI harness for command line generation.
# Provider endpoints (Kong path multiplexer + ExtremeRouter backup):
#   kong-er:       http://luffy:8090/v1 (ExtremeRouter)
#   kong-omni:     http://luffy:8090/omni/v1 (OmniRoute)
#   kong-free:     http://luffy:8090/llm/free/v1 (FreeLLMPool)
#   kong-frontier: http://luffy:8090/llm/frontier/v1 (Manifest)
#   extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
# Option Path: layers.layer-70.agent.gemini-cli
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "gemini-cli" ]
      [ "layers" "layer-71" "harness" "gemini-cli" ]
    )
  ];

  options.layers.layer-71.harness.gemini-cli = {
    enable = lib.mkEnableOption "Gemini CLI agent (alias for Antigravity)";
  };

  nixos =
    let
      cfg = config.layers.layer-71.harness.gemini-cli;
    in
    lib.mkIf cfg.enable {
      # gemini-cli was removed from nixpkgs (replaced by Antigravity CLI).
      # Antigravity is the supported successor — enable it instead.
      layers.layer-71.harness.antigravity.enable = true;
    };

  home =
    let
      cfg = config.layers.layer-71.harness.gemini-cli;
    in
    lib.mkIf cfg.enable {
      xdg.configFile."gemini/mcp_config.json".text = builtins.toJSON {
        mcpServers = {
          mcp-nixos = {
            command = "${lib.getExe pkgs.mcp-nixos}";
            args = [ ];
          };
        };
      };

      xdg.configFile."gemini/config.json".text = builtins.toJSON {
        contextFiles = [
          "AGENTS.md"
          "GEMINI.md"
        ];
      };
    };
}
