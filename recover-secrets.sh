#!/usr/bin/env bash
set -e

echo "=== Clan Secrets Recovery ==="
echo ""
echo "This script will help you generate a new age key and reset your secrets."
echo "Since the old key is lost, previous secrets cannot be recovered."
echo ""

# Step 1: Generate new key
echo "Step 1: Checking for new key..."
mkdir -p ~/.config/sops/age
if [ ! -f ~/.config/sops/age/keys.txt ]; then
    nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
    echo "Generated new key at ~/.config/sops/age/keys.txt"
else
    echo "Key already exists at ~/.config/sops/age/keys.txt"
fi

PUBLIC_KEY=$(grep "public key:" ~/.config/sops/age/keys.txt | awk '{print $4}')
echo "Your Public Key: $PUBLIC_KEY"
echo ""

# Step 2: Add user to clan secrets
echo "Step 2: Resetting secrets configuration..."
echo ""
echo "Run the following commands manually:"
echo ""
echo "  1. Add yourself as a user:"
echo "     clan secrets users add t0psh31f --age-key $PUBLIC_KEY"
echo ""
echo "  2. Regenerate secrets (this will prompt for new values):"
echo "     clan vars generate"
echo ""
echo "  3. Update machine configuration:"
echo "     clan machines update z0r0"
echo ""
