# layers/10-system/11-foundation/builders.nix
# Purpose: Declarative Fleet Distributed Building Configuration
# Enables z0r0, luffy, nami, and mobile nodes (nix-on-droid) to build packages in parallel.

{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.layers.layer-10.system.builders;
  currentHost = config.networking.hostName;
  baseDomain = config.layers.meta.tailnetDomain or "nfp.nix";

  # Master registry of potential build machines across the fleet
  allBuildMachines = [
    {
      hostName = "luffy.${baseDomain}";
      machineId = "luffy";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "kvm"
        "big-parallel"
        "nixos-test"
        "benchmark"
      ];
      sshUser = "root";
    }
    {
      hostName = "z0r0.${baseDomain}";
      machineId = "z0r0";
      system = "x86_64-linux";
      maxJobs = 6;
      speedFactor = 2;
      supportedFeatures = [
        "kvm"
        "big-parallel"
        "nixos-test"
      ];
      sshUser = "root";
    }
    {
      hostName = "nami.${baseDomain}";
      machineId = "nami";
      system = "x86_64-linux";
      maxJobs = 2;
      speedFactor = 1;
      supportedFeatures = [ ];
      sshUser = "root";
    }
    {
      hostName = "phone.${baseDomain}";
      machineId = "phone";
      system = "aarch64-linux";
      maxJobs = 2;
      speedFactor = 1;
      supportedFeatures = [ ];
      sshUser = "root";
    }
  ];

  # Filter out current host from its own buildMachines list (don't SSH to self)
  remoteBuildMachines = filter (m: m.machineId != currentHost) allBuildMachines;
in
{
  options.layers.layer-10.system.builders = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable distributed fleet compilation across z0r0, luffy, nami, and phone nodes.";
    };

    enablePhoneBuilder = mkOption {
      type = types.bool;
      default = false;
      description = "Include phone (nix-on-droid aarch64-linux) in remote builders list.";
    };
  };

  config = mkIf cfg.enable {
    nix = {
      distributedBuilds = true;

      # Enable remote builders using substituters directly on remote nodes
      extraOptions = ''
        builders-use-substitutes = true
      '';

      buildMachines = map (m: {
        inherit (m)
          hostName
          system
          maxJobs
          speedFactor
          supportedFeatures
          sshUser
          ;
      }) (filter (m: m.machineId != "phone" || cfg.enablePhoneBuilder) remoteBuildMachines);
    };
  };
}
