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
├── flake.nix              # Main flake
├── clan.nix               # Clan inventory
├── modules/
│   ├── desktop/           # Desktop environments
│   ├── system/            # System modules
│   ├── users/             # User configs
│   └── home-manager/      # Home-manager modules
└── machines/
    ├── luffy/             # Primary laptop (192.168.1.182)
    └── z0r0/              # Secondary laptop (192.168.1.159)
```

## Desktop Environments

Toggle in `machines/<name>/default.nix`:
- **Omarchy** - Hyprland with Material Design
- **Caelestia** - QuickShell based
- **Illogical Impulse** - End-4's Hyprland dotfiles

Only enable **one** at a time.

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

### Quick Start

#### Option 1: Direct nix develop
```bash
# From anywhere
nix develop ~/Grandlix-Gang#python-ai-agent

# Or from repo
nix develop .#python-ai-agent
```

#### Option 2: With direnv (Recommended)
```bash
# In your project directory
cd ~/projects/my-new-saas
echo 'use flake ~/Grandlix-Gang#python-ai-agent' > .envrc
direnv allow
# Environment loads automatically when you cd into the directory!
```

### Available Environments

| Environment | Command | Use Case |
|---|---|---|
| python-ai-agent | `nix develop .#python-ai-agent` | AI agents, LangChain, FastAPI |
| node-automation | `nix develop .#node-automation` | n8n, web scraping, automation |
| rust-saas | `nix develop .#rust-saas` | Rust backend services |
| go-microservice | `nix develop .#go-microservice` | Go microservices, gRPC |
| fullstack | `nix develop .#fullstack` | Combined stack |

### First-Time Setup

Update flake lock:
```bash
cd ~/Grandlix-Gang
nix flake update
```

Test an environment:
```bash
nix develop .#python-ai-agent
```

Bootstrap a new project:
```bash
mkdir ~/projects/ai-telegram-bot
cd ~/projects/ai-telegram-bot
echo 'use flake ~/Grandlix-Gang#python-ai-agent' > .envrc
direnv allow

# Environment is now active!
python --version
poetry init
```

### Customizing Environments

Edit files in `~/Grandlix-Gang/devenvs/`:
- `python-ai-agent.nix` - Python environment
- `node-automation.nix` - Node/n8n environment
- `rust-saas.nix` - Rust environment
- `go-microservice.nix` - Go environment

After editing, reload with:
```bash
direnv reload  # If using direnv
# or
nix develop .#python-ai-agent  # Manual reload
```

### Tips

- **No local builds**: Everything uses binary cache
- **Services included**: PostgreSQL, Redis auto-start
- **Process management**: Built-in (see processes in each .nix)
- **Pre-commit hooks**: Automatic linting/formatting
- **Per-project configs**: Each project can have different Python versions, dependencies, etc.

### Dev Environment Troubleshooting

Environment not loading?
```bash
direnv reload
```

Need to update packages?
```bash
cd ~/Grandlix-Gang
nix flake update
```

Check what's in an environment:
```bash
nix flake show ~/Grandlix-Gang
```

## Support

- Clan Docs: https://docs.clan.lol
- NixOS Manual: https://nixos.org/manual/nixos/stable/
