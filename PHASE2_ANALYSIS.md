# Phase 2: Dendritic Refactor + Yazelix Conflict Analysis

## STEP 1: CONFLICT REPORT

### ✅ Yazelix Conflicts - RESOLVED
**Status**: Helix successfully archived, no active conflicts found

#### Checked Locations:
1. ✅ `modules/Home-Manager/editors/helix/` → **MOVED to old/Home-Manager/editors/helix/**
2. ✅ `modules/Home-Manager/editors/default.nix` → **Helix import removed**
3. ✅ `modules/Home-Manager/yazi/default.nix` → **Standalone yazi (no conflict with yazelix)**
4. ✅ `modules/Home-Manager/yazi/yazelix.nix` → **Yazelix module active**
5. ✅ `modules/Home-Manager/shell/zsh.nix` → **No zsh conflicts (yazelix doesn't replace zsh)**

#### Active Editor Modules:
- `modules/Home-Manager/editors/nvf.nix` - NVF (Neovim) - **NO CONFLICT**
- `modules/Home-Manager/editors/vscode.nix` - VSCode - **NO CONFLICT**
- `modules/Home-Manager/editors/zed.nix` - Zed - **NO CONFLICT**
- `modules/Home-Manager/yazi/yazelix.nix` - Yazelix (Yazi + Helix) - **ACTIVE**

#### Yazelix Integration Status:
```nix
# modules/Home-Manager/yazi/yazelix.nix
programs.helix.enable = true;  # Yazelix owns Helix
programs.yazi.enable = true;   # Yazelix owns Yazi
```

**CONCLUSION**: No Yazelix conflicts. Helix properly archived, yazelix module active.

---

## STEP 2: PATTERN VIOLATIONS IN machines/z0r0/default.nix

### Current Issues:

#### ❌ Issue 1: Scattered Option Declarations
**Problem**: Options spread across multiple top-level attributes instead of nested attrsets

**Current (Messy)**:
```nix
config.nix-tools.enable = true;
config.desktop-portals.enable = true;
programs.yazelix.enable = true;
programs.keybind-cheatsheet.enable = true;
desktop.noctalia.enable = true;
desktop.dankmaterialshell.enable = false;
themes.sddm-sel.enable = true;
themes.grub-lain.enable = true;
mobile.android.enable = true;
gaming.enable = true;
virtualization.enable = true;
services.ssh-agent.enable = true;
services.home-assistant-server.enable = true;
# ... 20+ more scattered service options
```

**Target (Dendritic)**:
```nix
config = {
  nix-tools.enable = true;
  desktop-portals.enable = true;
  desktop = {
    noctalia = { enable = true; backend = "hyprland"; };
    dankmaterialshell.enable = false;
  };
  programs = {
    yazelix.enable = true;
    keybind-cheatsheet.enable = true;
  };
  themes = {
    sddm-sel = { enable = true; variant = "shaders"; };
    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };
  mobile = {
    android.enable = true;
    ios.enable = true;
  };
  gaming.enable = true;
  virtualization.enable = true;
};

services = {
  ssh-agent.enable = true;
  desktop = {
    searxng.enable = false;
    pastebin.enable = false;
  };
  infrastructure = {
    home-assistant.enable = true;
    caddy.enable = true;
    n8n.enable = true;
  };
  ai = {
    sillytavern.enable = true;
    llm-agents.enable = true;
    services = {
      enable = true;
      open-webui.enable = true;
      localai.enable = true;
      chromadb.enable = true;
    };
  };
  media = {
    immich.enable = true;
    calibre-web.enable = true;
    nextcloud.enable = true;
    stack.enable = false;
  };
  communication = {
    matrix.enable = true;
    mautrix-bridges.enable = true;
    avahi.enable = true;
  };
  monitoring.enable = false;
  dashboard.homepage.enable = true;
};
```

#### ❌ Issue 2: Module Option Paths Don't Match Usage
**Problem**: Modules declare flat options, but dendritic pattern needs nested paths

**Examples**:
```nix
# Current module declarations (WRONG for dendritic):
options.desktop.noctalia.enable = ...  # ✅ Already nested
options.yazelix.enable = ...           # ❌ Should be config.programs.yazelix
options.keybind-cheatsheet.enable = ...# ❌ Should be config.programs.keybind-cheatsheet
options.ssh-agent.enable = ...         # ❌ Should be services.desktop.ssh-agent
```

---

## STEP 3: REFACTOR PLAN

### Phase 2A: Module Option Path Alignment

#### Files to Update (17 modules):

1. **modules/Home-Manager/yazi/yazelix.nix**
   - Change: `options.yazelix.enable` → `options.programs.yazelix.enable`
   - Change: `let cfg = config.yazelix` → `let cfg = config.programs.yazelix`

2. **modules/Home-Manager/tools/keybinds.nix**
   - Change: `options.keybind-cheatsheet.enable` → `options.programs.keybind-cheatsheet.enable`
   - Change: `let cfg = config.keybind-cheatsheet` → `let cfg = config.programs.keybind-cheatsheet`

3. **clan-service-modules/desktop/ssh-agent.nix**
   - Change: `options.services.ssh-agent.enable` → `options.services.desktop.ssh-agent.enable`
   - Change: `let cfg = config.services.ssh-agent` → `let cfg = config.services.desktop.ssh-agent`

4. **clan-service-modules/desktop/searxng.nix**
   - Change: `options.services.searxng.enable` → `options.services.desktop.searxng.enable`
   - Change: `let cfg = config.services.searxng` → `let cfg = config.services.desktop.searxng`

5. **clan-service-modules/desktop/pastebin.nix**
   - Change: `options.services.pastebin.enable` → `options.services.desktop.pastebin.enable`
   - Change: `let cfg = config.services.pastebin` → `let cfg = config.services.desktop.pastebin`

6. **modules/nixos/system/desktop-portals.nix**
   - Already correct: `options.desktop-portals.enable` (top-level config option)

7. **modules/Desktop-env/Noctalia/default.nix**
   - Already correct: `options.desktop.noctalia.enable` (nested)

8. **Service Modules to Group** (create nested structure):
   - `services.home-assistant-server` → `services.infrastructure.home-assistant`
   - `services.caddy-server` → `services.infrastructure.caddy`
   - `services.n8n-server` → `services.infrastructure.n8n`
   - `services.sillytavern-app` → `services.ai.sillytavern`
   - `services.llm-agents` → `services.ai.llm-agents`
   - `services.ai-services` → `services.ai.services`
   - `services.immich-server` → `services.media.immich`
   - `services.calibre-web-app` → `services.media.calibre-web`
   - `services.nextcloud-server` → `services.media.nextcloud`
   - `services-config.media-stack` → `services.media.stack`
   - `services.matrix-server` → `services.communication.matrix`
   - `services.mautrix-bridges` → `services.communication.mautrix-bridges`
   - `services-config.avahi` → `services.communication.avahi`
   - `services-config.monitoring` → `services.monitoring`
   - `services-config.homepage-dashboard` → `services.dashboard.homepage`

### Phase 2B: machines/z0r0/default.nix Transformation

**Target Structure**:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../modules ];  # Single auto-import

  # Hardware (unchanged)
  boot.initrd.luks.devices."crypted".device = "...";
  fileSystems = { ... };
  swapDevices = [ ... ];
  networking.hostName = "z0r0";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";

  # ALL FEATURES (nested attrsets)
  config = {
    nix-tools.enable = true;
    desktop-portals.enable = true;
    
    desktop = {
      noctalia = { enable = true; backend = "hyprland"; };
      dankmaterialshell.enable = false;
      omarchy.enable = false;
      caelestia.enable = false;
      illogical-impulse.enable = false;
    };
    
    programs = {
      yazelix.enable = true;
      keybind-cheatsheet.enable = true;
    };
    
    themes = {
      sddm-lain.enable = false;
      sddm-sel = { enable = true; variant = "shaders"; };
      grub-lain.enable = true;
      plymouth-hellonavi.enable = true;
    };
    
    mobile = {
      android.enable = true;
      ios.enable = true;
    };
    
    gaming.enable = true;
    virtualization.enable = true;
  };

  # System config (unchanged)
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";
  system-config.impermanence.enable = true;
  nix.settings = { cores = 4; max-jobs = 4; };

  # ALL SERVICES (nested attrsets)
  services = {
    desktop = {
      ssh-agent.enable = true;
      searxng.enable = false;
      pastebin.enable = false;
    };
    
    infrastructure = {
      home-assistant.enable = true;
      caddy.enable = true;
      n8n.enable = true;
    };
    
    ai = {
      sillytavern.enable = true;
      llm-agents.enable = true;
      services = {
        enable = true;
        open-webui.enable = true;
        localai.enable = true;
        chromadb.enable = true;
      };
    };
    
    media = {
      immich.enable = true;
      calibre-web.enable = true;
      nextcloud.enable = true;
      stack.enable = false;
    };
    
    communication = {
      matrix.enable = true;
      mautrix-bridges.enable = true;
      avahi.enable = true;
    };
    
    monitoring.enable = false;
    dashboard.homepage.enable = true;
    
    # Service fixes (temporary)
    aria2.rpcSecretFile = "/etc/aria2-rpc-token";
    deluge.authFile = "/etc/deluge-auth";
  };

  # Environment fixes (unchanged)
  environment.etc = { ... };
  
  # Security (unchanged)
  security.acme = { ... };
}
```

### Phase 2C: Propagate to Other Machines

**Files to Update**:
1. `machines/nami/default.nix` - Apply same dendritic pattern
2. `templates/machine/default.nix` - Update template
3. `templates/iso/default.nix` - Already has `config` parameter (fixed)

---

## STEP 4: EXECUTION SEQUENCE

### Sequence 1: Module Option Path Updates (5 files)
1. Update `modules/Home-Manager/yazi/yazelix.nix`
2. Update `modules/Home-Manager/tools/keybinds.nix`
3. Update `clan-service-modules/desktop/ssh-agent.nix`
4. Update `clan-service-modules/desktop/searxng.nix`
5. Update `clan-service-modules/desktop/pastebin.nix`

### Sequence 2: Service Module Grouping (12+ files)
Create nested service structure in existing service modules

### Sequence 3: machines/z0r0/default.nix Transformation
Transform to fully dendritic nested attrset structure

### Sequence 4: Propagation
Apply pattern to nami and templates

---

## VALIDATION COMMANDS

After each sequence:
```bash
nix flake check --show-trace
clan machines build z0r0 --show-trace
./scripts/clan-validate.sh
```

---

## SUMMARY

### ✅ Completed:
- Yazelix conflict audit: **NO CONFLICTS FOUND**
- Helix properly archived to `old/`
- Pattern violation analysis complete

### ⏳ Pending (Awaiting Approval):
- 17 module option path updates
- machines/z0r0/ nested attrset transformation
- Service grouping (infrastructure, ai, media, communication)
- Propagation to nami + templates

### 📊 Impact:
- **Files to modify**: 20+ (5 modules + z0r0 + nami + templates + 12 service modules)
- **Pattern**: Flat options → Nested attrsets
- **Benefit**: True dendritic structure (modules declare → machines enable)

---

**STOP**: Awaiting user approval before proceeding with unified diffs.
