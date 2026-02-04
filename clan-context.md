# Clan Project Context & Refactoring Guide
# Grandlix-Gang Context & Refactoring Guide (CLAN_CONTEXT.md)

## 1. Project Overview
**Repo:** `github:T0PSH31F/Grandlix-Gang`
**Owner:** T0psh31f (Erik)
**Location:** Los Angeles, CA
**Framework:** Clan (Sovereign Infrastructure on NixOS)
**Core Philosophy:** Impermanence (tmpfs root), Sops-Nix Secrets, Flake-parts, Tag-based Module Injection.

## 2. The Refactoring Mandate: "Tags"
We are refactoring from monolithic configurations to a **Tag-Based Package Injection System**.
* **Old Way:** Hardcoded `roles = []` or manual imports.
* **New Way:** Machines declare `clan.tags = [ "desktop" "ai-ml" ];` and modules are conditionally imported.

### Required Directory Structure
The agent must enforce this specific structure for the refactor:
```text
packages/
├── core/                  # BASE SYSTEM (Git, Curl, Htop, Persistence, Sops)
│   └── default.nix        # Always imported
├── desktop/               # Tag: "desktop"
│   ├── default.nix        # Aggregator (Hyprland + SDDM)
│   ├── hyprland.nix       # Sub-Tag: "hyprland"
│   ├── sddm.nix           # Sub-Tag: "sddm"
│   └── themes.nix         # Tag: "themes" (Lainframe, Sonic Cursor)
├── ai-ml/                 # Tag: "ai-server" or "ai-heavy"
│   ├── default.nix
│   ├── ollama.nix         # Service: Ollama (Port 11434)
│   └── open-webui.nix     # Service: Open-WebUI (Port 8080)
├── media/                 # Tag: "media-server"
│   ├── default.nix
│   ├── jellyfin.nix       # Service: Jellyfin (Port 8096)
│   └── arr-stack.nix      # Services: Radarr, Sonarr, Prowlarr
├── networking/            # Tag: "network"
│   ├── tailscale.nix      # Always on for Grandlix-Gang
│   ├── pihole.nix         # Tag: "dns-server" (Port 53/8081)
│   └── harmonia.nix       # Tag: "binary-cache" (Port 5000)
└── hardware/              # Hardware specific
    ├── nvidia.nix         # Tag: "nvidia"
    └── intel.nix          # Tag: "intel"
3. Machine Inventory & Tag Assignments
z0r0 (Primary Hub)
Hardware: LG Gram 17Z90Q, Intel i7-1260P, 16GB RAM.

Network: 192.168.1.100 (Static).

Target Tags:

Nix
clan.tags = [ "desktop" "ai-server" "binary-cache" "database" "dns-server" "intel" ];
Persistence: Critical. /persist/home/t0psh31f, /persist/var/lib/{ollama,postgres,harmonia}.

nami (Media/Storage)
Hardware: LUKS-encrypted Btrfs.

Network: DHCP.

Target Tags:

Nix
clan.tags = [ "media-server" "download-server" ];
Storage: Mounts /srv/media via Btrfs subvolume @media.

luffy (Future Gaming)
Target Tags: [ "desktop" "gaming" "ai-heavy" "nvidia" ].

4. Implementation Rules (Agent Anti-Hallucination)
Impermanence First: In packages/core/default.nix, ensure environment.persistence."/persist" is configured. Do not break boot by losing SSH keys.

Clan Secrets: Use clan.core.vars and sops-nix. Secrets are at ~/Grandlix-Gang/secrets/.

Harmonia Key: secrets/harmonia.yaml

Postgres: secrets/postgres.yaml

Module Logic: Create modules/tags.nix to define options.clan.tags.

Use: lib.mkIf (hasTag "ai-server") { services.ollama.enable = true; }

Networking:

Tailscale is essential for the mesh (100.x.x.x).

Open firewall ports defined in "Inventory" (e.g., 5000 for Harmonia, 11434 for Ollama).

5. Deployment Reference
Update: clan machines update (Preferred over nixos-rebuild).

Secrets: clan secrets upload <machine>.

## 1. Project Mandate: The "Tagged" Architecture
We are refactoring this NixOS/Clan project to use a **Tag-Based Package Injection System**.
Instead of monolithic `environment.systemPackages`, machines declare a list of "tags" (e.g., `["desktop" "gaming"]`), and the module system conditionally imports the relevant suites.

### The "Tag" Logic
We use a conditional merge strategy.
* **Input:** `clan.tags = [ "desktop" "ai-ml" ];` (defined in `inventory/machines/machine-name.nix`)
* **Logic:** `lib.mkIf (hasTag "desktop") { ... }`

### Directory Structure (Strict Adherence)
The agent must enforce this directory structure:
```text
packages/
├── core/                  # Base system (git, curl, htop) - Always Imported
│   └── default.nix
├── desktop/               # Tag: "desktop"
│   ├── default.nix        # Aggregator
│   ├── hyprland.nix       # Tag: "hyprland" (optional sub-tag)
│   ├── niri.nix           # Tag: "niri"
│   ├── fonts.nix          # Tag: "fonts"
│   └── fun-tools.nix      # Tag: "fun-tools"
├── development/           # Tag: "dev"
├── pentest/               # Tag: "pentest"
│   ├── default.nix
│   ├── wifi.nix           # Tag: "wifi-pentest"
│   └── recon.nix          # Tag: "recon"
├── gaming/                # Tag: "gaming"
├── ai-ml/                 # Tag: "ai-ml"
│   ├── default.nix
│   ├── agents.nix         # Tag: "agents"
│   ├── ai-tools.nix       # Tag: "ai-tools"
│   └── ml-tools.nix       # Tag: "ml-tools"
├── media/                 # Tag: "media"
├── networking/            # Tag: "network"
├── hardware/              # Tags: "nvidia", "amd-gpu", "intel"
└── virtualization/        # Tag: "virtualization"
2. Implementation Reference (Copy-Paste Ready)
A. The Module Logic (modules/tags.nix)
The agent should create this module to enable the tag system.

