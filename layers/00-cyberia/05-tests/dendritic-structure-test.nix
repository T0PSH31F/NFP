# Dendritic Structure, Guardrails, & Tag Profile Verification Test
{ pkgs, lib }:
let
  validTags = [
    "agent-orchestrator"
    "ai-agent"
    "ai-inference"
    "ai-router"
    "ai-server"
    "ai-ui"
    "cache-server"
    "desktop"
    "development"
    "gaming"
    "gpu-compute"
    "homelab"
    "intel-12th-gen"
    "intel-13th-gen"
    "intel-9th-gen"
    "laptop"
    "media"
    "network-router"
    "pkb-node"
    "server"
    "workstation"
  ];

  tagFiles = builtins.attrNames (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
      builtins.readDir ../../90-profiles/tags
    )
  );

  expectedTagFiles = map (t: "${t}.nix") validTags ++ [ "default.nix" ];
  missingFromRegistry = lib.filter (f: !(lib.elem f expectedTagFiles)) tagFiles;
in
if missingFromRegistry != [ ] then
  throw "Tag files exist without being in validTags registry: ${lib.concatStringsSep ", " missingFromRegistry}"
else
  pkgs.runCommand "check-dendritic-structure"
    {
      nativeBuildInputs = [ pkgs.gnugrep ];
    }
    ''
      set -e

      # 1. Zero relative helper imports in layers/
      if grep -rn "import \.\./" ${../../.}/layers/ >/dev/null 2>&1; then
        echo "ERROR: Relative helper imports found in layers/"
        exit 1
      fi

      # 2. Zero mkForce under layers/90-profiles/
      if grep -rn "mkForce" ${../../.}/layers/90-profiles/ >/dev/null 2>&1; then
        echo "ERROR: lib.mkForce found under layers/90-profiles/"
        exit 1
      fi

      # 3. Hyprland base contains zero "noctalia" strings
      if grep -ri "noctalia" ${../../.}/layers/40-desktop/41-hyprland/ >/dev/null 2>&1; then
        echo "ERROR: noctalia reference found in neutral Hyprland base (layers/40-desktop/41-hyprland/)"
        exit 1
      fi

      # 5. Check for orphaned layers.layer-* option paths in machines and tags
      echo "Checking for orphaned layers.layer-* setting paths..."
      for opt in $(grep -oE "layers\.layer-[0-9]+\.[a-zA-Z0-9._-]+" -r ${../../.}/machines/ ${../../.}/layers/90-profiles/tags/ | cut -d: -f2 | cut -d'=' -f1 | tr -d ' ' | sort -u); do
        base_opt=$(echo "$opt" | sed 's/\.enable$//')
        if ! grep -rn "$base_opt" ${../../.}/layers/ >/dev/null 2>&1; then
          echo "ERROR: Orphaned setting path found: $opt (not declared anywhere in layers/)"
          exit 1
        fi
      done

      echo "Dendritic structure & guardrail checks passed successfully." > $out
    ''
