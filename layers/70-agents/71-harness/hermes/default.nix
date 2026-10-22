{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "hermes" ./hermes.nix)
    (mkDendriticModule "hermes-workspace" ./workspace.nix)
    (mkDendriticModule "hermes-dashboard" ./dashboard.nix)
    (mkDendriticModule "hermes-live-voice" ./hermes-live-voice.nix)
    (mkDendriticModule "hermes-evaluator" ./hermes-evaluator.nix)
    (mkDendriticModule "open-skills" ./open-skills.nix)
  ];
}
