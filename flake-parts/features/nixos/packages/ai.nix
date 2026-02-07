{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # AI/ML tools
    ollama

    # Python ML stack (if not using devenv)
    python311Packages.torch
    python311Packages.transformers
    python311Packages.langchain

    # AI assistants/interfaces
    # (note: many are services, not packages)
  ];
}
