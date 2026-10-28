# System Tier Entry Point — imports system sub-tiers
{ ... }:
{
  imports = [
    ./11-foundation
    ./12-processor
    ./13-users
    ./14-virtualization
    ./15-filesystem
    ./16-mobile
    ./17-app-runtimes
    ./18-peripherals
    ./19-optimizations
    ./nas-mounts.nix
  ];
}
