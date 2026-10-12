# Services Tier Entry Point — imports service sub-tiers
{ ... }:
{
  imports = [
    ./21-networking
    ./22-ai
    ./23-media
    ./24-communication
    ./25-data
    ./26-monitoring
    ./27-automation
    ./29-ci
  ];
}
