---
description: Clan-first development practices and commands
---

# Clan-First Development Workflow

**Always prefer Clan CLI and patterns over raw NixOS commands.**

## Deployment Commands

```bash
# Deploy to a machine (PREFERRED)
clan machines update z0r0

# Deploy to all machines
clan machines update

# Generate vars/secrets
clan vars generate z0r0

# Check machine status
clan machines list
```

## DO NOT USE (unless debugging)
```bash
# Avoid these - use Clan equivalents instead
nixos-rebuild switch --flake .#z0r0
```

## Architecture Principles

1. **Inventory over imports**: Use `inventory.instances` with roles/tags, not direct module imports
2. **Vars over sops.secrets**: Use `clan.core.vars.generators` for secrets
3. **Service modules over raw config**: Create `clan-service-modules/` with `_class = "clan.service"`
4. **Tags for grouping**: Use machine tags (`all`, `desktop`, `server`) for service assignment

## Key Patterns

### Service Instance Example
```nix
inventory.instances.myservice = {
  module.name = "myservice";
  roles.server.machines.z0r0 = {};
  roles.client.tags = ["all"];
};
```

### Vars Generator Example
```nix
clan.core.vars.generators.mypassword = {
  prompts.password.description = "Enter password";
  prompts.password.type = "hidden";
  files.password.secret = true;
  script = "cat $prompts/password > $out/password";
};
```
