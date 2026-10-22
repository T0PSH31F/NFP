# All layers — unconditional import of every dendritic layer.
# Tags-as-data: ALL modules are always imported. Enablement is via
# options and lib.mkIf guards, never via import-site control flow.
{ ... }:
{
  imports = [
    ./layers/10-system
    ./layers/20-services
    ./layers/30-environments
    ./layers/40-desktop
    ./layers/50-cli-tui-programs
    ./layers/60-gui-programs
    ./layers/70-agents
    ./layers/90-profiles/tags
  ];
}
