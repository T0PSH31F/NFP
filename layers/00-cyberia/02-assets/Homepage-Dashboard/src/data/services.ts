export type ServiceStatus = 'online' | 'warning' | 'offline';

export type CrewMember = 'luffy' | 'zoro' | 'nami' | 'sanji' | 'vegapunk' | 'robin' | 'chopper';

export type SatellitePersonality = 'stella' | 'shaka' | 'lilith' | 'brook' | 'edison' | 'pythagoras' | 'york' | 'atlas';

export interface Service {
  id: string;
  name: string;
  subtitle: string;
  bountyLabel: string;
  status: ServiceStatus;
  url: string;
  category: CrewMember;
  satellite?: SatellitePersonality;
  stats?: Record<string, string>;
  icon: string; // lucide icon name
}

export interface Category {
  id: CrewMember;
  name: string;
  subtitle: string;
  emoji: string;
  colorClass: string;
  neonClass: string;
  services: Service[];
}

const services: Service[] = [
  // === LUFFY'S COMMAND ===
  { id: 'matrix', name: 'Matrix Synapse', subtitle: 'Crew Transponder Network', bountyLabel: '฿ 8 CREW MEMBERS', status: 'online', url: '#', category: 'luffy', icon: 'MessagesSquare', stats: { rooms: '34', 'msg/day': '420' } },
  { id: 'mautrix', name: 'Mautrix Bridges', subtitle: 'Bridge Network', bountyLabel: '฿ 3/4 BRIDGES UP', status: 'warning', url: '#', category: 'luffy', icon: 'Network', stats: { WA: '✅', TG: '✅', DC: '✅', SG: '⚠️' } },
  { id: 'nextcloud', name: 'Nextcloud', subtitle: 'Shared Treasure Vault', bountyLabel: '฿ 240GB CREW STORAGE', status: 'online', url: '#', category: 'luffy', icon: 'Cloud', stats: { used: '240GB', total: '2TB', users: '4' } },
  { id: 'filebrowser', name: 'FileBrowser', subtitle: "Ship's Log Navigator", bountyLabel: '฿ 84K ADVENTURE LOGS', status: 'online', url: '#', category: 'luffy', icon: 'FolderOpen', stats: { dirs: '8.2k', size: '1.2TB' } },
  { id: 'immich', name: 'Immich', subtitle: 'Crew Photo Album', bountyLabel: '฿ 28.4K MEMORIES', status: 'online', url: '#', category: 'luffy', icon: 'Camera', stats: { videos: '840', albums: '42' } },
  { id: 'glances', name: 'Glances', subtitle: 'Ship Status Monitor', bountyLabel: '฿ 99.2% CREW VITALS', status: 'online', url: '#', category: 'luffy', icon: 'Activity', stats: { CPU: '45%', RAM: '18GB', Net: '↓45MB/s' } },

  // === ZORO'S ARMORY ===
  { id: 'caddy', name: 'Caddy', subtitle: 'Santoryu Navigation Routes', bountyLabel: '฿ 24 PATHS SECURED', status: 'online', url: '#', category: 'zoro', icon: 'Route', stats: { routes: '24', uptime: '99.9%' } },
  { id: 'headscale', name: 'Headscale', subtitle: 'VPN Armory Network', bountyLabel: '฿ 6 BLADES CONNECTED', status: 'online', url: '#', category: 'zoro', icon: 'Shield', stats: { nodes: '6', routes: '18' } },
  { id: 'adguard', name: 'AdGuard', subtitle: "First Mate's Shield", bountyLabel: '฿ 18.2% THREATS SLASHED', status: 'online', url: '#', category: 'zoro', icon: 'ShieldCheck', stats: { queries: '24.5k', blocked: '18.2%' } },
  { id: 'portainer', name: 'Portainer', subtitle: 'Container Armory', bountyLabel: '฿ 42/45 SHIPS READY', status: 'warning', url: '#', category: 'zoro', icon: 'Container', stats: { running: '42', stopped: '3', stacks: '12' } },

  // === NAMI'S CHART ROOM ===
  { id: 'searxng', name: 'SearXNG', subtitle: 'Grand Line Map', bountyLabel: '฿ 124 ROUTES CHARTED', status: 'online', url: '#', category: 'nami', icon: 'Compass', stats: { engines: '32', avg: '0.8s' } },
  { id: 'openmeteo', name: 'Open-Meteo', subtitle: 'Weather Forecast', bountyLabel: '฿ WEATHER SURVEILLANCE', status: 'online', url: '#', category: 'nami', icon: 'CloudLightning', stats: { forecast: '7-day', conditions: 'Clear' } },

  // === SANJI'S GALLEY ===
  { id: 'grocy', name: 'Grocy', subtitle: 'Galley Inventory', bountyLabel: '฿ PANTRY MANAGED', status: 'online', url: '#', category: 'sanji', icon: 'Refrigerator', stats: { items: '148', expiring: '3' } },
  { id: 'mealie', name: 'Mealie', subtitle: 'Recipe Collection', bountyLabel: '฿ 86 DISHES MASTERED', status: 'online', url: '#', category: 'sanji', icon: 'ChefHat', stats: { recipes: '86', plans: '4' } },

  // === VEGAPUNK RECORDS ===
  { id: 'jellyfin', name: 'Jellyfin', subtitle: 'The Original', bountyLabel: '฿ 12K RECORDS', status: 'online', url: '#', category: 'vegapunk', satellite: 'stella', icon: 'Brain', stats: { movies: '842', shows: '124', streams: '2' } },
  { id: 'sonarr', name: 'Sonarr', subtitle: 'Good Satellite', bountyLabel: '฿ 124 SERIES', status: 'online', url: '#', category: 'vegapunk', satellite: 'shaka', icon: 'Tv', stats: { monitored: '124', missing: '12' } },
  { id: 'radarr', name: 'Radarr', subtitle: 'Evil Satellite', bountyLabel: '฿ 842 FILMS', status: 'online', url: '#', category: 'vegapunk', satellite: 'lilith', icon: 'Film', stats: { movies: '842', queue: '3' } },
  { id: 'lidarr', name: 'Lidarr', subtitle: '45° Soul King', bountyLabel: '฿ 3.4K SOUL ALBUMS', status: 'online', url: '#', category: 'vegapunk', satellite: 'brook', icon: 'Music', stats: { artists: '240', albums: '3.4k' } },
  { id: 'prowlarr', name: 'Prowlarr', subtitle: 'Thinking Satellite', bountyLabel: '฿ 18/20 INDEXERS', status: 'warning', url: '#', category: 'vegapunk', satellite: 'edison', icon: 'Lightbulb', stats: { online: '18', offline: '2' } },
  { id: 'bazarr', name: 'Bazarr', subtitle: 'Wisdom Satellite', bountyLabel: '฿ 95% SUBTITLED', status: 'online', url: '#', category: 'vegapunk', satellite: 'pythagoras', icon: 'Subtitles', stats: { series: '98%', movies: '95%' } },
  { id: 'overseerr', name: 'Overseerr', subtitle: 'Greed Satellite', bountyLabel: '฿ 8 REQUESTS', status: 'online', url: '#', category: 'vegapunk', satellite: 'york', icon: 'ClipboardList', stats: { pending: '8', users: '6' } },
  { id: 'deluge', name: 'Deluge', subtitle: 'Violence Satellite', bountyLabel: '฿ 2.8 RATIO', status: 'online', url: '#', category: 'vegapunk', satellite: 'atlas', icon: 'Download', stats: { down: '↓2.1MB/s', up: '↑800KB/s', active: '2', seeding: '28' } },

  // === ROBIN'S LIBRARY ===
  { id: 'calibreweb', name: 'Calibre-Web', subtitle: 'Ancient Poneglyphs', bountyLabel: '฿ 1.2K TEXTS', status: 'online', url: '#', category: 'robin', icon: 'BookOpen', stats: { texts: '1.2k', authors: '156' } },
  { id: 'readarr', name: 'Readarr', subtitle: 'Archaeological Discoveries', bountyLabel: '฿ 1.2K VOLUMES', status: 'online', url: '#', category: 'robin', icon: 'ScrollText', stats: { volumes: '1.2k', queue: '2' } },
  { id: 'komga', name: 'Komga', subtitle: 'Manga Scrolls', bountyLabel: '฿ 2.8K ILLUSTRATED SCROLLS', status: 'online', url: '#', category: 'robin', icon: 'Library', stats: { series: '340', libs: '4' } },
  { id: 'pastebin', name: 'Pastebin', subtitle: 'Research Fragments', bountyLabel: '฿ 124 DISCOVERIES', status: 'online', url: '#', category: 'robin', icon: 'FileText', stats: { pastes: '124', views: '340' } },

  // === CHOPPER'S INFIRMARY ===
  { id: 'prometheus', name: 'Prometheus', subtitle: 'Medical Scanner', bountyLabel: '฿ 24/24 PATIENTS STABLE', status: 'online', url: '#', category: 'chopper', icon: 'Scan', stats: { targets: '24/24', alerts: '0' } },
  { id: 'grafana', name: 'Grafana + Loki', subtitle: 'Medical Records', bountyLabel: '฿ 4.2K LOGS/MIN', status: 'online', url: '#', category: 'chopper', icon: 'HeartPulse', stats: { dashboards: '18', history: '68GB' } },
  { id: 'harmonia', name: 'Harmonia', subtitle: 'Medicine Cache', bountyLabel: '฿ 94% EFFECTIVENESS', status: 'online', url: '#', category: 'chopper', icon: 'Pill', stats: { cache: '8.2GB', hits: '2.4k' } },
];

