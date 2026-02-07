# Dendritic Pattern Migration - Implementation Plan

## Objective
Refactor Grandlix-Gang configuration to use flake-parts dendritic pattern with clan-core as primary abstraction, achieving:
- 30%+ reduction in root-level file count (currently 14 files)
- Tag-based deployment and service distribution
- Feature modularity (1 feature = 1 file)
- Zero duplication via proper module system usage

## Current State Analysis
```
Root files: 14 (target: ≤9)
├── flake.nix (keep)
├── flake.lock (keep)
├── clan.nix (keep - primary clan config)
├── hardware-configuration.nix (consolidate into machines/)
├── facter.json (keep)
├── README.md (keep)
├── README-devenvs.md (merge into main README)
├── clan-context.md (archive or merge)
├── .sops.yaml (keep)
├── .envrc (keep)
├── .gitignore (keep)
├── nami-iso (move to scripts/)
├── optimization-metrics.txt (move to docs/)
└── time_output.txt (move to docs/)
```

Current structure:
- `modules/nixos/` - 18 NixOS modules
- `modules/home/` - 12 Home Manager modules
- `modules/clan/` - 5 clan-specific modules
- `machines/` - 3 machine configs (z0r0, luffy, nami)
- `clan-service-modules/` - 3 clan services (ai, desktop, media)

## Target Structure

```
Grandlix-Gang/
├── flake.nix                    # Main flake - flake-parts integration
├── flake.lock                   # Lock file
├── clan.nix                     # Clan inventory + machine definitions
├── facter.json                  # Hardware facts
├── .sops.yaml                   # Secrets config
├── README.md                    # Primary documentation
├── .envrc, .gitignore          # Tooling
│
├── flake-parts/                 # NEW: Dendritic modules directory
│   ├── features/                # Feature toggles (tag-agnostic)
│   │   ├── nixos/              # NixOS features
│   │   │   ├── gaming.nix
│   │   │   ├── virtualization.nix
│   │   │   ├── impermanence.nix
│   │   │   ├── mobile-support.nix
│   │   │   ├── flatpak.nix
│   │   │   ├── appimage.nix
│   │   │   └── performance.nix
│   │   └── home/               # Home Manager features
│   │       ├── dev-tools.nix
│   │       ├── pentest-tools.nix
│   │       ├── gaming-apps.nix
│   │       └── productivity.nix
│   │
│   ├── desktop/                # Desktop environment stack
│   │   ├── hyprland.nix
│   │   ├── noctalia.nix
│   │   ├── ghostty.nix
│   │   ├── shikane.nix
│   │   └── portals.nix
│   │
│   ├── themes/                 # Visual themes
│   │   ├── sddm-lain.nix
│   │   ├── sddm-lainframe.nix
│   │   ├── sddm-sel.nix
│   │   ├── grub-lain.nix
│   │   ├── plymouth-hellonavi.nix
│   │   ├── plymouth-matrix.nix
│   │   └── cursors.nix
│   │
│   ├── hardware/               # Hardware profiles
│   │   ├── intel-12th-gen.nix
│   │   ├── laptop.nix
│   │   └── default.nix
│   │
│   ├── system/                 # Core system modules
│   │   ├── base.nix
│   │   ├── nix-settings.nix
│   │   ├── networking.nix
│   │   └── security.nix
│   │
│   └── services/               # Individual service modules
│       ├── ai/
│       │   ├── llm-agents.nix
│       │   ├── ollama.nix
│       │   ├── open-webui.nix
│       │   ├── localai.nix
│       │   └── chromadb.nix
│       ├── media/
│       │   ├── immich.nix
│       │   ├── calibre-web.nix
│       │   ├── jellyfin.nix
│       │   ├── arr-stack.nix
│       │   └── aria2.nix
│       ├── infrastructure/
│       │   ├── caddy.nix
│       │   ├── home-assistant.nix
│       │   ├── n8n.nix
│       │   ├── nextcloud.nix
│       │   └── harmonia.nix
│       └── communication/
│           ├── matrix.nix
│           └── mautrix.nix
│
├── machines/                    # Machine-specific configs
│   ├── z0r0/
│   │   ├── default.nix         # Main config (tags, hardware, overrides)
│   │   └── hardware.nix        # Hardware-specific (LUKS, filesystems)
│   ├── luffy/
│   │   ├── default.nix
│   │   └── hardware.nix
│   └── nami/
│       ├── default.nix
│       └── hardware.nix
│
├── clan-services/              # Clan service instances (role-based)
│   ├── sillytavern/
│   │   ├── module.nix          # Service definition
│   │   └── roles.nix           # Role assignments
│   ├── homepage-dashboard/
│   └── binary-cache/
│
├── overlays/                   # Package overlays
│   ├── default.nix
│   ├── custom-packages.nix
│   ├── desktop-packages.nix
│   └── themes.nix
│
├── packages/                   # Custom packages
│   └── default.nix
│
├── devenvs/                    # Development environments
│   ├── default.nix
│   ├── python-ai-agent.nix
│   ├── rust-saas.nix
│   └── ...
│
├── templates/                  # Templates (ISO, etc.)
│   └── iso/
│
├── scripts/                    # Helper scripts
├── docs/                       # Documentation
├── tests/                      # Integration tests
├── secrets/                    # Sops secrets
└── sops/                       # Sops keys
```

