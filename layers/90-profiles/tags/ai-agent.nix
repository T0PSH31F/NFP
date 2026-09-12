# ai-agent — coding and agent tooling profile
# Does NOT enable LLM inference backends (that's ai-server profile)
# Tags-as-data: all config gated by tag membership.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "ai-agent" config.machine.tags) {
    layers.layer-71.harness = {
      opencode.enable = lib.mkDefault true;
      claude-code.enable = lib.mkDefault true;
      gemini-cli.enable = lib.mkDefault true;
      codegraph.enable = lib.mkDefault true;
      kiro-cli.enable = lib.mkDefault true;
      dsh.enable = lib.mkDefault true;
      herdr.enable = lib.mkDefault true;
      pi-coding-agent.enable = lib.mkDefault true;
      aider-chat.enable = lib.mkDefault true;
    };

    layers.layer-72.voice.voice.enable = lib.mkDefault false;

    layers.layer-75.mcp.enable = lib.mkDefault true;
    layers.layer-75.mcp.gateway.enable = lib.mkDefault true;
    layers.layer-76.hermes.enable = lib.mkDefault true;
    layers.layer-76.hermes.enableDesktop = lib.mkDefault true;
    layers.layer-76.hermes-workspace.enable = lib.mkDefault true;
    layers.layer-76.hermes-dashboard.enable = lib.mkDefault true;
    layers.layer-76.hermes-live-voice.enable = lib.mkDefault true;
    layers.layer-76.open-skills.enable = lib.mkDefault true;

    # LLM Routers
    layers.layer-78.llm-routers.extreme-router.enable = lib.mkDefault true;

    # Orchestration & control plane services
    layers.layer-79.skills.llm-agents-catalog.enable = lib.mkDefault true;
    layers.layer-76.orchestrators.mission-control.enable = lib.mkDefault true;
    layers.layer-76.orchestrators.aionui.enable = lib.mkDefault true;
    layers.layer-76.orchestrators.paperclip.enable = lib.mkDefault true;

    # Memory chassis & gateway services
    layers.layer-73.memory.memory-vault.enable = lib.mkDefault true;
    layers.layer-73.memory.memory-governance.enable = lib.mkDefault true;
    layers.layer-74.ai-infra.agent-sandbox.enable = lib.mkDefault true;

    # Agent productivity & messaging daemons
    layers.layer-79.skills.todo-system.enable = lib.mkDefault true;
    layers.layer-20.services.communication.signal-cli-daemon = {
      enable = lib.mkDefault true;
      port = lib.mkDefault 8080;
    };
    layers.layer-20.services.communication.camofox-browser = {
      enable = lib.mkDefault true;
      port = lib.mkDefault 9377;
      apiKey = config.sops.placeholder.camofox_api_key or "";
    };
  };
}
