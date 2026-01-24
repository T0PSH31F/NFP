{
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.llm-agents;
in
{
  options.services.llm-agents = {
    enable = mkEnableOption "Agentic AI-related services";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Frameworks
      crewai # Framework for orchestrating autonomous AI agents
      droid # AI agent framework
      fabric-ai # AI-powered workflow framework
      go-hass-agent # Home Assistant agent in Go
      letta-code # Framework for stateful LLM agents (formerly MemGPT)
      task-master-ai # Task automation agent

      # Inference
      gpt4all # Run LLMs locally on consumer hardware
      lmstudio # GUI for running local LLMs
      jan
      local-ai # OpenAI-compatible API for local models
      qdrant # Vector database for AI applications
      ramalama # Tool for managing AI models

      # Interfaces
      bluemail # Email client with AI integration
      cherry-studio # Desktop LLM client
      librechat # Open-source AI chat interface
      nextjs-ollama-llm-ui # Web UI for Ollama
      pi # Personal AI assistant interface
      sillytavern # Advanced LLM interface for roleplay
      # windsurf # Agentic IDE

      # CLI & TUI
      aider-chat-full # CLI for AI pair programming
      crush # AI-powered command-line tool
      gemini-cli # Google Gemini CLI
      krillinai # AI agent tool
      nanocoder # Small footprint AI coding assistant
      opencode # AI-powered coding tool

      # TTS & STT
      moshi # Real-time conversational AI
      piper-tts # Local neural text-to-speech engine
      whisper-ctranslate2 # High-performance speech-to-text

      # Open AI Spec
      agent-browser # Browser automation for AI agents
      openskills # Open specification for AI skills
      openspec # Open AI specification tools

      # Claude Ecosystem
      claude-code # Anthropic's CLI for AI-assisted coding
      clawdbot # Claude-powered bot
      catnip # Claude ecosystem enhancement
      ccstatusline # Status line for Claude Code
      claude-code-npm # Claude Code NPM package
      claude-code-router # Routing for Claude Code
      claude-plugins # Plugins for Claude assistants

    ];
  };
}
