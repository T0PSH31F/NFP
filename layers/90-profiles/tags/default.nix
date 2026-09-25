# Tag Profile Registry — Tags as Pure Data
{
  config,
  lib,
  mkDendriticModule,
  mkDendriticTree,
  ...
}:
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
    "intel-9th-gen"
    "laptop"
    "media"
    "network-router"
    "pkb-node"
    "server"
    "workstation"
  ];
in
{
  imports = mkDendriticTree mkDendriticModule ./.;

  config =
    let
      machineTags = config.machine.tags or [ ];
      invalidTags = builtins.filter (tag: !(builtins.elem tag validTags)) machineTags;
    in
    {
      assertions = [
        {
          assertion = invalidTags == [ ];
          message = "Invalid machine tag(s): ${builtins.concatStringsSep ", " invalidTags}. Valid tags: ${builtins.concatStringsSep ", " validTags}";
        }
      ];
    };
}
