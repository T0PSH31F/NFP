# Garnix CI/CD Setup Guide for Grandline-Gang

## Overview

This document explains the Continuous Integration and Continuous Deployment (CI/CD) setup for the Grandline-Gang NixOS configuration repository using **Garnix** for automated builds and optional GitHub Actions for deployment.

## What is Garnix?

**Garnix** is a specialized CI/CD service for Nix projects that provides:

- **Automatic builds** of all NixOS configurations when you push to GitHub
- **Binary caching** to speed up builds
- **Build status badges** for your repository
- **Zero configuration** for basic use cases
- **Optional NixOS hosting** on Garnix infrastructure (not used in this setup)

The key advantage of Garnix is that it understands Nix flakes natively and requires minimal configuration.

## Current Setup

### 1. Garnix CI (Automatic Builds)

Garnix has been enabled for the repository and will automatically:

- Build the `luffy` NixOS configuration on every push
- Verify that the configuration is valid and builds successfully
- Cache build artifacts for faster subsequent builds
- Report build status on GitHub pull requests and commits

**Configuration file:** `garnix.yaml`

```yaml
builds:
  include:
    - "nixosConfigurations.*"
    - "homeConfigurations.*"
  exclude: []
  
incrementalizeBuilds: true
```

This configuration tells Garnix to:
- Build all NixOS configurations (currently just `luffy`)
- Build all Home Manager configurations (currently just `t0psh31f`)
- Use incremental builds for faster CI (only rebuild what changed)

### 2. GitHub Actions (Optional Deployment)

A GitHub Actions workflow has been created at `.github/workflows/deploy.yml` that can be enabled for automatic deployment.

**Current status:** The deployment steps are commented out by default for safety.

## How It Works

### Garnix Build Process

When you push commits to GitHub:

1. **Garnix detects the push** via GitHub webhook
2. **Garnix reads `garnix.yaml`** to determine what to build
3. **Garnix builds** all matching configurations (`nixosConfigurations.luffy`)
4. **Build results** are reported back to GitHub
5. **Artifacts are cached** in Garnix's binary cache

### Deployment Process (Manual)

Currently, deployment is manual and uses clan-core:

1. **Garnix builds** verify the configuration is valid
2. **You manually deploy** using one of these methods:
   - `clan machines update luffy`
   - `nixos-rebuild switch --flake .#luffy --target-host root@192.168.8.212`

### Deployment Process (Automatic - Optional)

If you enable the GitHub Actions deployment:

1. **Garnix builds** complete successfully
2. **GitHub Actions workflow** is triggered
3. **Workflow connects via SSH** to the luffy machine
4. **nixos-rebuild** deploys the new configuration
5. **System switches** to the new configuration

## Enabling Automatic Deployment

To enable automatic deployment via GitHub Actions:

### Step 1: Generate SSH Key for Deployment

On your local machine:

```bash
# Generate a dedicated SSH key for GitHub Actions
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_deploy -C "github-actions@grandline-gang"

# Copy the public key to luffy
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub root@192.168.8.212
```

### Step 2: Add SSH Private Key to GitHub Secrets

1. **Copy the private key:**
   ```bash
   cat ~/.ssh/github_actions_deploy
   ```

2. **Go to GitHub repository settings:**
   - Navigate to: `https://github.com/T0PSH31F/Grandline-Gang/settings/secrets/actions`
   - Click "New repository secret"
   - Name: `SSH_PRIVATE_KEY`
   - Value: Paste the entire private key (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)
   - Click "Add secret"

### Step 3: Uncomment Deployment Steps

Edit `.github/workflows/deploy.yml` and uncomment the deployment sections:

```yaml
- name: Setup SSH
  env:
    SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
  run: |
    mkdir -p ~/.ssh
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    ssh-keyscan -H 192.168.8.212 >> ~/.ssh/known_hosts

- name: Deploy to luffy
  run: |
    nix run nixpkgs#nixos-rebuild -- switch \
      --flake .#luffy \
      --target-host root@192.168.8.212 \
      --use-remote-sudo
```

### Step 4: Commit and Push

```bash
git add .github/workflows/deploy.yml
git commit -m "Enable automatic deployment via GitHub Actions"
git push
```

Now, every push to the `main` or `master` branch will:
1. Trigger Garnix builds
2. If builds succeed, trigger GitHub Actions deployment
3. Automatically deploy to the luffy machine

## Adding More Machines

When you add more machines in the future, the CI/CD will automatically adapt:

### Step 1: Add Machine Configuration

Create a new machine directory:

```bash
mkdir -p machines/newmachine
```

Add configuration files:
- `machines/newmachine/default.nix`
- `machines/newmachine/hardware-configuration.nix`

### Step 2: Update flake.nix

Add the new machine to the `clan.machines` section:

```nix
clan = {
  meta.name = "Grandline-Gang";
  meta.tld = "internal";

  machines = {
    "luffy" = {
      # ... existing config ...
    };
    
    "newmachine" = {
      imports = [
        ./machines/newmachine
        omarchy-nix.nixosModules.default
        home-manager.nixosModules.home-manager
      ];
      nixpkgs.hostPlatform = "x86_64-linux";
      clan.core.networking.targetHost = "root@<IP_ADDRESS>";
    };
  };
};
```

### Step 3: Garnix Automatically Builds It

Garnix will automatically detect and build `nixosConfigurations.newmachine` because the `garnix.yaml` includes `nixosConfigurations.*`.

### Step 4: Update GitHub Actions (Optional)

If using automatic deployment, add a deployment step for the new machine:

