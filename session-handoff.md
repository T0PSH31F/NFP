# Session Handoff

## Last Session Accomplishments
1. **LoveLain Cyberia Guest Portal & Authenticated Launchpad**:
   - Designed and built a responsive, accessible single-page portal at [`layers/20-services/21-networking/portal/`](file:///home/t0psh31f/Clan/NFP/layers/20-services/21-networking/portal/) containing `index.html`, `style.css`, and `app.js`.
   - **Guest / Unauthenticated View**: Modern dark Cyberia aesthetic with Erik Wright (`t0psh31f`) bio & portfolio, facility overview, and prominent "Access Facility // Authenticate" CTA linking to `https://auth.lovelain.duckdns.org`.
   - **Member / Authenticated View**: Interrogates Authentik session API (`/api/v3/core/users/me/`) and unlocks the Member Launchpad featuring large interactive service cards for:
     - **Jellyfin Cinema**: `https://jellyfin.lovelain.duckdns.org`
     - **Audiobookshelf**: `https://audiobooks.lovelain.duckdns.org`
     - **Komga Comics & Manga**: `https://komga.lovelain.duckdns.org`
     - **Calibre-Web Literature**: `https://calibre.lovelain.duckdns.org`
     - **Navidrome & Feishin Hi-Fi**: `https://navidrome.lovelain.duckdns.org`
     - **SearXNG Metasearch**: `https://search.lovelain.duckdns.org`
   - **Evaluator Mode Toggle**: Interactive pill button allowing instantaneous preview switching between Guest View and Member View.
   - **Operator Subpath**: Caddy route `@internalDash path /dash*` preserves access to internal Homepage (:3007) while keeping the root domain purely for guests and members.

2. **Authentik Declarative Application Catalog Blueprint**:
   - In [`layers/20-services/21-networking/authentik.nix`](file:///home/t0psh31f/Clan/NFP/layers/20-services/21-networking/authentik.nix), provisioned `/etc/authentik/blueprints/media-suite.yaml` and wired container volume `/var/lib/authentik/blueprints:/blueprints/custom`.
   - Automatically populates Authentik's native User Library (`/if/user/#/library`) with all 6 media applications upon user sign-in.

## Verification Evidence
1. `./layers/00-cyberia/06-scripts/nfp-check.sh static`: Clean exit (code 0).
2. `./layers/00-cyberia/06-scripts/nfp-check.sh eval`: Evaluated all 3 machines (`z0r0`, `luffy`, `sanji`) remotely on builder `100.64.0.1` with exit code 0.
3. `nix build .#nixosConfigurations.luffy.config.layers.layer-20.services.networking.portal.package --no-link`: Built successfully in `/nix/store/7za2svc4ylc416sqbx0hfsnvk9g279p1-lovelain-cyberia-portal`.
4. `feature_list.json`: 243 lines (under 300 cap), feature `lovelain-guest-portal-and-authenticated-launchpad` marked `passing`.

## Live Fleet Deployment
When ready to deploy the portal live to the server:
```bash
clan machines update luffy
```
