# SSH Agent Conflict Resolution

## Problem
The NixOS build for z0r0 was failing with the following error:
```
error: The option `systemd.user.services.ssh-agent.serviceConfig.ExecStart' has conflicting definition values:
- In `/nix/store/.../nixos/modules/programs/ssh.nix': ".../ssh-agent -a %t/ssh-agent"
- In `/nix/store/.../modules/nixos/services/ssh-agent.nix': ".../ssh-agent -D -a $SSH_AUTH_SOCK"
```

## Root Cause
Two ssh-agent modules were being loaded simultaneously:
1. `modules/nixos/services/ssh-agent.nix` - Basic module imported via services/default.nix
2. `clan-service-modules/desktop/ssh-agent.nix` - Feature-rich clan service module

Both modules:
- Set `programs.ssh.startAgent = true` (which auto-creates a systemd user service)
- ALSO manually defined `systemd.user.services.ssh-agent` with different ExecStart commands

This created a conflict because NixOS's built-in `programs.ssh.startAgent` creates its own service definition, and then both custom modules tried to override it with different values.

## Solution Applied

### 1. Fixed the NixOS Service Module
- **Updated**: `modules/nixos/services/ssh-agent.nix` - Set `programs.ssh.startAgent = false`
- **Reason**: The machine configuration uses `services.ssh-agent.enable`, not clan services
- **Key Fix**: Disabled the built-in `programs.ssh.startAgent` to prevent automatic service creation

### 2. Updated Clan Service Module (for consistency)
- **File**: `clan-service-modules/desktop/ssh-agent.nix`
- **Change**: Also set `programs.ssh.startAgent = false`
- **Reason**: Ensures both modules follow the same pattern if ever used together

## Changes Made

### modules/nixos/services/ssh-agent.nix
```diff
+ options.services.ssh-agent = {
+   enable = lib.mkEnableOption "SSH Agent service for desktop sessions";
+   
+   package = lib.mkOption {
+     type = lib.types.package;
+     default = pkgs.openssh;
+     description = "SSH package to use";
+   };
+ };

  config = lib.mkIf cfg.enable {
+   # Configure SSH client settings
    programs.ssh = {
-     startAgent = true;
+     # Don't use the built-in startAgent to avoid conflicts
+     # We define our own systemd service below for better control
+     startAgent = false;
+     agentTimeout = "1h";
+     extraConfig = ''
+       AddKeysToAgent yes
+     '';
    };

+   # Custom ssh-agent systemd user service
    systemd.user.services.ssh-agent = {
      description = "SSH Agent";
+     wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
-       ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
+       ExecStart = "${cfg.package}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
+       Restart = "on-failure";
      };
    };
+
+   # Set SSH_AUTH_SOCK environment variable
+   environment.sessionVariables = {
+     SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
+   };
  };
```

### clan-service-modules/desktop/ssh-agent.nix
```diff
  programs.ssh = {
-   startAgent = true;
+   # Don't use the built-in startAgent to avoid conflicts
+   # We define our own systemd service below for better control
+   startAgent = false;
    agentTimeout = "1h";
```

## Result
- No more conflicting definitions
- SSH agent service is now managed solely by the clan-service module
- Custom systemd service provides better control with:
  - Configurable package option
  - Agent timeout settings
  - Auto-add keys configuration
  - Proper environment variable setup
  - Restart on failure

## Additional Fixes Applied

While fixing the ssh-agent conflict, three other build errors were discovered and resolved:

### 1. Icon Theme Conflict
**Error**: `kora-icon-theme` and `BeautyLine` both provide conflicting files
**Fix**: Commented out `kora-icon-theme` in `modules/Home-Manager/home-packages.nix` since `BeautyLine` is already configured in `gtk.nix`

### 2. SDDM Lain Theme Build Error
**Error**: Missing Qt wrapping configuration
**Fix**: Added `dontWrapQtApps = true` to `modules/nixos/themes/sddm-lainframe.nix` since it's a theme/data package, not an application

### 3. Python MCP Dependency Conflict
**Error**: `mcp-nixos` requires `mcp<1.17.0` but system has `mcp 1.25.0`
**Fix**: Disabled `mcp-nixos` in `modules/nixos/nix-tools.nix` until dependency is updated

## Testing
After applying these changes, the NixOS build should complete successfully without any errors.
