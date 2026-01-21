<!-- Copilot instructions for AI coding agents in this repo -->
# Copilot instructions — Grandlix-Gang

Purpose: give an AI coding agent the minimal, high-value context to be productive in this Nix/Clan configuration repo.

- Big picture:
  - This repository is a flake-based NixOS configuration built around `clan` (Clan-core) for machine inventory + deployment. Key roots: `flake.nix`, `clan.nix`, `machines/`, `modules/`, `templates/`.
  - `machines/<name>/default.nix` is the per-machine entrypoint used to build and deploy a host. `templates/machine/` is the canonical starter template used for new machines.
  - `modules/` contains reusable NixOS / Home Manager modules (desktop, system, users, theming). Treat these as the primary place for feature logic.

- Typical developer workflows (commands you may run or suggest):
  - Enter dev environment: `direnv allow` (or `nix develop`). The repository relies on direnv for a devshell with tools like `clan`, `nixfmt`, `statix`.
  - Build image or VM: `nix build .#iso` or `nix build .#vm` or `nix build .#docker` (see `templates/README.md` examples).
  - Test a machine config locally: `nix build .#nixosConfigurations.<name>.config.system.build.toplevel` or `sudo nixos-rebuild test --flake .#<name>` on the target.
  - Deploy via Clan: `clan machines update <name>` or `clan machines install <name>`.
  - Lint/format: `nixfmt`, `statix`, `deadnix` are available in the devshell.

- Project-specific conventions and patterns:
  - One desktop per machine: each `machines/<name>/default.nix` selects exactly one desktop module (e.g. `Omarchy`, `Caelestia-shell`, `End-4`). Do not enable multiple desktop modules for the same machine.
  - Machine templates: to add a machine, `cp -r templates/machine machines/<new>` then edit `machines/<new>/default.nix` and add to `clan.nix` inventory.
  - Secrets: secrets and sops are stored under `sops/` and `secrets/` with per-machine values under `vars/per-machine/<host>/` and `sops/machines/<host>/`. Don’t hardcode secret values in modules.
  - Home-manager integration: dotfiles and user config are implemented under `modules/Home-Manager/` and wired into machine configs.

- Integration points and external dependencies:
  - Clan-core (`clan`) is the inventory and deployment tool — many operations use `clan` commands rather than ad-hoc scripts.
  - `nixos-generators` is used for building ISOs/VMs (`templates/README.md` shows examples like `nix build .#iso`).
  - Flake inputs are declared in `flake.nix`; update them with `nix flake update` when required.

- Patterns to follow when editing code:
  - Prefer adding new behavior as a module under `modules/` and export a small option set, then import that module into machine defaults.
  - Keep machine-specific overrides inside `machines/<name>/default.nix` or `vars/per-machine/<name>/`.
  - For theme/desktop changes, mirror patterns in `modules/Desktop-env/*` — these modules show how to wire Hyprland, IPC commands, and autostart hooks.
  - When proposing changes to deployment, reference the exact command to test: `sudo nixos-rebuild test --flake .#<machine>` or `clan machines update <name>`.

- Files to inspect when reasoning about behavior (most important):
  - `flake.nix`, `clan.nix` — flake interface and machine inventory
  - `machines/<name>/default.nix` — per-machine config used for builds and deploys
  - `templates/machine/default.nix` and `templates/README.md` — canonical machine/template usage
  - `modules/` — where system and desktop logic lives (see `modules/Desktop-env/*` and `modules/Home-Manager/`)
  - `sops/`, `secrets/`, `vars/per-machine/` — secret/value management

- Examples to show in suggestions (copyable):
  - Enter devshell: `cd /path/to/repo && direnv allow` (or `nix develop`)
  - Build a machine: `nix build .#nixosConfigurations.luffy.config.system.build.toplevel`
  - Test on machine `luffy`: `sudo nixos-rebuild test --flake .#luffy`

- What not to assume:
  - Do not assume a running SSH agent or unlocked keys — the README documents explicit SSH setup steps. Recommend `ssh-keygen` and adding public keys to `clan.nix` / `vars/per-machine/...`.
  - Do not assume a single desktop layout — confirm the machine's `default.nix` which desktop module is used.

- Files and locations where changes are commonly made:
  - `modules/Desktop-env/*` — desktop wiring and Hyprland integration
  - `modules/Home-Manager/` — user dotfiles and home packages
  - `templates/` — image and machine templates

- Quick reply guidance for PRs and edits:
  - When changing a module, include a short example `nix build` or `nixos-rebuild test` command to validate the change.
  - If a change touches secrets, point to the `sops/` or `vars/per-machine/` location and remind reviewers not to commit secrets.

If anything above is unclear or you want more detail for a specific change (e.g., how `clan` inventory maps to `machines/` entries, or examples of adding a module), tell me which area to expand and I will iterate.
