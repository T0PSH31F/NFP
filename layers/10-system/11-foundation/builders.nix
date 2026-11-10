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

  # Master registry of potential build machines across the fleet (distributed equally across luffy, z0r0, sanji)
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
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
    }
    {
      hostName = "z0r0.${baseDomain}";
      machineId = "z0r0";
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
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
    }
    # sanji (workstation/laptop) is explicitly excluded as a build machine
    # per workstation resource preservation rules (GEMINI.md section 5).
    # sanji offloads builds to z0r0/luffy; other machines must never build on sanji.
    # RETIRED 2026-10-13: nami removed as a distributed builder. The instance
    # (47.254.90.69) went permanently unreachable on 2026-10-12, so every build
    # paid a full SSH connect-timeout before falling through to a real builder.
    # Re-add the block below if nami ever returns:
    #   {
    #     hostName = "nami.${baseDomain}";
    #     machineId = "nami";
    #     system = "x86_64-linux";
    #     maxJobs = 2;
    #     speedFactor = 1;
    #     supportedFeatures = [ ];
    #     sshUser = "root";
    #   }
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
          sshKey
          ;
      }) (filter (m: m.machineId != "phone" || cfg.enablePhoneBuilder) remoteBuildMachines);
    };

    # Force identities-only and use host ed25519 key for fleet SSH connections to prevent agent key exhaustion
    programs.ssh.extraConfig = ''
      Host *.${baseDomain} 100.64.0.*
        IdentitiesOnly yes
        IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';

    # Declarative host keys for all fleet machines to eliminate "Host key verification failed" in nix-daemon
    programs.ssh.knownHosts = {
      z0r0 = {
        hostNames = [
          "z0r0.${baseDomain}"
          "100.64.0.1"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBbma86jIAHhoKLb7xDbXqTxofk0dz3BnuZEXmQQokRo";
      };
      luffy = {
        hostNames = [
          "luffy.${baseDomain}"
          "100.64.0.3"
          "192.168.1.54"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILq2CNXMpVIOPv3byApLfUgbhSYYXWVjeYA19bpjJuMz";
      };
      sanji = {
        hostNames = [
          "sanji.${baseDomain}"
          "100.64.0.6"
          "192.168.1.68"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7VxJTk07Z8WIcBoBFzqOy2TyEhypZmHDsGJeZzKFqa";
      };
    };
  };
}
