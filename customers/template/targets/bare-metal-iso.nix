# Target 1: Bare-Metal Live ISO Profile
{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../configuration.nix
  ];
  jarvis.deploymentTarget = "bare-metal-iso";
}