## Migration Strategy

### Phase 1: Preparation (Risk: Low)
**Goal**: Set up new structure without breaking existing config

1. **Create branch**: `refactor3`
   ```bash
   git checkout -b refactor3
   ```

2. **Create directory structure**:
   ```bash
   mkdir -p flake-parts/{features/{nixos,home},desktop,themes,hardware,system,services/{ai,media,infrastructure,communication}}
   mkdir -p machines/{z0r0,luffy,nami}
   mkdir -p clan-services/{sillytavern,homepage-dashboard,binary-cache}
   mkdir -p docs
   ```

3. **Archive old docs**:
   ```bash
   mv optimization-metrics.txt time_output.txt docs/
   cat README-devenvs.md >> README.md
   rm README-devenvs.md
   mv clan-context.md docs/
   ```

4. **Baseline measurement**:
   ```bash
   find . -maxdepth 1 -type f | wc -l > docs/refactor3-baseline.txt
   time nix eval .#nixosConfigurations.z0r0.config.system.build.toplevel > docs/eval-time-before.txt 2>&1
   ```

### Phase 2: Extract Core System Modules (Risk: Low)
**Goal**: Move foundational system modules to flake-parts/system/

**Files to migrate**:
- `modules/nixos/system/base.nix` → `flake-parts/system/base.nix`
- `modules/nixos/nix-settings.nix` → `flake-parts/system/nix-settings.nix`
- `modules/nixos/networking.nix` → `flake-parts/system/networking.nix`

**Process**:
```nix
# flake-parts/system/default.nix
{ ... }:
{
  imports = [
    ./base.nix
    ./nix-settings.nix
    ./networking.nix
  ];
}
```

**Validation**:
```bash
nix flake check
clan machines build z0r0
```

### Phase 3: Extract Hardware Profiles (Risk: Low)
**Goal**: Consolidate hardware configs

**Files to migrate**:
- `modules/nixos/hardware/intel-12th-gen.nix` → `flake-parts/hardware/intel-12th-gen.nix`
- `modules/nixos/system/laptop.nix` → `flake-parts/hardware/laptop.nix`
- Extract hardware-specific from each machine config

**Process**:
```nix
# machines/z0r0/hardware.nix
{ ... }:
{
  imports = [
    ../../flake-parts/hardware/intel-12th-gen.nix
    ../../flake-parts/hardware/laptop.nix
  ];
  
  # LUKS
  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-uuid/...";
  
  # Filesystems
  fileSystems."/".device = "/dev/mapper/crypted";
  fileSystems."/".fsType = "btrfs";
  # ... rest of filesystems
  
  # Swap
  swapDevices = [ { device = "/persist/swapfile"; size = 32768; } ];
}
```

**Validation**: Build each machine

### Phase 4: Extract Themes (Risk: Low)
**Goal**: Move all theme modules to flake-parts/themes/

**Files to migrate**:
- All `modules/nixos/themes/*.nix` → `flake-parts/themes/*.nix`

**Process**:
```nix
# flake-parts/themes/default.nix
{ ... }:
{
  imports = [
    ./sddm-lain.nix
    ./sddm-lainframe.nix
    ./sddm-sel.nix
    ./grub-lain.nix
    ./plymouth-hellonavi.nix
    ./plymouth-matrix.nix
    ./cursors.nix
  ];
}
```

