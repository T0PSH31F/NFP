# agent-orchestrator — runtime/orchestration for AI agents
# Deployed on always-on machines that host the agent control plane.
# Does NOT run LLM backends (that's ai-router) or vector RAG (that's pkb-node).
{ config, lib, ... }:
{
  config = lib.mkIf (lib.elem "agent-orchestrator" config.machine.tags) {
    layers = {
      # Sandbox for agent code execution
      layer-74.ai-infra.agent-sandbox.enable = lib.mkDefault true;
      # MCP framework
      layer-75.mcp.enable = lib.mkDefault true;
      layer-76 = {
        # Hermes server daemon
        hermes.enable = lib.mkDefault true;
        # Agent control-plane services
        orchestrators = {
          executor.enable = lib.mkDefault true;
          mission-control.enable = lib.mkDefault true;
          paperclip.enable = lib.mkDefault true;
          polyfloor.enable = lib.mkDefault true;
        };
      };
    };
  };
}
