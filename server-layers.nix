# server-layers.nix — layer import set for headless cloud/server hosts.
# Imports all layers EXCEPT the full 10-system/13-users user profile.
# Imports the HM catalog module separately so all HM option definitions
# are available (tag profiles can reference them).
{ ... }:
{
  imports = [
    ./layers/10-system/11-foundation
    ./layers/10-system/12-processor
    # Full user profile excluded (HM + user-specific config):
    # ./layers/10-system/13-users
    # HM catalog — vicinae + sops HM modules only (nixvim/dsh/yazelix via their barrels):
    ./layers/10-system/13-users/hm-catalog.nix
    ./layers/10-system/14-virtualization
    ./layers/10-system/15-filesystem
    ./layers/10-system/16-mobile
    ./layers/10-system/17-app-runtimes
    ./layers/10-system/18-peripherals
    ./layers/10-system/19-optimizations

    ./layers/20-services
    ./layers/30-environments
    ./layers/40-desktop
    ./layers/50-cli-tui-programs
    ./layers/60-gui-programs
    ./layers/70-agents
    ./layers/90-profiles/tags
  ];
}
