{
  inputs,
  config,
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
    environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      # AI Coding Agents
      amp # - CLI for Amp, an agentic coding tool in research preview from Sourcegraph
      claude-code # - Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
      # code # - Fork of codex. Orchestrate agents from OpenAI, Claude, Gemini or any provider.
      # codex # - OpenAI Codex CLI - a coding agent that runs locally on your computer
      # copilot-cli # - GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal.
      crush # - The glamourous AI coding agent for your favourite terminal
      # cursor-agent # - Cursor Agent - CLI tool for Cursor AI code editor
      # droid # - Factory AI's Droid - AI-powered development agent for your terminal
      # eca # - Editor Code Assistant (ECA) - AI pair programming capabilities agnostic of editor
      # forge # - AI-Enhanced Terminal Development Environment - A comprehensive coding agent that integrates AI capabilities with your development environment
      # gemini-cli # - AI agent that brings the power of Gemini directly into your terminal
      goose-cli # - CLI for Goose - a local, extensible, open source AI agent that automates engineering tasks
      # jules # - Jules, the asynchronous coding agent from Google, in the terminal
      # kilocode-cli # - The open-source AI coding agent. Now available in your terminal.
      # letta-code # - Memory-first coding agent that learns and evolves across sessions
      mistral-vibe # - Minimal CLI coding agent by Mistral AI - open-source command-line coding assistant powered by Devstral
      nanocoder # - A beautiful local-first coding agent running in your terminal - built by the community for the community ⚒
      opencode # - AI coding agent built for the terminal
      # pi # - A terminal-based coding agent with multi-model support
      # qoder-cli # - Qoder AI CLI tool - Terminal-based AI assistant for code development
      qwen-code # - Command-line AI workflow tool for Qwen3-Coder models

      # Claude Code Ecosystem
      catnip # - Developer environment that's like catnip for agentic programming
      ccstatusline # - A highly customizable status line formatter for Claude Code CLI
      claude-code-router # - Use Claude Code without an Anthropics account and route it to another LLM provider
      claude-plugins # - CLI tool for managing Claude Code plugins
      claudebox # - Sandboxed environment for Claude Code
      # sandbox-runtime # - Lightweight sandboxing tool for enforcing filesystem and network restrictions
      # skills-installer # - Install agent skills across multiple AI coding clients

      # ACP Ecosystem
      claude-code-acp # - An ACP-compatible coding agent powered by the Claude Code SDK (TypeScript)
      # codex-acp # - An ACP-compatible coding agent powered by Codex

      # Usage Analytics
      ccusage # - Usage analysis tool for Claude Code
      ccusage-amp # - Usage analysis tool for Amp CLI sessions
      # ccusage-codex # - Usage analysis tool for OpenAI Codex sessions
      ccusage-opencode # - Usage analysis tool for OpenCode sessions
      # ccusage-pi # - Pi-agent usage tracking for Claude Max

      # Workflow & Project Management
      # backlog-md # - Backlog.md - A tool for managing project collaboration between humans and AI Agents in a git ecosystem
      # beads # - A distributed issue tracker designed for AI-supervised coding workflows
      cc-sdd # - Spec-driven development framework for AI coding agents
      # chainlink # - Simple, lean issue tracker CLI designed for AI-assisted development
      openspec # - Spec-driven development for AI coding assistants
      spec-kit # - Specify CLI, part of GitHub Spec Kit. A tool to bootstrap your projects for Spec-Driven Development (SDD)
      # vibe-kanban # - Kanban board to orchestrate AI coding agents like Claude Code, Codex, and Gemini CLI
      # workmux # - Git worktrees + tmux windows for zero-friction parallel dev

      # Code Review
      # coderabbit-cli # - AI-powered code review CLI tool
      # tuicr # - Review AI-generated diffs like a GitHub pull request, right from your terminal

      # Utilities
      # agent-browser # - Headless browser automation CLI for AI agents
      # ck # - Local first semantic and hybrid BM25 grep / search tool for use by AI and humans!
      # clawdbot # - Personal AI assistant with WhatsApp, Telegram, Discord integration
      # coding-agent-search # - Unified, high-performance TUI to index and search your local coding agent history
      # copilot-language-server # - GitHub Copilot Language Server - AI pair programmer LSP
      # handy # - Fast and accurate local transcription app using AI models
      # happy-coder # - Happy Coder CLI to connect your local Claude Code to mobile device
      openskills # - Universal skills loader for AI coding agents - install and load Anthropic SKILL.md format skills in any agent
      # qmd # - mini cli search engine for your docs, knowledge bases, meeting notes, whatever. Tracking current sota approaches while being all local

    ];

    # services.local-ai.enable = true;

  };
}
