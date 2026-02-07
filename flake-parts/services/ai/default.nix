# flake-parts/services/ai/default.nix
# AI and LLM services
{
  imports = [
    ./ai-services.nix
    ./sillytavern.nix
    ./llm-agents.nix
  ];
}
