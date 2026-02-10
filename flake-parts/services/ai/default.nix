# flake-parts/services/ai/default.nix
# AI and LLM services
{
  imports = [
    ./ai-services.nix
    ./llm-agents.nix
    ./n8n.nix
    ./sillytavern.nix
  ];
}
