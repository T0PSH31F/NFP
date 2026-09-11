# Layer 25: Data & Storage Services

This layer contains data persistence, database, backup, and directory synchronization modules for the NFP fleet.

## Modules

| Module Name | File | Description | Ports / Interfaces | Persistence / Storage |
|-------------|------|-------------|--------------------|-----------------------|
| **syncthing** | `syncthing.nix` | Peer-to-peer folder sync (`~/Clan`, `~/Projects`, `~/Notes`) | `22000/tcp`, `22000/udp`, `21027/udp` | `/var/lib/syncthing`, `~/.config/syncthing` |
| **restic-backups** | `restic-backups.nix` | Fleet backups using Restic + rclone (Google Drive + Teldrive) | N/A | `/var/cache/restic`, `/etc/restic` |
| **postgresql-vectordb**| `postgresql-vectordb.nix` | Native PostgreSQL + pgvector for RAG/memory | `5432/tcp` | `/var/lib/postgresql` |
| **chromadb** | `chromadb.nix` | Vector DB for local embedding indices | `8000/tcp` | `/var/lib/chromadb` |
| **qdrant** | `qdrant.nix` | High-performance vector database | `6333/tcp` | `/var/lib/qdrant` |
| **vaultwarden** | `vaultwarden.nix` | Bitwarden-compatible password manager | `8222/tcp` | `/var/lib/bitwarden_rs` |
| **filebrowser** | `filebrowser.nix` | Web-based file browser | `8080/tcp` | `/var/lib/filebrowser` |

## Usage Rules & Tags
- `syncthing`: Enabled via `workstation` (`z0r0`) and `pkb-node` (`luffy`) tags. Bound to Tailscale mesh.
- `restic-backups`: Enabled across fleet hosts via machine profiles. Runs daily back ups with automated restore drill CLI (`restic-restore-drill`).