Nix
{ lib, config, ... }:
let
  cfg = config.clan;
in
{
  options.clan.tags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "List of feature tags to enable for this machine.";
  };

  config.lib.clan = {
    hasTag = tag: lib.elem tag cfg.tags;
    hasTags = tags: lib.all (t: lib.elem t cfg.tags) tags;
    hasAnyTag = tags: lib.any (t: lib.elem t cfg.tags) tags;
  };
}
B. Example Suite (packages/desktop/default.nix)
How to write the conditional imports.

Nix
{ config, lib, pkgs, ... }:
let
  inherit (config.lib.clan) hasTag hasAnyTag;
in
lib.mkMerge [
  # 1. Base Desktop (Always loaded if "desktop" tag is present)
  (lib.mkIf (hasTag "desktop") {
    environment.systemPackages = with pkgs; [
      firefox kitty wofi pavucontrol
    ];
  })

  # 2. Sub-Modules (Imported only if specific sub-tags are present)
  (lib.mkIf (hasTag "desktop" && hasTag "hyprland") {
    imports = [ ./hyprland.nix ];
  })
  
  (lib.mkIf (hasTag "desktop" && hasTag "fonts") {
    imports = [ ./fonts.nix ];
  })
]
3. Clan Framework Specifics (Docs Reference)
A. Inventory (flake.nix)
Machines are defined in the inventory. We inject tags here.

Nix
clan.core.clan.inventory.machines = {
  "Z0r0" = {
    imports = [ 
      ./machines/z0r0/configuration.nix
      ./packages/default.nix # Loads the tag logic
    ];
    
    # Define tags for this specific machine
    clan.tags = [ "desktop" "gaming" "nvidia" "ai-ml" ];

    # Clan Standard Metadata
    clan.core.networking.zerotier.controller.enable = true;
  };
};
B. Disko + ZFS Encryption (Reference: docs.clan.lol)
Constraint: Encryption keys must be managed via Clan Vars to allow unattended booting or remote unlocking.

1. Define the Secret Generator (vars/per-machine/machine/secrets.nix):

Nix
clan.core.vars.generators.zfs_key = {
  files."zfs.key" = {
    # "partitioning" ensures the key is available during the format phase
    neededFor = "partitioning"; 
    secret = true;
  };
  runtimeInputs = [ pkgs.coreutils ];
  script = ''
    # Generate a secure key
    openssl rand -hex 32 | tr -d '\n' > $out/zfs.key
  '';
};
2. Disko Config (disk-config.nix):

Nix
{
  disko.devices.disk.main.content = {
    type = "gpt";
    partitions = {
      zfs = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "zroot";
        };
      };
    };
  };
  
  disko.devices.zpool.zroot = {
    type = "zpool";
    # Reference the generated secret for encryption
    options.feature@encryption = "on";
    options.keylocation = "file://${config.clan.core.vars.generators.zfs_key.files."zfs.key".path}";
    options.keyformat = "hex";
  };
}
C. Clan Services (Reference)
When enabling standard services, prefer clan.core.services.* over services.* when available, as they handle firewalling and Zerotier DNS automatically.

Syncthing: clan.core.services.syncthing.enable = true;

Backups: clan.core.services.borgbackup (Use for backing up the ai-ml models directory).

Networking: clan.core.networking.zerotier.enable = true;

clan also has native services/options for admin, certificates, coredns, matrix-synapse, monitoring, sshd, trusted-nix-caches, wiregaurd, users, **packages(whcih should be defined with conditional imports for easyily enabling sets/suites based on dendretic pattern and packages already defined that need restructered into this format)**
4. all of which can be found and should be referenced at docs.clan.lol/

 Refactoring Strategy for Agent
Scaffold: Create the packages/ directory structure first.

Move & Tag: Move existing packages from configuration.nix into the relevant packages/category/default.nix.

Conditionals: Wrap every package group in lib.mkIf (hasTag "X").

Hardware: Create packages/hardware/nvidia.nix containing hardware.opengl, services.xserver.videoDrivers, and nvidia-container-toolkit.

Verify: Ensure flake.nix imports the new module system.

Make sure you understand everything and that everything builds and works in accordance with the docs! https://docs.clan.lol/ I will leave to your beter judgement if you can come up with better/more accurate architectural than I have suggested based on your research and understanding of clan. Also make sure to preserve our desktop configurations and noctalia-sh which should be importable with desktop/hyprland/niri tags. This is a reorganization and refactoring though we're restructuring try to preserve currently defined functionality and configurations as much as possible.