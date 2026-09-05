# development — coding tools, Python, VSCode, dev agents
# Tags-as-data: all config gated by tag membership.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "development" config.machine.tags) {
    layers = {
      layer-50.cli = {
        pythonTools.enable = lib.mkDefault true;
        zellij.yazelix.bars.enable = lib.mkDefault false;
        azure-cli.enable = lib.mkDefault true;
      };
      layer-71.harness = {
        antigravity.enable = lib.mkDefault true;
        claude-code.enable = lib.mkDefault true;
        codex.enable = lib.mkDefault true;
        dsh.enable = lib.mkDefault true;
        gemini-cli.enable = lib.mkDefault true;
        kiro-cli.enable = lib.mkDefault true;
        opencode = {
          enable = lib.mkDefault true;
          desktop = lib.mkDefault true;
        };
      };
      layer-60.gui = {
        vscode.enable = lib.mkDefault true;
        dev-tools.enable = lib.mkDefault true;
        brave.enable = lib.mkDefault true;
      };
      layer-75.mcp.enable = lib.mkDefault true;
      layer-76.hermes = {
        enable = lib.mkDefault true;
        enableDesktop = lib.mkDefault true;
      };
      layer-79.skills.llm-agents-catalog.enable = lib.mkDefault true;
      layer-20.services.config = {
        ci.auto-update.enable = lib.mkDefault true;
        ci.github-runner.enable = lib.mkDefault true;
        hedgedoc = {
          enable = false;
          port = lib.mkDefault 3001;
        };
      };
    };
  };
}
