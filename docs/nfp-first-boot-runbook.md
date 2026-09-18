# NFP first-boot runbook

Use this the first time the full stack is up after a rebuild (nixarr + Caddy + Headscale + AdGuard + telemetry + restic). Do the sections **in order**. Later rebuilds skip wizards unless state was wiped.

Replace (NFP canonical values — do not use generic placeholders in committed docs):

- `{TAILNET}` — `nfp.nix` Headscale MagicDNS suffix (`layers.meta.tailnetDomain`, `headscale.nix` `base_domain = nfp.nix`)
- Public WAN — `lovelain.duckdns.org` via Caddy/ACME on luffy (`layers.meta.publicDomain`), **not** `{TAILNET}`
- `{LUFFY}` — `luffy.nfp.nix` (`100.64.0.3`, `layers.meta.fleetAddresses.luffy`) or `100.64.0.3` from `tailscale status`; Tailnet transport via WireGuard
- AdGuard — luffy `100.64.0.3:53` Tailnet + `192.168.1.54:53` LAN + `127.0.0.1:53` loopback, DoH/DoT upstream `https://dns.quad9.net`/`tls://dns.quad9.net` (Headscale `dns.nameservers.global`), luffy `--accept-dns=false` (loopback + bootstrap `9.9.9.9`) vs clients `--accept-dns=true`
- `{MEDIADIR}` — nixarr `mediaDir` (upstream default `/data/media`)
- `{URL}` — Tailnet via Caddy: `https://<service>.nfp.nix` (e.g. `https://jellyfin.nfp.nix`, `https://audiobookshelf.nfp.nix`) with `tls=headscale`; WAN via Caddy: `https://<service>.lovelain.duckdns.org`

On luffy, API keys:

```bash
sudo nixarr list-api-keys
```

Default ports if you are not using Caddy names yet:

| Service | Port |
|---|---|
| Homepage | 8082 (confirm in `homepage-dashboard.nix`) |
| Grafana | 3000 |
| AdGuard Home | 3000 (if conflict, use the port in `adguard.nix`) |
| Jellyfin | 8096 |
| Seerr | 5055 |
| Sonarr | 8989 |
| Radarr | 7878 |
| Lidarr | 8686 |
| Readarr | 8787 |
| Prowlarr | 9696 |
| Bazarr | 6767 |
| SABnzbd | 8080 |
| Audiobookshelf | 13378 |
| Autobrr | 7474 |
| Komga | 25600 |
| Calibre-web | 8083 |
| ntfy | from `ntfy-sh.nix` |

# 0. Prove the box is actually up

On **luffy** (console or SSH):

1. `systemctl is-system-running` — should be `running` or `degraded` with a known leftover, not `starting`.
2. `tailscale status` — luffy, z0r0, nami should appear once those hosts are up.
3. Confirm media disk is mounted and `{MEDIADIR}` exists and is **root-owned**:

   ```bash
   ls -ld {MEDIADIR} {MEDIADIR}/library
   ls /data/.state/nixarr   # or your nixarr.stateDir
   ```

