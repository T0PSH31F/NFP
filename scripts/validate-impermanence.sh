#!/usr/bin/env bash
# Validate Impermanence Persistence
# This script checks user configuration directories and warns about unpersisted files.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Impermanence Persistence Validator         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "This script checks for files in ~/.config and ~/.local/share that"
echo "are NOT in your persistence list and will be WIPED on reboot."
echo ""

# Get the list of persisted directories from the NixOS config (requires nix-instantiate or manual hardcoding for now)
# Since parsing nix output in bash is hard without jq/nix-json, we'll look for common patterns or just list what exists.

echo -e "${YELLOW}Checking ~/.config ...${NC}"
find ~/.config -maxdepth 1 -type d | sort | while read -r dir; do
    base=$(basename "$dir")
    if [[ "$base" == ".config" ]]; then continue; fi
    
    # Check if this directory is in our known persistence list (manual check based on current config)
    # This list must be kept in sync with impermanence.nix
    case "$base" in
        ghostty|sops|Signal|TelegramDesktop|Antigravity|mcp|Bitwarden|obs-studio|vesktop|discord|spicetify|kdeconnect|google-chrome|chromium)
            echo -e "${GREEN}✓ PERSISTED:${NC} .config/$base"
            ;;
        *)
            echo -e "${RED}⚠ WILL BE WIPED:${NC} .config/$base"
            ;;
    esac
done

echo ""
echo -e "${YELLOW}Checking ~/.local/share ...${NC}"
if [[ -d ~/.local/share ]]; then
    find ~/.local/share -maxdepth 1 -type d | sort | while read -r dir; do
        base=$(basename "$dir")
        if [[ "$base" == "share" ]]; then continue; fi
        
        # Check against persistence list
        case "$base" in
            icons|themes|cursors|applications|fonts|keyrings|kwalletd) 
                # Some of these might be re-generated or standard
                echo -e "${GREEN}✓ SAFE/STANDARD:${NC} .local/share/$base" 
                ;;
            Flatpaks|Appimages|Games|Notes)
                echo -e "${GREEN}✓ PERSISTED:${NC} .local/share/$base"
                ;;
            *)
                 echo -e "${RED}⚠ WILL BE WIPED:${NC} .local/share/$base"
                 ;;
        esac
    done
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "Review the ${RED}WIPED${NC} items above."
echo "If you need to keep them, add them to modules/nixos/impermanence.nix"
echo "and rebuild properly."
echo ""
