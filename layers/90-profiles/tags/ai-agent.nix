# ai-agent — coding and agent tooling profile
# Does NOT enable LLM inference backends (that's ai-server profile)
# Tags-as-data: all config gated by tag membership.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "ai-agent" config.machine.tags) {
    layers = {
      layer-20.services.communication = {
        signal-cli-daemon = {
          enable = lib.mkDefault true;
          port = lib.mkDefault 8080;
        };
        camofox-browser = {
          enable = lib.mkDefault (builtins.elem "desktop" config.machine.tags);
          port = lib.mkDefault 9377;
          apiKey = config.sops.placeholder.camofox_api_key or "";
        };
      };

      layer-71.harness = {
        opencode.enable = lib.mkDefault true;
        claude-code.enable = lib.mkDefault true;
        gemini-cli.enable = lib.mkDefault true;
        codegraph.enable = lib.mkDefault true;
        kiro-cli.enable = lib.mkDefault true;
        dsh.enable = lib.mkDefault true;
        crush.enable = lib.mkDefault true;
        herdr.enable = lib.mkDefault true;
        pi-coding-agent.enable = lib.mkDefault true;
        aider-chat.enable = lib.mkDefault true;
        gitlab.enable = lib.mkDefault true;
      };

      layer-72.voice.voice.enable = lib.mkDefault false;

      layer-73.memory = {
        memory-vault.enable = lib.mkDefault true;
        memory-governance.enable = lib.mkDefault true;
      };

      layer-74.ai-infra.agent-sandbox.enable = lib.mkDefault true;

      layer-75.mcp = {
        enable = lib.mkDefault true;
        lxconnect.enable = lib.mkDefault true;
        jev.enable = lib.mkDefault true;
        headroom.enable = lib.mkDefault true;
      };

      layer-76 = {
        hermes = {
          enable = lib.mkDefault true;
          enableDesktop = lib.mkDefault (
            builtins.elem "desktop" config.machine.tags || (config.layers.layer-60.gui.enable or false)
          );
        };
        hermes-workspace.enable = lib.mkDefault true;
        hermes-dashboard.enable = lib.mkDefault true;
        hermes-live-voice.enable = lib.mkDefault true;
        open-skills.enable = lib.mkDefault true;
        orchestrators = {
          executor.enable = lib.mkDefault true;
          mission-control.enable = lib.mkDefault true;
          aionui.enable = lib.mkDefault false; # Disabled: better-sqlite3 build failure against electron 43 headers
          paperclip.enable = lib.mkDefault true;
          polyfloor.enable = lib.mkDefault true;
          hermes-ratchet.enable = lib.mkDefault true;
        };
      };

      # LLM Routers
      layer-78.llm-routers.extreme-router.enable = lib.mkDefault true;

      # Skills
      layer-79.skills = {
        nix-skills.enable = lib.mkDefault true;
        llm-agents-catalog.enable = lib.mkDefault true;
        todo-system.enable = lib.mkDefault true;
      };
    };
  };
}
