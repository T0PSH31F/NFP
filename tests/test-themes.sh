#!/usr/bin/env bash
# Theme Configuration Tests
# Run this script on a deployed z0r0 machine to verify themes are working

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

passed=0
failed=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((passed++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((failed++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

echo "================================"
echo "Theme Configuration Tests"
echo "================================"
echo ""

# ============================================================================
# Plymouth Tests
# ============================================================================
echo "--- Plymouth Theme Tests ---"

# Test 1: Plymouth enabled
if grep -q "boot.plymouth.enable = true" /etc/nixos/configuration.nix 2>/dev/null || \
   [[ -f /etc/plymouth/plymouthd.conf ]]; then
    test_pass "Plymouth is enabled"
else
    test_fail "Plymouth is not enabled"
fi

# Test 2: Plymouth theme is hellonavi
if [[ -f /etc/plymouth/plymouthd.conf ]]; then
    if grep -qi "hellonavi" /etc/plymouth/plymouthd.conf; then
        test_pass "Plymouth theme is set to hellonavi"
    else
        test_fail "Plymouth theme is NOT hellonavi (check /etc/plymouth/plymouthd.conf)"
    fi
else
    test_warn "Cannot find Plymouth config file"
fi

# Test 3: Plymouth theme files exist
if [[ -d /run/current-system/sw/share/plymouth/themes/hellonavi ]] || \
   ls /nix/store/*plymouth-theme-hellonavi*/share/plymouth/themes/hellonavi &>/dev/null; then
    test_pass "HelloNavi Plymouth theme files exist"
else
    test_fail "HelloNavi Plymouth theme files NOT found"
fi

# Test 4: Kernel params include quiet and splash
if grep -q "quiet" /proc/cmdline && grep -q "splash" /proc/cmdline; then
    test_pass "Kernel params include 'quiet' and 'splash'"
else
    test_fail "Kernel params missing 'quiet' or 'splash' (check /proc/cmdline)"
fi

echo ""

# ============================================================================
# SDDM Tests
# ============================================================================
echo "--- SDDM Theme Tests ---"

# Test 5: SDDM service enabled
if systemctl is-enabled sddm.service &>/dev/null; then
    test_pass "SDDM service is enabled"
else
    test_fail "SDDM service is NOT enabled"
fi

# Test 6: SDDM theme is lain-wired
if grep -rq "lain-wired" /etc/sddm.conf.d/ 2>/dev/null || \
   grep -q "lain-wired" /etc/sddm.conf 2>/dev/null; then
    test_pass "SDDM theme is set to lain-wired"
else
    test_fail "SDDM theme is NOT lain-wired"
fi

# Test 7: SDDM lain theme files exist
if [[ -d /run/current-system/sw/share/sddm/themes/lain-wired ]] || \
   ls /nix/store/*sddm-lain-wired*/share/sddm/themes/lain-wired &>/dev/null; then
    test_pass "Lain SDDM theme files exist"
else
    test_fail "Lain SDDM theme files NOT found"
fi

# Test 8: SDDM wayland enabled
if grep -rq "wayland\|Wayland" /etc/sddm.conf.d/ 2>/dev/null || \
   [[ -f /etc/sddm.conf.d/wayland.conf ]]; then
    test_pass "SDDM Wayland support enabled"
else
    test_warn "SDDM Wayland config not found (may still work)"
fi

echo ""

# ============================================================================
# GRUB Tests
# ============================================================================
echo "--- GRUB Theme Tests ---"

# Test 9: GRUB theme configured
if [[ -f /boot/grub/themes/lain/theme.txt ]] || \
   ls /nix/store/*grub-lain*/grub/themes/*/theme.txt &>/dev/null; then
    test_pass "GRUB Lain theme files exist"
else
    test_warn "GRUB Lain theme files not found in expected location"
fi

echo ""

# ============================================================================
# SSH Host Key Tests
# ============================================================================
echo "--- SSH Host Key Persistence Tests ---"

# Test 10: SSH host keys exist
if [[ -f /etc/ssh/ssh_host_ed25519_key ]]; then
    test_pass "ED25519 SSH host key exists"
else
    test_fail "ED25519 SSH host key NOT found"
fi

if [[ -f /etc/ssh/ssh_host_rsa_key ]]; then
    test_pass "RSA SSH host key exists"
else
    test_fail "RSA SSH host key NOT found"
fi

# Test 11: SSH service running
if systemctl is-active sshd.service &>/dev/null; then
    test_pass "SSH service is running"
else
    test_fail "SSH service is NOT running"
fi

echo ""
echo "================================"
echo "Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
echo "================================"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
