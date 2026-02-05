# Development Environments

## Quick Start
### Option 1: Direct nix develop
```bash
# From anywhere
nix develop ~/Grandlix-Gang#python-ai-agent

# Or from repo
nix develop .#python-ai-agent
```
### Option 2: With direnv (Recommended)
```bash
# In your project directory
cd ~/projects/my-new-saas
echo 'use flake ~/Grandlix-Gang#python-ai-agent' > .envrc
direnv allow
# Environment loads automatically when you cd into the directory!
```

## Available Environments
| Environment | Command | Use Case |
|---|---|---|
| python-ai-agent | `nix develop .#python-ai-agent` | AI agents, LangChain, FastAPI |
| node-automation | `nix develop .#node-automation` | n8n, web scraping, automation |
| rust-saas | `nix develop .#rust-saas` | Rust backend services |
| go-microservice | `nix develop .#go-microservice` | Go microservices, gRPC |
| fullstack | `nix develop .#fullstack` | Combined stack |

## First-Time Setup
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

## Customizing Environments
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

## Tips
- **No local builds**: Everything uses binary cache
- **Services included**: PostgreSQL, Redis auto-start
- **Process management**: Built-in (see processes in each .nix)
- **Pre-commit hooks**: Automatic linting/formatting
- **Per-project configs**: Each project can have different Python versions, dependencies, etc.

## Troubleshooting
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
