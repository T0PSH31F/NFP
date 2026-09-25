# Tier: 79-skills
# Module: llm-agents-catalog.nix
# Purpose: Declarative catalog of available agent skills, prompt templates, and tool manifests.
# Option Path: layers.layer-79.skills.llm-agents-catalog
# Enabling Host Tags: ai-agent, development
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  sys = pkgs.stdenv.hostPlatform.system;
  llmPkgs = inputs.llm-agents.packages.${sys} or { };

  # Categorized catalog of LLM agent packages from numtide/llm-agents.nix & nixpkgs
  catalogCategories = {
    harnessesAndAgents = [
      "bb-app"
      "freebuff"
      "jcode"
      "jules"
      "kilocode-cli" # — The open-source AI coding agent. Now available in your terminal.
      "kimi-code" # - The Starting Point for Next-Gen Agents
      "letta-code"
      "localgpt"
      "mistral-vibe"
      #"nanocoder"
      #"mimo-code"
      #"omp"
      #"openclaw"
      "opencode2"
      "openfang"
      "picoclaw"
      "prime-agent"
      "qoder-cli"
      #"qwen-code"
      #"reasonix"
      #"vix"
      #"zaly"
      #"zcode"
      #"zeroclaw"
    ];

    orchestratorsAndSwarms = [
      #"aionui"
      "agent-deck"
      "agentdesk"
      "gascity"
      "gastown"
      "gnhf"
      "herdr"
      #"kandev"
      "luvus"
      #"oh-my-claudecode"
      #"oh-my-codex"
      #"oh-my-opencode"
      "openhands-agent-canvas"
      "orca"
      #"paperclip"
      #"vibe-kanban"
    ];

    codeReviewAndInspection = [
      "ast-grep"
      "code-review-graph"
      "diffnav"
      "fastedit"
      "hunk"
      "jscpd"
      "open-code-review"
      "plannotator"
      "showboat"
      "tuicr"
      "zat"
    ];

    contextAndKnowledge = [
      "openskills"
      "openspec"
      "openspec-ui"
      "qmd"
      "rtk"
      "skills"
      "skills-installer"
      "semble"
      "spec-kit"
      "toon"
    ];

    toolsAndUtilities = [
      "agent-browser"
      "agentburn"
      "annot"
      "aven"
      "ax" # Agent Executor — lightweight runner for AI task execution
      "browser-use"
      "chatterbox" # Open-source voice assistant and TTS engine for AI agents
      "collie"
      "cpa-usage-keeper"
      "executor" # - lightweight runner for AI task execution
      "file-organizer-2000"
      "format-junkie"
      "greptile"
      "handy"
      "mcptoon"
      "parallel-cli"
      "pdfvision"
      "sub2api"
      "trellis"
    ];

    guiApps = [
      "agentdesk"
      #"antigravity-ide"
      #"claude-desktop"
      #hermes-desktop"
      "hermes-hud"
      "hermes-one"
      "multica-desktop"
      "kandev-desktop"
      "paseo-desktop"
      "voxtype"
    ];
  };

  defaultCatalogPackages = concatLists (attrValues catalogCategories);