export const categories: Category[] = [
  { id: 'luffy', name: "Luffy's Command", subtitle: "Captain's Deck", emoji: '👑', colorClass: 'text-crew-luffy', neonClass: 'neon-text-red', services: services.filter(s => s.category === 'luffy') },
  { id: 'zoro', name: "Zoro's Armory", subtitle: "First Mate's Watch", emoji: '⚔️', colorClass: 'text-crew-zoro', neonClass: 'neon-text-green', services: services.filter(s => s.category === 'zoro') },
  { id: 'nami', name: "Nami's Chart Room", subtitle: "Navigator's Station", emoji: '🧭', colorClass: 'text-crew-nami', neonClass: 'neon-text-orange', services: services.filter(s => s.category === 'nami') },
  { id: 'sanji', name: "Sanji's Galley", subtitle: "Chef's Kitchen", emoji: '🍳', colorClass: 'text-crew-sanji', neonClass: 'neon-text-yellow', services: services.filter(s => s.category === 'sanji') },
  { id: 'vegapunk', name: 'Vegapunk Records', subtitle: 'Satellite Network', emoji: '🎵', colorClass: 'text-crew-vegapunk', neonClass: 'neon-text-purple', services: services.filter(s => s.category === 'vegapunk') },
  { id: 'robin', name: "Robin's Library", subtitle: "Archaeologist's Archive", emoji: '📚', colorClass: 'text-crew-robin', neonClass: 'neon-text-teal', services: services.filter(s => s.category === 'robin') },
  { id: 'chopper', name: "Chopper's Infirmary", subtitle: "Doctor's Office", emoji: '🩺', colorClass: 'text-crew-chopper', neonClass: 'neon-text-pink', services: services.filter(s => s.category === 'chopper') },
];

export const allServices = services;
export default services;
