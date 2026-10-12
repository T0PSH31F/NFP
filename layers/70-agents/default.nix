# Agents Tier Entry Point — imports agent sub-tiers
{ ... }:
{
  imports = [
    ./71-harness
    ./72-voice
    ./73-memory
    ./74-ai-infra
    ./75-mcp
    ./76-orchestrators
    ./77-dash-desk-ui
    ./78-llm-routers
    ./79-skills
    ./jev
  ];
}