in
{
  options.layers.layer-79.skills.llm-agents-catalog = {
    enable = mkEnableOption "llm-agents catalog packages and tools";

    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of package names from llm-agents.nix catalog to install into system packages.

        # Catalog Inventory (Mechanically Generated):
        # agent-browser — CLI browser automation tool for AI coding agents
        # agentburn — Local profiler for AI agent spend
        # agentdesk — Desktop control plane for local AI coding agents
        # agentless — Autonomous AI agent for software engineering
        # aionui — Free, open-source Cowork app with AI Agents
        # amp [UNFREE] — Sourcegraph Amp, AI coding assistant CLI
        # antigravity — Advanced Agentic Coding CLI by Google DeepMind
        # ast-grep — Fast and polyglot tool for code searching, linting, and rewriting
        # aux — Terminal UI workspace for managing parallel AI coding agents
        # aven — Minimal, token-optimized coding agent for long-running workflows
        # ax — Agent Executor — lightweight runner for AI task execution
        # beads — Git-backed issue tracker designed for AI coding workflows
        # browser-use — Open-source web automation library for AI agents
        # chatgpt [UNFREE] — Official ChatGPT Desktop app for Linux
        # chatgpt-cli — Command-line interface for ChatGPT with session management
        # chatterbox — Open-source voice assistant and TTS engine for AI agents
        # claude-code [UNFREE] — Official Anthropic Claude Code agent CLI
        # claude-desktop [UNFREE] — Unofficial Claude Desktop Linux port
        # coderabbit-cli [UNFREE] — CodeRabbit AI code review CLI
        # codex — OpenAI Codex CLI for autonomous software development
        # codex-cli — Command-line interface for OpenAI Codex
        # collie — Lightweight agent supervisor and process watcher
        # context-hub — Local context and prompt management server for AI coding agents
        # copilot-cli [UNFREE] — GitHub Copilot CLI tool
        # cubic [UNFREE] — Cubic AI coding agent CLI
        # diff-pdf — Tool for visually comparing two PDF files
        # diffnav — Interactive terminal diff pager for AI agent code reviews
        # dls — Deep seek CLI for terminal code search
        # droid [UNFREE] — Factory Droid CLI — AI coding agent for complex codebases
        # dsh — Open-source agent harness developed by DeepSeek AI
        # fastedit — Token-efficient CLI tool for applying code diffs
        # file-organizer-2000 — AI-powered file organization and indexing CLI
        # format-junky — Media converter tool for audio/video assets
        # formatter — One CLI to format the code tree
        # freebuff — The world's strongest free coding agent
        # fx — Tiny, open, embeddable, native coding agent
        # gascity — Orchestration-builder SDK for multi-agent coding workflows
        # gastown — Gas Town - multi-agent workspace manager
        # git-ai — Git extension for tracking AI-generated code in repositories
        # git-surgeon — Git primitives for autonomous coding agents
        # gitbutler — Git client for simultaneous branches on top of your existing workflow
        # gitclaw — Universal git-native multimodal AI agent (formerly gitagent)
        # gitnexus [UNFREE] — Graph-powered code intelligence for AI agents
        # gnhf — Ralph/autoresearch-style orchestrator that keeps coding agents running while you sleep
        # gno — Local-first knowledge engine with hybrid search, RAG Q&A, and MCP server integration
        # go-bin — Latest Go toolchain (prebuilt binary) for building packages that need a newer patch release than nixpkgs ships
        # grok [UNFREE] — Grok Build, xAI's agentic coding tool
        # handy — Fast and accurate local transcription app using AI models
        # happy-coder — Mobile and Web client for Codex and Claude Code, with realtime voice and encryption
        # herdr — Terminal workspace manager for AI coding agents
        # hermes-desktop — Official native Electron desktop shell for Hermes Agent
        # hermes-hud — TUI consciousness monitor for Hermes Agent
        # hermes-one — Hermes One, community desktop companion for Hermes Agent
        # hunk — Terminal diff viewer for agentic changesets
        # icm — Persistent memory for AI agents with hybrid search, temporal decay, and multilingual embeddings
        # ironclaw — Secure personal AI assistant that protects your data and expands its capabilities on the fly
        # jscpd — Copy/paste detector for programming source code
        # junie [UNFREE] — Junie, JetBrains AI coding agent CLI
        # kandev — Manage tasks, orchestrate agents, review changes, and ship value
        # kandev-desktop — Native desktop application for the Kandev agentic development platform
        # kilocode-cli [UNFREE] — The open-source AI coding agent. Now available in your terminal.
        # kimi-code — The Starting Point for Next-Gen Agents
        # lean-ctx — Context OS for AI development — compression, memory, and routing for LLM context
        # letta-code — Memory-first coding agent that learns and evolves across sessions
        # localgpt — Local AI assistant with persistent markdown memory, autonomous tasks, and semantic search
        # luvus — Mission control for your AI coding agents
        # mardi-gras — Terminal UI for Beads issue tracking with a parade-inspired workflow view
        # mcporter — TypeScript runtime and CLI for the Model Context Protocol
        # mcptoon — Token-efficient MCP CLI client that converts tool discovery and results to compact TOON output
        # memvid-cli — AI memory CLI - crash-safe, single-file storage with semantic search
        # mimo-code — Open-source AI coding agent with cross-session memory
        # mindwalk — Visualization tool that replays coding-agent sessions on a 3D map of your codebase
        # mistral-vibe — Minimal CLI coding agent by Mistral AI - open-source command-line coding assistant powered by Devstral
        # nanocoder — A beautiful local-first coding agent running in your terminal - built by the community for the community ⚒
        # nono — Kernel-enforced agent sandbox. Capability-based isolation with secure key management, atomic rollback, cryptographic immutable audit chain of provenance.
        # officecli — CLI for creating and editing Office Open XML documents
        # oh-my-claudecode — Multi-agent orchestration system for Claude Code
        # oh-my-codex — Multi-agent orchestration layer for OpenAI Codex CLI
        # oh-my-opencode [UNFREE] — The Best AI Agent Harness - Multi-Model Orchestration for OpenCode
        # omp — A terminal-based coding agent with multi-model support
        # open-code-review — AI-powered code review CLI
        # openclaw — Your own personal AI assistant. Any OS. Any Platform. The lobster way
        # opencode2 — OpenCode 2 preview CLI
        # openfang — Open-source Agent OS built in Rust — CLI for the OpenFang platform
        # openskills — Universal skills loader for AI coding agents - install and load Anthropic SKILL.md format skills in any agent
        # openspec — Spec-driven development for AI coding assistants
        # openspecui — Visual interface for spec-driven development
        # orca — ADE for working with a fleet of parallel coding agents
        # paperclip — Open-source control plane for managing teams of AI agents
        # parallel-cli — AI-powered web search, extraction, and research CLI from Parallel
        # paseo-desktop — Voice-controlled desktop development environment for AI coding agents
        # pdfvision — Extract text, metadata, and page images from PDF files, designed for AI agents
        # picoclaw — Tiny, fast, and deployable anywhere — automate the mundane, unleash your creativity
        # plannotator — Interactive plan and code review tool for AI coding agents
        # prime-agent — A self-improving RLM agent for coding workflows and long-running autonomous tasks.
        # qmd — mini cli search engine for your docs, knowledge bases, meeting notes, whatever. Tracking current sota approaches while being all local
        # qoder-cli [UNFREE] — Qoder AI CLI tool - Terminal-based AI assistant for code development
        # qoder-cli-cn — Qoder CLI (mainland China edition) - terminal-based AI coding assistant for China-region accounts
        # qwen-code — Command-line AI workflow tool for Qwen3-Coder models
        # ralph-tui — AI Agent Loop Orchestrator TUI
        # reasonix — DeepSeek-native AI coding agent for your terminal
        # rtk — CLI proxy that reduces LLM token consumption by 60-90% on common dev commands
        # sandbox-runtime — Lightweight sandboxing tool for enforcing filesystem and network restrictions
        # semble — Fast and accurate local code search for AI agents — CLI and MCP server
        # showboat — Create executable demo documents showing and proving an agent's work
        # sidecar — Terminal-based development companion for AI coding agents
        # skills — The open agent skills tool for installing and managing skills across AI coding agents
        # skills-installer — Install agent skills across multiple AI coding clients
        # spec-kit — Specify CLI, part of GitHub Spec Kit. A tool to bootstrap your projects for Spec-Driven Development (SDD)
        # swamp — Deterministic automation for AI agents
        # t3code — Control surface for coding agents
        # t3code-desktop — Desktop control surface for coding agents
        # td — A minimalist CLI for tracking tasks across AI coding sessions.
        # terminal-use — Headless virtual terminal for AI agents
        # toon — Rust implementation of TOON - Token-Oriented Object Notation for LLM prompts
        # trellis — An out-of-the-box engineering framework for AI coding.
        # tuicr — Review AI-generated diffs like a GitHub pull request, right from your terminal
        # vessel-browser — Agent-oriented browser with durable state and MCP control
        # vibe-kanban — Kanban board to orchestrate AI coding agents like Claude Code, Codex, and Gemini CLI
        # vix — Sleek, Fast and Token Efficient AI Coding Agent
        # voxterm — Local real-time voice transcription TUI with speaker diarization
        # voxtype — Push-to-talk voice-to-text for Wayland
        # workmux — Git worktrees + tmux windows for zero-friction parallel dev
        # zaly — Hackable terminal coding agent
        # zat — Code outline viewer for LLM coding agents — shows exported symbols with line numbers
        # zcode — Agentic development environment (ADE) by Z.ai
        # zeroclaw — Fast, small, and fully autonomous AI assistant infrastructure
      '';
    };
  };

  config =
    let
      cfg = config.layers.layer-79.skills.llm-agents-catalog;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";
      hasTag = tag: builtins.elem tag (config.machine.tags or [ ]);

      guiCatalogPackages = [
        "agentdesk"
        "antigravity-ide"
        "chatgpt"
        "claude-desktop"
        "hermes-desktop"
        "hermes-hud"
        "kandev-desktop"
        "paseo-desktop"
        "voxtype"
      ];

      isGuiHost = hasTag "desktop" || (config.layers.layer-60.gui.enable or false);

      effectivePackageNames =
        let
          rawNames =
            if cfg.packages != [ ] then
              cfg.packages
            else if (hasTag "ai-agent" || hasTag "ai-server" || hasTag "development") then
              defaultCatalogPackages
            else
              [ ];
        in
        if isGuiHost then rawNames else filter (name: !(elem name guiCatalogPackages)) rawNames;

      resolvedPackages = filter (p: p != null) (
        (map (name: llmPkgs.${name} or pkgs.${name} or null) effectivePackageNames)
        ++ [ (inputs.hister.packages.${sys}.default or inputs.hister.defaultPackage.${sys} or null) ]
      );

      voxtypeEnabled = elem "voxtype" effectivePackageNames && cfg.enable;
    in
    mkIf cfg.enable {
      environment.systemPackages = resolvedPackages;

      environment.persistence."/persist" =
        mkIf (voxtypeEnabled && (config.layers.layer-10.system.config.impermanence.enable or false))
          {
            users.${primaryUser}.directories = [
              ".config/voxtype"
              ".local/share/voxtype"
            ];
          };
    };
}
