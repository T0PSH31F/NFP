# flake-parts/features/nixos/packages/ai.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);
in
{
  config = lib.mkIf (hasTag "ai-server") {
    environment.systemPackages = with pkgs; [
      ollama
    ];
  };
}
