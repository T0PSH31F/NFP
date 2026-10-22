---
name: nfp-module-authoring
description: How to add or modify a dendritic module in NFP — layer placement, auto-import, namespacing, persistence, secrets, docs.
---

# NFP Module Authoring

Use when creating or editing anything under `layers/`.

- Placement: services -> `layers/20-services/<group>/<name>.nix`; agents -> `layers/70-agents/<group>/<name>.nix`.
- Auto-Import: Drop file/directory in the target layer directory. `mkDendriticTree` automatically imports it. Name argument matches module file basename.
- Options: declare under `layers.layer-XX.<group>.<name>` (never new `services.ai-services` at top level).
- Enablement: Gate module logic with `lib.mkIf cfg.enable`. Tags act as data (`lib.mkIf (builtins.elem "tag" config.machine.tags)`). Tag defaults use `lib.mkDefault`.
- Desktop Experience: Gate desktop additions on `layers.desktop.experience` or `layers.desktop.compositor`.
- Wrap with `mkDendriticModule` per the layer's existing pattern; support dual NixOS/Home-Manager options if applicable.
- State: if the module has runtime state, add the `environment.persistence."/persist"` block matching user/group/mode.
- Secrets: clan `vars/` only. Never hardcode secrets.
- Firewall/ports: open ports in the module; record them in `layers/00-cyberia/01-docs/ports.md`.
- Done means: builds clean on target machine, docs updated, feature_list evidence recorded.
