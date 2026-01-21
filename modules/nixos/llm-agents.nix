{ pkgs, lib, inputs, ... }:
{

environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
   
    opencode
    nanocoder
    gemini-cli
    crush
    droid
    letta-code
    pi

  # Open AI Spec
    agent-browser
    openskills
    openspec

   # Claude Ecosystem
    claude-code
    clawdbot
    catnip
    ccstatusline
    claude-code-npm
    claude-code-router
    claude-plugins
   
  ];
}
