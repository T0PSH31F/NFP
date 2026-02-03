#!/usr/bin/env bash
# Pre-build setup for persistence directories
# Part of Grandlix-Gang system refactoring

set -e

echo "🚀 Setting up persistence directories for Noctalia and libvirt..."

# Create Noctalia persistence directories
echo "📁 Creating Noctalia persistence directories..."
sudo mkdir -p /persist/home/t0psh31f/.local/share/noctalia
sudo mkdir -p /persist/home/t0psh31f/.cache/noctalia
sudo mkdir -p /persist/etc/libvirt

# Copy existing Noctalia data if it exists
if [ -d ~/.local/share/noctalia ]; then
  echo "📦 Copying existing Noctalia data..."
  sudo cp -rv ~/.local/share/noctalia/* /persist/home/t0psh31f/.local/share/noctalia/ 2>/dev/null || true
fi

if [ -d ~/.cache/noctalia ]; then
  echo "📦 Copying existing Noctalia cache..."
  sudo cp -rv ~/.cache/noctalia/* /persist/home/t0psh31f/.cache/noctalia/ 2>/dev/null || true
fi

# Fix ownership
echo "🔧 Fixing ownership..."
sudo chown -R t0psh31f:users /persist/home/t0psh31f/.local
sudo chown -R t0psh31f:users /persist/home/t0psh31f/.cache

# Verify
echo ""
echo "✅ Verifying directories..."
echo "---"
ls -la /persist/home/t0psh31f/.local/share/ | grep noctalia || echo "⚠️  .local/share/noctalia not found"
ls -la /persist/home/t0psh31f/.cache/ | grep noctalia || echo "⚠️  .cache/noctalia not found"
ls -la /persist/etc/ | grep libvirt || echo "⚠️  /etc/libvirt not found"
echo "---"
echo ""
echo "✅ Pre-build setup complete!"
echo ""
echo "Next steps:"
echo "  1. cd ~/Clan/Grandlix-Gang"
echo "  2. sudo nixos-rebuild dry-build --flake .#grandlixos"
echo "  3. sudo nixos-rebuild switch --flake .#grandlixos"
echo "  4. home-manager switch --flake .#t0psh31f@grandlixos"
