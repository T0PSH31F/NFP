# 🧪 Keymap Registry & Root Key Verification Test
{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  actionRegistry = import ../../40-desktop/44-de-frameworks/action-registry.nix { inherit lib; };
  inherit (actionRegistry) rootChords;
  inherit (actionRegistry) groups;

  # 1. Assert Super+Enter is present as which-key-root
  whichKeyRoot = lib.filter (a: a.action == "which-key-root") rootChords;
  hasSuperEnterRoot =
    (builtins.length whichKeyRoot == 1) && ((builtins.head whichKeyRoot).chord == "Super+Enter");

  # 2. Assert no Super+Backslash root exists in neutral registry
  backslashRoots = lib.filter (a: a.chord == "Super+Backslash") rootChords;
  noBackslashRoot = builtins.length backslashRoots == 0;

  # 3. Assert no Noctalia-specific actions leak into neutral action registry
  allGroupActions = lib.concatMap (g: g.actions) (builtins.attrValues groups);
  noctaliaLeakedActions = lib.filter (
    a: a.noctaliaOnly || (lib.hasInfix "noctalia" a.action)
  ) allGroupActions;
  noNoctaliaLeakage = builtins.length noctaliaLeakedActions == 0;

  # 4. Assert all root chords are unique
  chords = map (a: a.chord) rootChords;
  uniqueChords = lib.unique chords;
  allChordsUnique = builtins.length chords == builtins.length uniqueChords;
in
pkgs.runCommand "keymap-registry-check" { } ''
  echo "Checking keymap action registry invariants..."
  ${
    if hasSuperEnterRoot then
      "echo '✓ Super+Enter root verified'"
    else
      "echo '✗ Super+Enter root missing'; exit 1"
  }
  ${
    if noBackslashRoot then
      "echo '✓ No Super+Backslash root in neutral registry'"
    else
      "echo '✗ Super+Backslash root found'; exit 1"
  }
  ${
    if noNoctaliaLeakage then
      "echo '✓ No Noctalia leakage in neutral registry'"
    else
      "echo '✗ Noctalia leakage detected'; exit 1"
  }
  ${
    if allChordsUnique then
      "echo '✓ All root chords unique'"
    else
      "echo '✗ Duplicate root chords detected'; exit 1"
  }
  echo "SUCCESS: Keymap action registry test passed cleanly." > $out
''