**Validation**: Test theme activation on z0r0

### Phase 5: Extract Desktop Stack (Risk: Medium)
**Goal**: Consolidate desktop environment

**Files to migrate**:
- `modules/home/hyprland.nix` → `flake-parts/desktop/hyprland.nix`
- `modules/home/ghostty.nix` → `flake-parts/desktop/ghostty.nix`
- `modules/home/shikane.nix` → `flake-parts/desktop/shikane.nix`
- `modules/nixos/system/desktop-portals.nix` → `flake-parts/desktop/portals.nix`

**Process**:
```nix
# flake-parts/desktop/default.nix
{ config, lib, ... }:
{
  imports = [
    ./hyprland.nix
    ./ghostty.nix
    ./shikane.nix
    ./portals.nix
  ];
  
  # Tag-based activation
  config = lib.mkIf (builtins.elem "desktop" config.clan.tags) {
    # Desktop will auto-enable based on tag
  };
}
```

**Validation**: Login to desktop environment

### Phase 6: Extract Services (Risk: Medium-High)
**Goal**: Individual service modules in flake-parts/services/

**Files to migrate**:
- Extract each service from `modules/nixos/services/*.nix`
- Create individual service files

**Process**:
```nix
# flake-parts/services/ai/ollama.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.ollama;
in
{
  options.services.ollama.enable = mkEnableOption "Ollama LLM server";
  
  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda";
      # ... rest of config
    };
  };
}
```

**Tag-based activation** (in service-distribution or similar):
```nix
# Auto-enable ollama on ai-server tagged machines
services.ollama.enable = lib.mkDefault (builtins.elem "ai-server" config.clan.tags);
```

**Validation**: Test each service individually

### Phase 7: Extract Features (Risk: Low)
**Goal**: Move feature toggles to flake-parts/features/

**Files to migrate**:
- `modules/nixos/gaming.nix` → `flake-parts/features/nixos/gaming.nix`
- `modules/nixos/virtualization.nix` → `flake-parts/features/nixos/virtualization.nix`
- `modules/nixos/impermanence.nix` → `flake-parts/features/nixos/impermanence.nix`
- `modules/nixos/mobile.nix` → `flake-parts/features/nixos/mobile-support.nix`
- `modules/home/dev.nix` → `flake-parts/features/home/dev-tools.nix`
- `modules/home/pentest.nix` → `flake-parts/features/home/pentest-tools.nix`

**Validation**: Feature toggles work as expected

### Phase 8: Refactor Clan Services (Risk: Medium)
**Goal**: Migrate to clan-services/ with role-based assignments

**Process**:
```nix
# clan-services/sillytavern/module.nix
{ config, lib, pkgs, ... }:
{
  options.clan.services.ai.sillytavern.enable = lib.mkEnableOption "SillyTavern";
  
  config = lib.mkIf config.clan.services.ai.sillytavern.enable {
    services.sillytavern = {
      enable = true;
      # ... config
    };
  };
}
```

```nix
# clan.nix
{
  inventory = {
    instances = {
      sillytavern = {
        module = { name = "ai"; input = "self"; };
        roles.sillytavern.machines = {
          z0r0 = { };
          luffy = { };
        };
      };
    };
  };
}
```

**Validation**: Clan service deploys correctly

### Phase 9: Update Machine Configs (Risk: Medium)
**Goal**: Simplify machine configs to use new structure

**Process**:
```nix
# machines/z0r0/default.nix
{ inputs, lib, ... }:
{
  imports = [
    ./hardware.nix
    ../../flake-parts/system
    ../../flake-parts/themes
    ../../flake-parts/desktop
    ../../flake-parts/hardware
    ../../flake-parts/features/nixos
    ../../flake-parts/services/ai
    ../../flake-parts/services/media
    ../../flake-parts/services/infrastructure
  ];
  
  # Machine metadata
  networking.hostName = "z0r0";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
  
  # Tags (drives service distribution)
  clan.tags = [
    "desktop"
    "laptop"
    "ai-server"
    "binary-cache"
    "database"
    "dev"
  ];
  
  # Feature toggles
  gaming.enable = false;
  virtualization.enable = true;
  system-config.impermanence.enable = true;
  
  # Theme selection
  themes = {
    sddm-lainframe.enable = true;
    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };
  
  # Service overrides (if needed)
  services.ollama.acceleration = "cuda";
  
  # Home Manager
  home-manager.users.t0psh31f = {
    imports = [ ../../flake-parts/features/home ];
    programs.yazelix.enable = true;
  };
}
```

