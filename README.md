# Grandlix-Gang NixOS Configuration

A Clan-core based NixOS configuration for the Grandlix-Gang with modular desktop environments.

## Quick Start

### 1. Load Development Environment

The project uses direnv for automatic environment loading. If you're getting "command not found" errors:

**One-time setup (if direnv isn't in your shell config):**

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
eval "$(direnv hook bash)"  # For bash
# OR
eval "$(direnv hook zsh)"   # For zsh
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

**Load the environment:**
```bash
cd /home/t0psh31f/Clan/Grandlix-Gang
direnv allow
```

**Manual activation (if direnv doesn't auto-load):**
```bash
eval "$(direnv export bash)"
# OR just use nix develop directly:
nix develop
```

### 2. Verify Tools Are Available

```bash
clan --version
which nixfmt
which statix
```

### 3. Generate SSH Keys

```bash
# Generate your SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "t0psh31f@grandlix.gang"

# Then manually add your public key to clan.nix:
# Edit the allowedKeys section in clan.nix
```

### 4. Deploy to Luffy

```bash
# Test the configuration
sudo nixos-rebuild test --flake .#luffy

# If everything works, switch to it
sudo nixos-rebuild switch --flake .#luffy
```

## Available Commands (in devshell)

- `clan` - Clan-core CLI for managing machines
- `nil` - Nix language server (for IDE)
- `nixfmt` - Format Nix code
- `deadnix` - Find unused Nix code
- `statix` - Nix linter
- `nix-search` - Search nixpkgs

## Configuration Structure

```
├── flake.nix              # Main flake (flake-parts based)
├── clan.nix               # Clan inventory
├── flake-parts/           # Dendritic module organization
│   ├── features/          # System and Home features
│   │   ├── nixos/         # NixOS modules (impermanence, etc.)
│   │   └── home/          # Home-Manager modules (hyprland, cli, etc.)
│   ├── services/          # Multi-host service definitions
│   └── hardware/          # Reusable hardware profiles
├── clan-services/         # Role-based service bundles
└── machines/
    ├── luffy/             # Primary laptop
    ├── z0r0/              # Workstation
    └── nami/              # Development server
```

Toggle in `machines/<name>/default.nix`:
- **Omarchy** - Hyprland with Material Design
- **Caelestia** - QuickShell based
- **Illogical Impulse** - End-4's Hyprland dotfiles

Only enable **one** at a time.

## CLI Environment

A comprehensive, portable terminal environment module that provides a complete CLI/TUI workflow.

### Features
- **Helix**: Modern modal editor with LSP support
- **Yazi**: Fast TUI file manager
- **Zellij**: Terminal multiplexer (yazelix-style)
- **Zsh**: Feature-rich shell with extensive configuration
- **Modern CLI Tools**: `eza`, `bat`, `ripgrep`, `fd`, `fzf`, `zoxide`, `delta`, etc.

### Usage
Enable in your machine config:
```nix
programs.cli-environment = {
  enable = true;
  enableYazelix = true;
};
```

**Key Bindings:**
- `Space + e` (in Helix) - Open Yazi file manager
- `Ctrl + F` (in Shell) - FZF directory jump
- `Ctrl + E` (in Shell) - FZF file search and edit
- `yazelix` (Command) - Start full environment in Zellij

## Documentation

See [walkthrough.md](file:///home/t0psh31f/.gemini/antigravity/brain/bfdd11d9-d09d-4aed-8516-c7b8f7469538/walkthrough.md) for complete deployment instructions.

## Troubleshooting

### "clan: command not found"

1. Make sure direnv is installed and hooked into your shell
2. Run `direnv allow` in the project directory
3. Or manually load with `eval "$(direnv export bash)"`
4. Or use `nix develop` directly

### Secrets/SSH setup

After generating SSH keys, update:
1. `clan.nix` - Add your public key to `allowedKeys`
2. `vars/per-machine/luffy/openssh/ssh.id_ed25519.pub/value` - Add your public key

## Development Environments

Development environments have been moved to a separate repository for reduced closure size:

**Repository**: [T0PSH31F/grandlix-devenvs](https://github.com/T0PSH31F/grandlix-devenvs)

### Quick Usage

```bash
# Python AI Agent environment
nix develop github:T0PSH31F/grandlix-devenvs#python-ai-agent

# Node automation environment
nix develop github:T0PSH31F/grandlix-devenvs#node-automation

# With direnv in your project
echo 'use flake github:T0PSH31F/grandlix-devenvs#python-ai-agent' > .envrc
direnv allow
```

See grandlix-devenvs repository for complete documentation.

- Clan Docs: https://docs.clan.lol
- NixOS Manual: https://nixos.org/manual/nixos/stable/
