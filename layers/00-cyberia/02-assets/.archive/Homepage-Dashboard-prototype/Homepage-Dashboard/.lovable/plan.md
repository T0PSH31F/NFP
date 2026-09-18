

# Grandlix × One Piece Cyberpunk Dashboard — Vegapunk Records Edition

An Egghead Island-inspired cyberpunk command center with 7 Straw Hat crew categories, Vegapunk satellite constellation for media services, and Brook as the Soul King of Lidarr. 30 services, zero duplicates, maximum eye-candy.

---

## Navbar — Straw Hat Command Bar
- Fixed glassmorphism header (72px) with backdrop blur
- Left: Red neon **Straw Hat Jolly Roger** (wireframe skull + straw hat + circuit-bone crossbones) with breathing pulse glow
- "GRANDLIX" in Orbitron font with red neon text-shadow
- Center: **Log Pose** compass element with slowly rotating needle (8s cycle)
- Den Den Mushi search bar with neon cyan focus glow
- Right: Settings gear, date/time, user avatar with neon ring
- Bottom stats bar: "🏴‍☠️ 30/30 CREW | 📡 7 SATELLITES | ⛵ 99.8% | 3:36 AM"
- Bottom border: animated neon gradient line

---

## Background & Atmosphere — Egghead Island
- Deep dark gradient (#0a0a1f → #1a0a2e)
- 3 fog layers with **Thousand Sunny** silhouette drifting (120s) and **Egghead Island dome** drifting opposite (90s) at 3-5% opacity
- Subtle animated grain texture (10% opacity)
- Floating particles: cyan/pink dots mixed with tiny Jolly Roger symbols
- Faint holographic grid lines pulsing subtly

---

## Category 1: 👑 Luffy's Command — Captain's Deck (Red #ff0055)
**Luffy silhouette header** (straw hat, fist raised) with Vivre Card section divider showing crew summary stats.

6 services:
- **Matrix Synapse** — Crew Transponder Network (฿ 8 CREW MEMBERS)
- **Mautrix Bridges** — Bridge Network (฿ 3/4 BRIDGES UP) with per-bridge status icons
- **Nextcloud** — Shared Treasure Vault (฿ 240GB CREW STORAGE) with usage progress bar
- **FileBrowser** — Ship's Log Navigator (฿ 84K ADVENTURE LOGS)
- **Immich** — Crew Photo Album (฿ 28.4K MEMORIES)
- **Glances** — Ship Status Monitor (฿ 99.2% CREW VITALS) with CPU/RAM/Net sparklines

---

## Category 2: ⚔️ Zoro's Armory — First Mate's Watch (Green #39ff14)
**Zoro silhouette header** (three-sword stance) with Vivre Card divider.

4 services:
- **Caddy** — Santoryu Navigation Routes (฿ 24 PATHS SECURED)
- **Headscale** — VPN Armory Network (฿ 6 BLADES CONNECTED) with triangle node visualization
- **AdGuard** — First Mate's Shield (฿ 18.2% THREATS SLASHED) with query sparkline
- **Portainer** — Container Armory (฿ 42/45 SHIPS READY) with warning badge for stopped containers

---

## Category 3: 🧭 Nami's Chart Room — Navigator's Station (Orange #ff9500)
**Nami silhouette header** (Clima-Tact staff) with Vivre Card divider.

2-3 services:
- **SearXNG** — Grand Line Map (฿ 124 ROUTES CHARTED) with Log Pose compass icon
- **Open-Meteo** — Weather Forecast (฿ WEATHER SURVEILLANCE) with Clima-Tact visualization showing current conditions

---

## Category 4: 🍳 Sanji's Galley — Chef's Kitchen (Yellow #ffd700)
**Sanji silhouette header** (cooking pose) with Vivre Card divider.

2 services:
- **Grocy** — Galley Inventory (฿ PANTRY MANAGED) with "All Blue Ingredients" subtitle
- **Mealie** — Recipe Collection (฿ XXX DISHES MASTERED) with "Black Leg Cuisine" badge

---

## Category 5: 🎵 Vegapunk Records — Satellite Network (Purple #bf00ff)
**Vegapunk Stella hologram header** with satellite constellation visual. This is the showcase section.

**Constellation Layout:** Stella (Jellyfin) in center as a holographic brain, 7 satellites arranged around it in a hexagonal pattern. Hovering a satellite draws a glowing connection line to Stella.

8 services with personality-based icons, color tints, and unique animations:
- **Jellyfin** (Stella — The Genius) — ฿ 12K RECORDS | Hologram brain icon, "The Original", "Now Broadcasting" indicator
- **Sonarr** (Shaka — Good) — ฿ 124 SERIES | Angel icon, soft angelic glow animation
- **Radarr** (Lilith — Evil) — ฿ 842 FILMS | Devil horns icon, flickering dark energy aura
- **Lidarr** (Brook — Soul King 💀🎵) — ฿ 3.4K SOUL ALBUMS | Skeleton with afro silhouette, floating musical notes (♪♫) around border, "Yohohoho!" speech bubble on click, bone-white + purple color, "45° Soul King" subtitle, Den Den Mushi wears tiny afro
- **Prowlarr** (Edison — Thinking) — ฿ 18/20 INDEXERS | Light bulb brain icon, flashing animation
- **Bazarr** (Pythagoras — Wisdom) — ฿ 95% SUBTITLED | Mathematical symbols orbiting, wisdom scroll icon
- **Overseerr** (York — Greed) — ฿ 8 REQUESTS | Money bag/treasure chest icon, coins spinning
- **Deluge** (Atlas — Violence) — ฿ 2.8 RATIO | Muscle icon, aggressive pulse animation, speed gauges

---

## Category 6: 📚 Robin's Library — Archaeologist's Archive (Teal #00d9ff)
**Robin silhouette header** (reading pose, crossed arms) with Vivre Card divider.

4 services:
- **Calibre-Web** — Ancient Poneglyphs (฿ 1.2K TEXTS) with stone tablet icon, "Ohara's Legacy"
- **Readarr** — Archaeological Discoveries (฿ 1.2K VOLUMES) with ancient scroll icon
- **Komga** — Manga Scrolls (฿ 2.8K ILLUSTRATED SCROLLS) with Ohara tree symbol
- **Pastebin** — Research Fragments (฿ 124 DISCOVERIES) with torn paper icon

---

## Category 7: 🩺 Chopper's Infirmary — Doctor's Office (Pink #ff00ff)
**Chopper silhouette header** (cute reindeer doctor) with Vivre Card divider.

3-4 services:
- **Prometheus** — Medical Scanner (฿ 24/24 PATIENTS STABLE) with X-ray icon
- **Grafana + Loki** — Medical Records (฿ 4.2K LOGS/MIN) with EKG sparkline
- **Harmonia** — Medicine Cache (฿ 94% EFFECTIVENESS) with pill bottle icon

---

## Service Card Design — Cyberpunk Wanted Posters
Every service card features:
- "WANTED" watermark text at 3% opacity, slightly rotated in background
- Glassmorphism panel with category-colored neon gradient border and shimmer sweep (3-4s)
- Torn/weathered edge effect via CSS clip-path with neon glow edges
- **Den Den Mushi** status indicator (SVG snail): green bobbing = online, orange pulsing with sweat drop = warning, gray closed eyes = offline
- Service icon (48px) with category-colored neon glow and subtle float animation
- Service name + One Piece subtitle (e.g., "Ancient Poneglyphs")
- Quick stats with bounty-style "฿" formatting
- "BOARD SHIP" / "LOGS" action buttons with gradient backgrounds
- Hover: lift 4px, intensify glow, brighten border 40% → 60%

---

## Animations & Effects
- **Entrance:** Staggered card fade-in (100ms delay), slide up 30px with scale 0.95 → 1
- **Continuous:** Den Den Mushi bobbing, border shimmer sweep, subtle card float (2-3px), Log Pose rotation, Jolly Roger pulse, Brook's floating musical notes
- **Hover:** Card lift + glow intensify, character-specific effects per category
- **Brook special:** Musical notes cascade upward on hover, "Yohohoho!" speech bubble on click
- **Satellite constellation:** Connection lines glow on hover, personality animations per satellite
- **Background:** Thousand Sunny + Egghead dome silhouettes drifting through fog, floating particles with occasional tiny Jolly Rogers

---

## Search & Filtering
- Den Den Mushi search bar filters all 30 services in real-time
- Filter dropdown by category (crew member) or status
- Non-matching cards fade out smoothly

---

## Responsive Design
- Desktop (>1200px): 4 columns, Vegapunk constellation layout, all effects
- Tablet (768-1200px): 2-3 columns, satellites in grid, reduced particles
- Mobile (<768px): Single column, hamburger menu, simplified animations, 44px touch targets

---

## Typography
- **Orbitron** — Headers and bounty values with neon text-shadow glow
- **Exo 2** — Service names and subtitles
- **Space Grotesk** — Body text and descriptions
- Letter-spacing 0.05em throughout

---

## Accessibility
- `prefers-reduced-motion` disables all continuous animations
- 4.5:1 contrast ratio on all text
- Keyboard navigation with visible neon focus rings
- Aria-labels on Den Den Mushi indicators, action buttons, and constellation elements