4. If this is a **blank** library, create the trees Jellyfin/*Arrs expect (nixarr default layout):

   ```bash
   sudo mkdir -p {MEDIADIR}/library/{movies,shows,music,books,audiobooks}
   sudo mkdir -p {MEDIADIR}/sabnzbd/{incomplete,complete}/{radarr,sonarr,lidarr,readarr}
   ```

   Do not use the download folder as a library root.

5. `journalctl -u nixarr-jellyfin -u caddy -u tailscaled --since "10 min ago"` — no crash loops.

You need a browser **on the tailnet** (luffy desktop, z0r0, or phone with Headscale already connected). If this is truly first boot and the phone is not on Headscale yet, do section 1 from luffy’s local browser using `{LUFFY}` IPs.

# 1. Headscale + AdGuard + phone

## 1.1 Headscale is the door

1. Confirm Headscale is healthy (wherever it runs in NFP — often luffy or a VPS).
2. On each NixOS machine: `tailscale status` shows connected to **your** login server, not `controlplane.tailscale.com`.
3. If a machine is missing:

   ```bash
   sudo tailscale up --login-server https://<your-headscale-url> --accept-dns=true
   ```

   Approve/register the node (`headscale nodes list` / `headscale nodes register`) as you already do for Clan.

## 1.2 AdGuard first-run (once)

1. Open AdGuard Home UI (`https://adguard.{TAILNET}` or the port in `adguard.nix`).
2. Complete the wizard: admin user, listen on the **Headscale IP** (and localhost). Do not listen on `0.0.0.0` WAN.
3. Enable DoH/DoT if the module did not already.
4. Add blocklists you want. Keep upstream DNS as encrypted DoH/DoT.

On the **AdGuard host**, Tailscale must **not** steal DNS in a loop:

```bash
sudo tailscale up --login-server https://<headscale> --accept-dns=false
```

## 1.3 Push AdGuard to every client

In Headscale DNS config (UI or `dns.nameservers.global`):

- Nameserver = luffy’s **tailnet IPv4** (the AdGuard listener).
- Override local DNS / split DNS so MagicDNS still resolves `{TAILNET}` names.
- Clients: `--accept-dns=true` (except the AdGuard machine).

Linux check: `resolvectl status` (or `tailscale dns status`) shows AdGuard’s `100.x` for non-MagicDNS queries.

## 1.4 Phone

1. Install official Tailscale app (Play / App Store / F-Droid).
2. **Android:** Accounts → ⋮ → **Use an alternate server** → paste Headscale URL → log in → register node.
3. **iOS:** account → log in → **Use custom coordination server**.
4. Turn the VPN switch **on**.
5. **Android:** set Private DNS to **Off**. Tailscale DNS and Android Private DNS fight; Headscale should be pushing AdGuard. [web:188]
6. Toggle VPN off/on once after Headscale DNS change.
7. Test: `https://homepage.{TAILNET}` or `http://{LUFFY}:8082` loads.

Until Headscale is up, **no** media URL on the phone will work. That is intended (no WAN).

# 2. Observability (so later failures are visible)

## 2.1 Homepage

Open Homepage. You should see tiles for the services. If tiles 401, that is normal until each app has an admin user and you paste API keys into Homepage widgets (or sops). Bookmark Homepage; use it as the map.

## 2.2 Grafana + telemetry

1. Open Grafana.
2. **Change the admin password immediately** (default is often `admin` / `admin` if telemetry created it). Prefer the sops password if NFP already set one.
3. Check datasources: Prometheus and Loki. If telemetry auto-wired them, Explore → Prometheus `up` should show luffy (and later z0r0/nami).
4. Explore Loki: `{host="luffy"}` or equivalent should return journal lines.
5. Confirm nixarr exporters later (`exportarr` ports 9707–9711). If Prometheus is empty, keep going; scrape config can wait until *Arrs have API keys.

## 2.3 ntfy

1. Open ntfy UI, create the topic your `alertmanager-ntfy.nix` expects (or confirm it already exists).
2. Install ntfy on the phone (F-Droid/Play), subscribe to that topic **over Headscale**.
3. Send a test: `curl -d "nfp test" http://{LUFFY}:<ntfy-port>/homelab`

# 3. Jellyfin (do this before Seerr)

1. Open `{URL}:8096`.
2. Create the **admin** account. Store it in Vaultwarden.
3. Add libraries (content type → folder). Nixarr defaults: [web:155]

   | Type | Folder |
   |---|---|
   | Movies | `{MEDIADIR}/library/movies` |
   | TV | `{MEDIADIR}/library/shows` |
   | Music | `{MEDIADIR}/library/music` |
   | Books | `{MEDIADIR}/library/books` |

4. Metadata: TheMovieDb / MusicBrainz / TheAudioDB. Language = yours.
5. Networking: leave public ports alone. Remote access = Headscale only. Disable UPnP if the wizard offers it.
6. Dashboard → Scheduled Tasks: for a small library, reduce scan interval if you want.
7. Play one file locally. Note the LAN vs tailnet URL; phone will use the Caddy/Headscale URL.

**Phone:** Symfonium → add server **Jellyfin** → `https://jellyfin.{TAILNET}` → same admin (or a dedicated user). Transcode Opus on cellular. Pin albums for offline.

# 4. SABnzbd (download client before *Arrs)

1. Open `{URL}:8080`.
2. Wizard: language, then **Usenet provider** host/port/SSL/user/pass (from your existing provider + sops; do not put them in git).
3. Categories matching *Arrs: `radarr`, `sonarr`, `lidarr`, `readarr` (and `tv`/`movies` if you prefer those names — then use the same strings in *Arr download-client settings).
4. Incomplete / complete folders must be **inside** `{MEDIADIR}` (or nixarr’s sab paths), **not** the library folders.
5. Copy the API key (Config → General). `sudo nixarr list-api-keys` may already show it.

If nixarr `settings-sync` already injected SABnzbd into Sonarr/Radarr, skip adding the client by hand in those apps; still **test** a connection.

# 5. Prowlarr, then the *Arrs

Servarr rule: Prowlarr owns indexers. *Arrs own libraries. Download client is SABnzbd. [web:178][web:155]

## 5.1 Prowlarr (`:9696`)

1. Auth method **Forms**, username/password.
2. Settings → Apps: add Sonarr, Radarr, Lidarr (and Readarr if kept). Sync API keys via `sudo nixarr list-api-keys` or enable `nixarr.prowlarr.settings-sync.enable-nixarr-apps`.
3. Add **your** indexer accounts (API keys you already have). Test each.
4. Sync App Indexers so they appear in Sonarr/Radarr/Lidarr.

## 5.2 Shared *Arr settings (Sonarr 8989, Radarr 7878, Lidarr 8686, Readarr 8787)

For **each** app, first boot:

1. Forms auth, username/password (or SSO later — not day one).
2. Settings → Media Management → Show Advanced:
   - Enable **Rename**
   - **Use Hardlinks instead of Copy**
   - `chmod Folder` = `775`
   - Unmonitor deleted items
3. Root folders (nixarr defaults): [web:155]

   | App | Root folder |
   |---|---|
   | Radarr | `{MEDIADIR}/library/movies/` |
   | Sonarr | `{MEDIADIR}/library/shows/` |
   | Lidarr | `{MEDIADIR}/library/music/` |
   | Readarr | `{MEDIADIR}/library/books/` |

   Library folder ≠ download folder.

4. Download clients → SABnzbd, host `127.0.0.1`, port `8080`, category = app name, API key from step 4. Test.
5. Quality profiles: pick one you actually want; leave TRaSH/Recyclarr to the next step.
6. **Import existing library** (Add → Import): only for already-organized folders. Review matches before confirm. Lidarr will fail or mis-match if tags/names are garbage — run Picard/Beets on music **before** a bulk Lidarr import.

## 5.3 Recyclarr

If `nixarr.recyclarr.enable` is on with a config, it is a **timer**, not a wizard.

```bash
sudo systemctl status recyclarr.timer
sudo recyclarr sync   # or the nixarr wrapper
```

If it errors on missing API keys, put Sonarr/Radarr keys in the sops/recyclarr secrets the module expects, then sync again.

## 5.4 Bazarr (`:6767`)

1. Settings → Languages: add spoken languages, create a profile, set as default for Series and Movies. [web:155]
2. Settings → Sonarr / Radarr: URL `http://127.0.0.1:8989` / `:7878`, API keys from `nixarr list-api-keys`. Test + Save. Skip if `nixarr.bazarr.settings-sync` already did this.
3. Settings → Providers: enable subtitle providers you have accounts for.
4. Optional: automatic audio sync; unmonitor deleted subtitles.

## 5.5 Seerr (`:5055`) — after Jellyfin + Radarr + Sonarr

1. Choose **Jellyfin** (not Plex).
2. Jellyfin URL: `http://127.0.0.1:8096` from luffy, or the Caddy name if Seerr is not on the same host.
3. Jellyfin admin user/password. Dummy email is fine. [web:155]
4. Sync Libraries → enable Movies and Shows → Next.
5. Add Radarr + Sonarr. API keys: `sudo nixarr list-api-keys`. Default 4K vs SD: pick one server each unless you built two.
6. Create a **non-admin** Seerr user for the phone if others will request titles.

Phone: Seerr URL over Headscale; sign in; request a test movie and watch it appear in Radarr.

# 6. Music, books, audiobooks

## 6.1 Lidarr

Already has root folder + SABnzbd from §5. Then:

1. Metadata: MusicBrainz.
2. Import `{MEDIADIR}/library/music` only after tags/names look like `Artist/Album/track`.
3. One manual album search as a smoke test (you should see indexers from Prowlarr).

Jellyfin music library should point at the **same** folder. Symfonium stays on Jellyfin, not Lidarr.

## 6.2 Audiobookshelf (`:13378`)

1. Create admin.
2. Add library type Audiobooks → `{MEDIADIR}/library/audiobooks` (or the path you actually use).
3. Optional podcasts library.
4. Create a phone user. App: Audiobookshelf official client, server `https://audiobookshelf.{TAILNET}`.

Do not also add that folder as a Jellyfin “books” library if you want progress to live in ABS only.

## 6.3 Shelfmark

1. Open its Homepage tile / nixarr port.
2. Create admin.
3. Point at `{MEDIADIR}/library/books` **or** a dedicated comics/books path if you kept Komga/Calibre for that.
4. If Komga or Calibre-web already owns comics/ebooks, pick **one** canonical app per format to avoid double-scans.

## 6.4 Keepers (if still enabled)

- **Calibre-web:** default login is often `admin`/`admin123` until you change it — change immediately, point at the Calibre library path.
- **Komga:** create admin, add comics/manga series folder, scan.
- **RomM:** admin, library path for ROMs, metadata providers if you use them.
- **Readarr:** same *Arr ritual as §5.2, root `{MEDIADIR}/library/books`. Do not overlap Shelfmark/Calibre on the same files unless you accept duplicate management.

# 7. Autobrr + Anchorr

## 7.1 Autobrr (`:7474`)

1. First visit creates the admin user.
2. Settings → IRC/indexers: add **your** tracker/IRC credentials (sops, not wiki).
3. Add a download client: SABnzbd (usenet) and/or the torrent client if you enabled one.
4. Filters later; day one is “can login + client test succeeds”.

## 7.2 Anchorr

Discord bot. No useful UI until the token is valid.

1. Confirm the bot token is in sops and the unit is up: `systemctl status nixarr-anchorr` (name may differ).
2. Invite the bot to your Discord with the permissions the project docs require.
3. In Discord, run the bot’s setup / link Seerr if that is the integration you enabled.
4. Test a request from Discord → Seerr → Radarr.

# 8. Backups (USB + GCS)

Do this **after** the apps have created their databases.

1. Plug in the 2TB. Confirm UUID mount (the restic unit should `RequiresMountsFor=` that path).
2. If restic repos are not initialized:

   ```bash
   sudo restic -r /mnt/<usb-repo> snapshots
   sudo restic -r rclone:gcs:<bucket> snapshots
   ```

   If “no such config”, run the init your `restic-backups.nix` documents (password from sops). Never commit the password.

3. Start one job:

   ```bash
   sudo systemctl start restic-backups-<name>
   journalctl -u restic-backups-<name> -e
   ```

4. Confirm a snapshot on **both** USB and GCS.
5. Unplug test: job should **fail**, not write to `/`.
6. Optional restore drill: restore one SQLite/Postgres dump to `/tmp` and discard.

Media library: USB yes if it fits; GCS usually **state + DBs only**.

# 9. Homepage widgets and a full-path smoke test

1. Paste API keys into Homepage widgets (Jellyfin, *Arrs, SABnzbd, Prowlarr) or rely on sops-generated widgets.
2. End-to-end (TV or movie):
   - Phone on Headscale → Seerr request → Radarr/Sonarr grabs via Prowlarr → SABnzbd completes → file appears under `{MEDIADIR}/library/...` → Jellyfin scan/plays → Bazarr may fetch subs.
3. Music: play from Symfonium over Headscale; skip/pause works; offline pin works on Wi-Fi then airplane mode.
4. Grafana: request/download shows up on exportarr dashboards within a few minutes.
5. ntfy: optional *Arr connect to ntfy or rely on Alertmanager only.

# 10. Security pass (same day)

- Every wizard admin password is in Vaultwarden, not a text file in the repo.
- No UPnP, no “open to internet”, no Jellyfin public ports.
- `ss -lntp` on luffy: app ports on `127.0.0.1` or tailnet, not `0.0.0.0` except Headscale/Caddy as designed.
- Grafana password changed.
- Calibre-web default password changed.
- Phone cannot load Homepage with Headscale **off**.
- AdGuard query log shows z0r0, nami, and the phone.

# After a later rebuild

If `/data/.state/nixarr` and restic persist:

- Skip all wizards.
- `tailscale status`, AdGuard, Homepage, play one title.
- If impermanence ate state, restore restic **stateDir + DBs** first, then start units.

# If something 404s / connection refused

1. `systemctl list-units --failed`
2. Wrong URL: try `{LUFFY}:port` vs Caddy name.
3. *Arr “cannot access folder”: permissions on `{MEDIADIR}` (root-owned, `mediaUsers` includes you, chmod 775 as set).
4. Seerr cannot see Jellyfin: use `http://127.0.0.1:8096` not the public name if they share luffy.
5. Phone DNS broken: disable Android Private DNS, `--accept-dns=true`, AdGuard host `--accept-dns=false`.
6. Duplicate *Arrs: old nixpkgs `services.sonarr` still enabled next to nixarr — disable the old modules.