**Validation**: Build and deploy each machine

### Phase 10: Update flake.nix (Risk: High)
**Goal**: Integrate flake-parts modules into main flake

**Process**:
```nix
# flake.nix
{
  outputs = inputs@{ flake-parts, clan-core, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        clan-core.flakeModules.default
        ./devenvs
      ];
      
      clan = {
        imports = [ ./clan.nix ];
        specialArgs = { inherit inputs; };
        pkgsForSystem = system: import inputs.nixpkgs {
          localSystem = system;
          config.allowUnfree = true;
          overlays = [
            inputs.nur.overlays.default
            (import ./overlays/custom-packages.nix)
          ];
        };
      };
      
      # ... rest of flake config
    };
}
```

**Validation**: Full flake check

### Phase 11: Clean Up Old Structure (Risk: Low)
**Goal**: Remove deprecated modules/

**Process**:
```bash
git mv modules modules-old
# After validation, delete:
rm -rf modules-old
```

**Validation**: Full rebuild from scratch

### Phase 12: Final Validation (Risk: Low)
**Goal**: Complete validation checklist

**Checklist**:
- [ ] `nix flake check` passes with zero errors
- [ ] Each machine builds: `clan machines build <machine>`
- [ ] All option references verified via mcp-nixos
- [ ] No duplicate definitions
- [ ] Ghostty + shaders tested and functional
- [ ] Noctalia desktop environment launches properly
- [ ] AI services accessible on tagged machines
- [ ] DevShells work: `nix develop`
- [ ] Home-manager activations succeed
- [ ] Secrets properly managed via sops-nix + clan
- [ ] File count in root reduced by 30%+ (14 → ≤9)
- [ ] README updated with new structure
- [ ] Performance targets met:
  - [ ] Eval time < 3 seconds
  - [ ] Flake check < 10 seconds

## Risk Mitigation

1. **Branch Strategy**: Work on `refactor3` branch, keep `refactor2` intact
2. **Git Worktree**: `git worktree add ../Grandlix-Gang-old refactor2` for comparison
3. **Incremental Testing**: Build after each phase
4. **Backup**: Keep old structure until all validations pass
5. **Rollback Plan**: Each commit represents a reversible step

## Tools & Verification

### MCP NixOS
Use for EVERY option and package verification:
```bash
# Example: Verify ollama options
mcp_nixos_nix --action search --type options --query "services.ollama"
```

### Formatting
```bash
nixfmt-tree .
```

### Linting
```bash
deadnix .
statix check .
```

### Parallel Builds
```bash
nix-fast-build
```

### Clan Verification
```bash
clan machines list
clan machines build --all
```

## Success Criteria

### Structural Goals
- ✅ Root file count: 14 → ≤9 (36%+ reduction)
- ✅ Feature = 1 file in flake-parts/
- ✅ Machine config < 150 lines (currently 270 for z0r0)
- ✅ Zero duplication

### Functional Goals
- ✅ All machines build successfully
- ✅ All services functional
- ✅ Desktop environment works
- ✅ Theme switching works
- ✅ Clan deployment works
- ✅ DevShells accessible

### Performance Goals
- ✅ Eval time < 3 seconds
- ✅ Flake check < 10 seconds
- ✅ No increase in build closure size

### Maintainability Goals
- ✅ Adding new machine: ~10 lines + tags
- ✅ Adding new service: 1 file in flake-parts/services/
- ✅ Adding new feature: 1 file in flake-parts/features/
- ✅ Clear documentation in README

## Timeline Estimate

- Phase 1: 30 minutes
- Phase 2: 1 hour
- Phase 3: 1 hour
- Phase 4: 30 minutes
- Phase 5: 1.5 hours
- Phase 6: 3 hours (most complex)
- Phase 7: 1 hour
- Phase 8: 1.5 hours
- Phase 9: 2 hours
- Phase 10: 1 hour
- Phase 11: 30 minutes
- Phase 12: 1 hour

**Total**: ~14 hours (spread across multiple sessions)

## Next Steps

1. Review and approve this plan
2. Create refactor3 branch
3. Start with Phase 1 (Preparation)
4. Execute phases incrementally with validation
5. Regular commits after each successful phase
