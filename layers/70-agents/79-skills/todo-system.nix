# Tier: 79-skills
# Module: todo-system.nix
# Purpose: Agent task tracking system — Rofi frontend, Hermes roundups, and periodic timers.
# Option Path: layers.layer-79.skills.todo-system
# Enabling Host Tags: ai-agent, desktop
# RAM Footprint: light (<300MB)
{
  lib,
  ...
}:
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "todo-system" "enable" ]
      [ "layers" "layer-79" "skills" "todo-system" "enable" ]
    )
  ];

  options.layers.layer-79.skills.todo-system = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Rofi + Hermes To-Do system";
    };
  };
}
