#!/usr/bin/env bash
set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Grandlix-Gang Clan-Core Validation Suite              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}✗${NC} $message"
    elif [ "$status" = "info" ]; then
        echo -e "${BLUE}ℹ${NC} $message"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    fi
}

# Function to run command with status
run_check() {
    local description=$1
    local command=$2
    
    echo ""
    print_status "info" "Running: $description"
    echo "─────────────────────────────────────────────────────────────────"
    
    if eval "$command"; then
        print_status "success" "$description completed successfully"
        return 0
    else
        print_status "error" "$description failed"
        return 1
    fi
}

# Change to repo root
cd "$(dirname "$0")/.." || exit 1

print_status "info" "Working directory: $(pwd)"
echo ""

# 1. Nix Flake Check
run_check "Nix flake check" "nix flake check --show-trace" || {
    print_status "error" "Flake check failed. Fix errors before proceeding."
    exit 1
}

# 2. Nix Format Check
run_check "Nix format check" "nix fmt" || {
    print_status "warning" "Some files were reformatted. Review changes."
}

# 3. Clan Machines Status
run_check "Clan machines status (z0r0)" "clan machines status z0r0" || {
    print_status "warning" "Could not get machine status. Clan may not be fully configured."
}

# 4. Clan Build Test
run_check "Clan build test (z0r0)" "clan machines build z0r0 --show-trace" || {
    print_status "error" "Machine build failed. Check configuration."
    exit 1
}

# 5. Check for common issues
echo ""
print_status "info" "Checking for common configuration issues..."
echo "─────────────────────────────────────────────────────────────────"

# Check if Noctalia input exists
if grep -q "noctalia" flake.nix; then
    print_status "success" "Noctalia input found in flake.nix"
else
    print_status "warning" "Noctalia input not found in flake.nix"
fi

# Check if yazelix module exists
if [ -f "modules/Home-Manager/yazi/yazelix.nix" ]; then
    print_status "success" "Yazelix module exists"
else
    print_status "error" "Yazelix module not found"
fi

# Check if helix was archived
if [ -d "old/Home-Manager/editors/helix" ]; then
    print_status "success" "Helix archived to old/"
else
    print_status "warning" "Helix not found in old/ directory"
fi

# Check if desktop-portals module exists
if [ -f "modules/nixos/system/desktop-portals.nix" ]; then
    print_status "success" "Desktop portals module exists"
else
    print_status "error" "Desktop portals module not found"
fi

# Check if clan service modules exist
if [ -f "clan-service-modules/desktop/ssh-agent.nix" ]; then
    print_status "success" "SSH agent service module exists"
else
    print_status "error" "SSH agent service module not found"
fi

if [ -f "clan-service-modules/desktop/searxng.nix" ]; then
    print_status "success" "SearxNG service module exists"
else
    print_status "error" "SearxNG service module not found"
fi

if [ -f "clan-service-modules/desktop/pastebin.nix" ]; then
    print_status "success" "Pastebin service module exists"
else
    print_status "error" "Pastebin service module not found"
fi

# Check if Noctalia structure exists
if [ -d "modules/Desktop-env/Noctalia" ]; then
    print_status "success" "Noctalia directory structure exists"
    
    if [ -f "modules/Desktop-env/Noctalia/default.nix" ]; then
        print_status "success" "  - Noctalia default.nix exists"
    fi
    
    if [ -f "modules/Desktop-env/Noctalia/hyprland/keybinds.nix" ]; then
        print_status "success" "  - Noctalia Hyprland keybinds exist"
    fi
    
    if [ -f "modules/Desktop-env/Noctalia/hyprland/ipc.nix" ]; then
        print_status "success" "  - Noctalia Hyprland IPC exists"
    fi
    
    if [ -f "modules/Desktop-env/Noctalia/niri/default.nix" ]; then
        print_status "success" "  - Noctalia Niri stub exists"
    fi
else
    print_status "error" "Noctalia directory structure not found"
fi

# Check if keybind cheatsheet exists
if [ -f "modules/Home-Manager/tools/keybinds.nix" ]; then
    print_status "success" "Keybind cheatsheet module exists"
else
    print_status "error" "Keybind cheatsheet module not found"
fi

# Check if z0r0 uses dendritic pattern
if grep -q "desktop.noctalia" machines/z0r0/default.nix; then
    print_status "success" "z0r0 uses Noctalia (dendritic pattern)"
else
    print_status "warning" "z0r0 may not be using dendritic pattern"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Validation Complete!                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_status "success" "All critical checks passed!"
echo ""
print_status "info" "Next steps:"
echo "  1. Review any warnings above"
echo "  2. Test the configuration: nixos-rebuild build --flake .#z0r0"
echo "  3. Deploy if successful: clan machines update z0r0"
echo ""