```yaml
- name: Deploy to newmachine
  run: |
    nix run nixpkgs#nixos-rebuild -- switch \
      --flake .#newmachine \
      --target-host root@<IP_ADDRESS> \
      --use-remote-sudo
```

## Monitoring Builds

### Garnix Dashboard

1. Visit: https://garnix.io/
2. Log in with your GitHub account
3. Navigate to the Grandline-Gang repository
4. View build status, logs, and history

### GitHub Checks

Build status appears directly on:
- Commit pages
- Pull request pages
- Repository main page

### Build Badges

You can add a Garnix build badge to your README:

```markdown
[![Garnix Build Status](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2FT0PSH31F%2FGrandline-Gang)](https://garnix.io)
```

## Troubleshooting

### Garnix Build Failures

If Garnix builds fail:

1. **Check the build logs** on the Garnix dashboard
2. **Test locally:**
   ```bash
   nix flake check
   nix build .#nixosConfigurations.luffy.config.system.build.toplevel
   ```
3. **Common issues:**
   - Syntax errors in Nix files
   - Missing or incorrect imports
   - Incompatible package versions
   - Network issues fetching dependencies

### GitHub Actions Deployment Failures

If automatic deployment fails:

1. **Check the Actions tab** on GitHub
2. **Verify SSH connectivity:**
   ```bash
   ssh root@192.168.8.212 echo "Connection successful"
   ```
3. **Check SSH key permissions:**
   - Ensure the private key is correctly added to GitHub Secrets
   - Verify the public key is in `/root/.ssh/authorized_keys` on luffy
4. **Check firewall:**
   - Ensure port 22 is open on luffy
   - Verify SSH service is running: `systemctl status sshd`

### Incremental Build Issues

If incremental builds cause problems:

1. **Disable incremental builds** in `garnix.yaml`:
   ```yaml
   incrementalizeBuilds: false
   ```
2. **Commit and push** the change

## Security Best Practices

### SSH Key Management

- **Use dedicated keys** for CI/CD (don't reuse personal keys)
- **Rotate keys regularly** (every 6-12 months)
- **Revoke old keys** when no longer needed
- **Use key passphrases** for additional security (note: GitHub Actions keys can't have passphrases)

### GitHub Secrets

- **Never commit secrets** to the repository
- **Use GitHub Secrets** for all sensitive data
- **Limit secret access** to specific workflows
- **Audit secret usage** regularly

### Deployment Safety

- **Test in staging** before deploying to production
- **Use branch protection** to require reviews before merging
- **Enable deployment approvals** for critical systems
- **Monitor deployments** and have rollback procedures

## Advanced Configuration

### Branch-Specific Builds

To only build on specific branches, update `garnix.yaml`:

```yaml
builds:
  - include:
      - "nixosConfigurations.*"
    branch: main
  
  - include:
      - "nixosConfigurations.*"
    branch: production
```

### Conditional Deployment

To deploy only from specific branches, update the GitHub Actions workflow:

```yaml
on:
  push:
    branches:
      - production  # Only deploy from production branch
```

### Multiple Deployment Targets

To deploy to multiple machines in parallel:

```yaml
jobs:
  deploy-luffy:
    runs-on: ubuntu-latest
    steps:
      # ... deploy to luffy ...
  
  deploy-newmachine:
    runs-on: ubuntu-latest
    steps:
      # ... deploy to newmachine ...
```

### Using Garnix Cache in Local Builds

To speed up local builds using Garnix's cache:

```bash
# Add Garnix cache to your Nix configuration
nix-shell -p cachix --run "cachix use garnix"

# Or add to ~/.config/nix/nix.conf:
substituters = https://cache.nixos.org https://garnix.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= garnix.cachix.org-1:VxHCvPfqhJvr3Yz8Qvx/gTxfVqzgJvZJvbqXQZRbDfY=
```

## Cost Considerations

### Garnix Pricing

- **Open source projects:** Free unlimited builds
- **Private repositories:** Check https://garnix.io/pricing for current plans
- **Bandwidth:** Included in all plans
- **Build time:** Generous limits on free tier

### GitHub Actions

- **Public repositories:** Free unlimited minutes
- **Private repositories:** 2,000 minutes/month free, then paid
- **Storage:** 500 MB free, then paid

## Summary

The Grandline-Gang repository now has a complete CI/CD pipeline:

1. **Garnix** automatically builds all NixOS configurations on every push
2. **GitHub Actions** can optionally deploy to machines automatically
3. **Binary caching** speeds up builds significantly
4. **Incremental builds** reduce build times
5. **Extensible** to support multiple machines easily

### Current Status

- ✅ Garnix CI enabled and configured
- ✅ `garnix.yaml` created with optimal settings
- ✅ GitHub Actions workflow created (deployment disabled by default)
- ⏸️ Automatic deployment disabled (enable when ready)

### Next Steps

1. **Fix SSH connectivity** to luffy machine (see SSH_TROUBLESHOOTING.md)
2. **Verify Garnix builds** are working on the dashboard
3. **Optionally enable** automatic deployment when ready
4. **Add more machines** as needed (CI/CD will automatically adapt)

## Additional Resources

- **Garnix Documentation:** https://garnix.io/docs
- **Garnix Blog:** https://garnix.io/blog
- **GitHub Actions Documentation:** https://docs.github.com/en/actions
- **Clan-core Deployment Guide:** https://docs.clan.lol
- **NixOS Manual:** https://nixos.org/manual/nixos/stable/

## Support

For issues or questions:

- **Garnix Support:** https://garnix.io/discord or https://garnix.io/matrix
- **GitHub Issues:** https://github.com/T0PSH31F/Grandline-Gang/issues
- **NixOS Discourse:** https://discourse.nixos.org/
