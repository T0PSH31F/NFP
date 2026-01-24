#!/usr/bin/env bash
set -e

echo "=== Clan Secrets Initialization ==="
echo ""

# Step 1: Check for existing age key
if [ -f ~/.config/sops/age/keys.txt ]; then
    echo "✓ Age key already exists at ~/.config/sops/age/keys.txt"
    echo ""
    echo "Your public key is:"
    grep "public key:" ~/.config/sops/age/keys.txt || age-keygen -y ~/.config/sops/age/keys.txt
else
    echo "Step 1: Generating age key..."
    mkdir -p ~/.config/sops/age
    nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
    echo ""
fi

# Extract the public key
PUBLIC_KEY=$(grep "public key:" ~/.config/sops/age/keys.txt 2>/dev/null | awk '{print $4}' || nix run nixpkgs#age -- -keygen -y ~/.config/sops/age/keys.txt 2>/dev/null)

if [ -z "$PUBLIC_KEY" ]; then
    # Alternative method to get public key
    PUBLIC_KEY=$(nix run nixpkgs#age -- -keygen -y ~/.config/sops/age/keys.txt 2>&1 | tail -1)
fi

echo ""
echo "Your age public key is:"
echo "$PUBLIC_KEY"
echo ""

# Step 2: Add user to clan secrets
echo "Step 2: Adding you as a clan secrets user..."
echo ""
echo "Run this command:"
echo "  clan secrets users add t0psh31f --age-key $PUBLIC_KEY"
echo ""
echo "Then run:"
echo "  clan vars generate"
echo ""
echo "=== Instructions ==="
echo "1. Copy the command above and run it"
echo "2. Then run 'clan vars generate'"
echo "3. Press Enter when prompted (to auto-generate passwords)"
