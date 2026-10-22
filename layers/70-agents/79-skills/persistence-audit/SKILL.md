---
name: persistence-audit
description: Audit a service module for state loss under impermanence — write paths, persistence declarations, container mounts, image pinning.
---

# Persistence Audit

Use when a service loses state across rebuild/reboot, or before enabling any new stateful service.

1. Identify runtime write paths: read the module; for containers, `podman inspect` mount sources.
2. Every write path must be either (a) under a persisted `dataDir` bind-mount, or (b) in `environment.persistence."/persist"`.
3. The module must contain an `environment.persistence."/persist"` block; confirm the paths exist and match.
4. Ownership: persisted dir user/group/mode must match the container/service UID (`podman` rootless vs systemd unit user).
5. Images: digest-pinned (`@sha256:`), never `:latest`.
6. Prove it: write a sentinel through the app's UI, `systemctl restart` the unit (or container), and confirm data persists.
