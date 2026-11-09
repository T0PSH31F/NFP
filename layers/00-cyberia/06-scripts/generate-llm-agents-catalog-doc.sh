#!/usr/bin/env bash
# Mechanically generate commented inventory of llmPkgs for llm-agents-catalog.nix
set -euo pipefail

nix eval --impure --json --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.llm-agents.packages.x86_64-linux;
    excluded = [
      "claude-code" "goose-cli" "opencode" "pi" "ccusage"
      "codex" "antigravity-cli" "hermes-agent"
    ];
    unfreeSet = [
      "amp" "grok" "cursor-agent" "droid" "cubic" "coderabbit-cli"
      "copilot-cli" "junie" "qoder-cli" "kilocode-cli" "claude-code"
      "chatgpt" "claude-desktop" "oh-my-opencode" "gitnexus"
    ];
    formatPkg = n: v:
      let
        desc = v.meta.description or "No description available";
        isUnfree = builtins.elem n unfreeSet || (v.meta.unfree or false);
        unfreeStr = if isUnfree then " [UNFREE]" else "";
      in "# ${n}${unfreeStr} — ${desc}";
    filtered = builtins.removeAttrs pkgs excluded;
  in builtins.attrValues (builtins.mapAttrs formatPkg filtered)
' | jq -r '.[]'
