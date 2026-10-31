/* ==========================================================================
   Grandlix × One Piece Cyberpunk Dashboard — Vegapunk Records Edition
   Client-Side Engine (homepage-theme.js)
   ========================================================================== */

(function () {
  'use strict';

  // SVG Den Den Mushi Status Snails
  const DEN_DEN_MUSHI_SVGS = {
    online: `
      <svg class="snail-svg snail-online" viewBox="0 0 64 64" aria-label="Den Den Mushi Snail Online">
        <path fill="#22c55e" d="M12 44c0 6.6 5.4 12 12 12h24c4.4 0 8-3.6 8-8s-3.6-8-8-8H24c-6.6 0-12 5.4-12 12z"/>
        <circle cx="36" cy="32" r="16" fill="#15803d" stroke="#22c55e" stroke-width="2"/>
        <path stroke="#fff" stroke-width="2" d="M30 32a6 6 0 1 0 12 0"/>
        <circle cx="18" cy="22" r="4" fill="#22c55e"/>
        <circle cx="26" cy="20" r="4" fill="#22c55e"/>
        <circle cx="18" cy="22" r="1.5" fill="#000"/>
        <circle cx="26" cy="20" r="1.5" fill="#000"/>
      </svg>`,
    warning: `
      <svg class="snail-svg snail-warning" viewBox="0 0 64 64" aria-label="Den Den Mushi Snail Warning">
        <path fill="#f59e0b" d="M12 44c0 6.6 5.4 12 12 12h24c4.4 0 8-3.6 8-8s-3.6-8-8-8H24c-6.6 0-12 5.4-12 12z"/>
        <circle cx="36" cy="32" r="16" fill="#b45309" stroke="#f59e0b" stroke-width="2"/>
        <path fill="#38bdf8" d="M48 18c0 3-3 6-3 6s-3-3-3-6a3 3 0 0 1 6 0z"/>
        <circle cx="18" cy="22" r="4" fill="#f59e0b"/>
        <circle cx="26" cy="20" r="4" fill="#f59e0b"/>
        <circle cx="18" cy="22" r="1.5" fill="#000"/>
        <circle cx="26" cy="20" r="1.5" fill="#000"/>
      </svg>`,
    offline: `
      <svg class="snail-svg snail-offline" viewBox="0 0 64 64" aria-label="Den Den Mushi Snail Offline">
        <path fill="#64748b" d="M12 44c0 6.6 5.4 12 12 12h24c4.4 0 8-3.6 8-8s-3.6-8-8-8H24c-6.6 0-12 5.4-12 12z"/>
        <circle cx="36" cy="32" r="16" fill="#334155" stroke="#64748b" stroke-width="2"/>
        <path stroke="#cbd5e1" stroke-width="2" d="M15 22h6M23 20h6"/>
      </svg>`,
    checking: `
      <svg class="snail-svg snail-checking" viewBox="0 0 64 64" aria-label="Den Den Mushi Snail Checking">
        <path fill="#94a3b8" d="M12 44c0 6.6 5.4 12 12 12h24c4.4 0 8-3.6 8-8s-3.6-8-8-8H24c-6.6 0-12 5.4-12 12z"/>
        <circle cx="36" cy="32" r="16" fill="#475569" stroke="#94a3b8" stroke-width="2"/>
        <circle cx="18" cy="22" r="4" fill="#94a3b8"/>
        <circle cx="26" cy="20" r="4" fill="#94a3b8"/>
        <circle cx="18" cy="22" r="1.5" fill="#000"/>
        <circle cx="26" cy="20" r="1.5" fill="#000"/>
      </svg>`
  };

  const PERSONALITY_ICONS = {
    shaka: '😇',
    lilith: '😈',
    brook: '💀',
    edison: '💡',
    pythagoras: '📐',
    york: '🤑',
    atlas: '💪',
    stella: '★'
  };

  let dashboardConfig = null;

  document.addEventListener('DOMContentLoaded', initDashboard);

  async function initDashboard() {
    try {
      const res = await fetch('/api/config');
      if (!res.ok) throw new Error(`Config HTTP error: ${res.status}`);
      dashboardConfig = await res.json();

      renderNavbarStats(dashboardConfig.stats);

      const main = document.getElementById('dashboard-main');
      if (main) main.innerHTML = '';

      // 1. Grand Line Fleet Vitals — ALWAYS FIRST
      renderFleetVitalsSkeleton();
      pollFleetVitals();
      setInterval(pollFleetVitals, 5000);

      // 2. Render crew categories
      renderCategories(dashboardConfig.categories, dashboardConfig.constellation);

      // 3. Render speeddial bookmarks
      renderSpeeddial(dashboardConfig.bookmarks);

      setupSearch();
      setupBrookEasterEgg();

      // Poll widget live metrics immediately and periodically
      pollWidgetMetrics();
      setInterval(pollWidgetMetrics, 10000);
    } catch (err) {
      console.error('Failed to initialize homepage dashboard:', err);
    }
  }

  function renderNavbarStats(stats) {
    if (!stats) return;
    const statsContainer = document.getElementById('nav-stats-bar');
    if (!statsContainer) return;

    statsContainer.innerHTML = `
      <div class="stat-pill" aria-label="Fleet Reachability" id="nav-reachability-pill">
        <span>🏴‍☠️</span>
        <span class="stat-pill-val" id="nav-crew-val">PROBING FLEET...</span>
      </div>
      <div class="stat-pill" aria-label="Vegapunk Satellites Count">
        <span>📡</span>
        <span class="stat-pill-val">${stats.satellites || 7} SATELLITES</span>
      </div>
      <div class="stat-pill" aria-label="Observability Status">
        <span>🎯</span>
        <span class="stat-pill-val">NETDATA ACTIVE</span>
      </div>
    `;
  }

  function renderFleetVitalsSkeleton() {
    const main = document.getElementById('dashboard-main');
    if (!main) return;

    const sec = document.createElement('section');
    sec.className = 'fleet-vitals-section';
    sec.id = 'fleet-vitals-section';
    sec.innerHTML = `
      <header class="fleet-vitals-header">
        <div class="fleet-vitals-title-group">
          <div class="fleet-vitals-flag">🏴‍☠️</div>
          <div>
            <h2>GRAND LINE FLEET VITALS</h2>
            <span class="fleet-vitals-subtitle">High-Definition Telemetry via Netdata Engine (z0r0 · luffy · sanji)</span>
          </div>
        </div>
        <div class="fleet-vitals-meta" id="fleet-vitals-meta">COLLECTING VITALS...</div>
      </header>
      <div class="fleet-vitals-grid" id="fleet-vitals-grid">
        <div class="fleet-loading-card">Connecting to fleet Netdata engines...</div>
      </div>
    `;
    main.appendChild(sec);
  }

  async function pollFleetVitals() {
    const grid = document.getElementById('fleet-vitals-grid');
    const meta = document.getElementById('fleet-vitals-meta');
    if (!grid) return;

    try {
      const res = await fetch('/api/fleet/vitals');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      const hosts = data.hosts || [];

      if (meta && data.updatedAt) {
        meta.textContent = `LAST HARVEST: ${new Date(data.updatedAt).toLocaleTimeString()} UTC`;
      }

      grid.innerHTML = hosts.map(h => createHostVitalCardHtml(h)).join('');
    } catch (err) {
      if (meta) meta.textContent = 'TELEMETRY DEGRADED';
    }
  }

  function createHostVitalCardHtml(host) {
    const isOnline = host.state === 'online';
    const cpuPct = host.cpuPct !== null ? host.cpuPct : 0;
    const ramPct = host.ramPct !== null ? host.ramPct : 0;
    const diskPct = host.diskPct !== null ? host.diskPct : 0;
    const loadStr = Array.isArray(host.load) ? host.load.join(', ') : (host.load || '—');

    return `
      <div class="host-vital-card ${isOnline ? 'host-online' : 'host-offline'}" id="host-card-${host.id}">
        <div class="host-vital-top">
          <div class="host-identity">
            <span class="host-status-indicator ${isOnline ? 'indicator-online' : 'indicator-offline'}"></span>
            <div class="host-name-box">
              <span class="host-name">${host.name}</span>
              <span class="host-subinfo">${host.os || 'NixOS'} · ${host.version || 'v2'}</span>
            </div>
          </div>
          <div class="host-badges">
            <span class="host-uptime-badge">⏱ ${host.uptime || 'offline'}</span>
            ${host.netdataUrl ? `<a href="${host.netdataUrl}" target="_blank" rel="noopener noreferrer" class="netdata-link" aria-label="Open Netdata on ${host.id}">Netdata — ${host.id} ↗</a>` : ''}
          </div>
        </div>

        ${isOnline ? `
        <div class="host-metrics-bars">
          <div class="vital-bar-group">
            <div class="vital-bar-label">
              <span>CPU UTILIZATION</span>
              <span class="vital-val">${cpuPct}%</span>
            </div>
            <div class="vital-progress-track">
              <div class="vital-progress-fill ${cpuPct > 80 ? 'fill-warn' : ''}" style="width: ${Math.min(100, cpuPct)}%"></div>
            </div>
          </div>

          <div class="vital-bar-group">
            <div class="vital-bar-label">
              <span>RAM USAGE</span>
              <span class="vital-val">${host.ramUsedGB} / ${host.ramTotalGB} GB (${ramPct}%)</span>
            </div>
            <div class="vital-progress-track">
              <div class="vital-progress-fill ${ramPct > 85 ? 'fill-warn' : ''}" style="width: ${Math.min(100, ramPct)}%"></div>
            </div>
          </div>

          <div class="vital-bar-group">
            <div class="vital-bar-label">
              <span>DATA DISK</span>
              <span class="vital-val">${host.diskUsedGB} / ${host.diskTotalGB} GB (${diskPct}%)</span>
            </div>
            <div class="vital-progress-track">
              <div class="vital-progress-fill ${diskPct > 90 ? 'fill-warn' : ''}" style="width: ${Math.min(100, diskPct)}%"></div>
            </div>
          </div>
        </div>

        <div class="host-vital-footer">
          <span class="vital-stat-sub">NET: ↓ ${host.netRxKbps || 0} KB/s  ↑ ${host.netTxKbps || 0} KB/s</span>
          <span class="vital-stat-sub">LOAD: ${loadStr}</span>
        </div>
        ` : `
        <div class="host-offline-box">
          <span>⚠️ Tailnet unreachable or Netdata probe inactive</span>
        </div>
        `}
      </div>
    `;
  }

  function renderCategories(categories, constellation) {
    const main = document.getElementById('dashboard-main');
    if (!main || !categories) return;

    categories.forEach(cat => {
      if (!cat.services || cat.services.length === 0) return;

      const sec = document.createElement('section');
      sec.className = 'category-section' + (cat.id === 'vegapunk' ? ' constellation-section' : '');
      sec.id = `cat-${cat.id}`;
      sec.style.setProperty('--accent-color', cat.color);

      if (cat.id === 'vegapunk' && constellation && constellation.center && constellation.satellites && constellation.satellites.length > 0) {
        sec.innerHTML = `
          <header class="crew-header">
            <div class="crew-header-left">
              <img src="${cat.avatar}" alt="${cat.crewMember}" class="crew-avatar-img">
              <div class="crew-title-group">
                <h2>${cat.title}</h2>
                <span class="crew-subtitle">${cat.subtitle}</span>
              </div>
            </div>
            <div class="vivre-card-summary" id="cat-summary-${cat.id}">${cat.services.length} SATELLITES (PROBING...)</div>
          </header>

          <div class="constellation-stage-wrapper">
            <div class="constellation-orbit-stage" id="constellation-stage">
              <svg class="constellation-orbit-svg" id="constellation-svg" viewBox="0 0 420 420"></svg>
              
              <div class="constellation-stella-node" id="stella-node" role="button" tabindex="0" aria-label="Vegapunk Stella Center" onclick="focusCanonicalCard('${constellation.center.id}')" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();focusCanonicalCard('${constellation.center.id}')}">
                <img src="${constellation.center.icon}" alt="Stella" class="stella-node-icon" onerror="this.src='/assets/icons/fallback.svg'">
                <span class="stella-node-title">STELLA</span>
                <span class="stella-node-sub">${constellation.center.name}</span>
              </div>

              ${renderOrbitalSatellites(constellation.satellites)}
            </div>
          </div>

          <div class="services-grid">
            ${groupServicesByBase(cat.services).map(grp => renderServiceGroup(grp, cat.color)).join('')}
          </div>
        `;
      } else {
        sec.innerHTML = `
          <header class="crew-header">
            <div class="crew-header-left">
              <img src="${cat.avatar}" alt="${cat.crewMember}" class="crew-avatar-img">
              <div class="crew-title-group">
                <h2>${cat.title}</h2>
                <span class="crew-subtitle">${cat.subtitle}</span>
              </div>
            </div>
            <div class="vivre-card-summary" id="cat-summary-${cat.id}">${cat.services.length} SERVICES (PROBING...)</div>
          </header>
          <div class="services-grid">
            ${groupServicesByBase(cat.services).map(grp => renderServiceGroup(grp, cat.color)).join('')}
          </div>
        `;
      }
      main.appendChild(sec);
    });

    if (constellation && constellation.center && constellation.satellites && constellation.satellites.length > 0) {
      setTimeout(drawConstellationLines, 80);
      window.addEventListener('resize', drawConstellationLines);
    }
  }

  function groupServicesByBase(services) {
    const groups = [];
    const map = new Map();

    (services || []).forEach(svc => {
      const baseName = svc.baseTitle || svc.name.replace(/\s*\([^)]*\)$/, '').trim();
      const groupKey = `${svc.category}:${baseName.toLowerCase().replace(/[^a-z0-9]/g, '-')}`;
      if (!map.has(groupKey)) {
        const grp = {
          groupKey: groupKey,
          baseName: baseName,
          category: svc.category,
          instances: []
        };
        map.set(groupKey, grp);
        groups.push(grp);
      }
      map.get(groupKey).instances.push(svc);
    });

    return groups;
  }

  function renderServiceGroup(group, catColor) {
    if (group.instances.length === 1) {
      return createWantedPosterCardHtml(group.instances[0], catColor);
    }
    return createMultiInstancePosterCardHtml(group, catColor);
  }

  window.switchServiceInstance = function (evt, groupKey, targetId) {
    if (evt) {
      evt.preventDefault();
      evt.stopPropagation();
    }
    const card = document.querySelector(`[data-group-key="${groupKey}"]`);
    if (!card) return;

    const pills = card.querySelectorAll('.instance-pill');
    pills.forEach(p => {
      const match = p.getAttribute('data-target-id') === targetId;
      p.classList.toggle('active', match);
      p.setAttribute('aria-selected', match ? 'true' : 'false');
    });

    const views = card.querySelectorAll('.instance-view');
    views.forEach(v => {
      const match = v.getAttribute('data-instance-id') === targetId;
      v.classList.toggle('hidden', !match);
    });

    const snails = card.querySelectorAll('.den-den-mushi-container');
    snails.forEach(s => {
      const match = s.getAttribute('data-instance-id') === targetId;
      s.classList.toggle('hidden', !match);
    });
  };

  window.focusCanonicalCard = function (svcId) {
    let card = document.querySelector(`[data-service-id='${svcId}']`);
    if (!card) {
      card = document.querySelector(`[data-all-ids~='${svcId}']`);
      if (card) {
        const groupKey = card.getAttribute('data-group-key');
        if (groupKey && window.switchServiceInstance) {
          window.switchServiceInstance(null, groupKey, svcId);
        }
      }
    }
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' });
      card.classList.add('card-highlight-pulse');
      setTimeout(() => card.classList.remove('card-highlight-pulse'), 2500);
    }
  };

  function renderOrbitalSatellites(satellites) {
    if (!satellites || satellites.length === 0) return '';
    const count = satellites.length;
    const radius = 150;
    const cx = 210;
    const cy = 210;

    return satellites.map((sat, i) => {
      const angle = (i * (2 * Math.PI) / count) - (Math.PI / 2);
      const x = Math.round(cx + radius * Math.cos(angle));
      const y = Math.round(cy + radius * Math.sin(angle));
      const emoji = PERSONALITY_ICONS[sat.satellite] || '📡';
      const label = sat.satellite || sat.name;

      const hasImg = sat.icon && (sat.icon.startsWith('/') || sat.icon.endsWith('.svg') || sat.icon.endsWith('.png'));
      const bubbleContent = hasImg
        ? `<img src="${sat.icon}" alt="${sat.name}" class="satellite-bubble-img" onerror="this.src='/assets/icons/fallback.svg'">`
        : `<span class="satellite-bubble-text">${emoji}</span>`;

      return `
        <div class="satellite-orbit-node" id="orbit-${sat.id}" data-service-id="${sat.id}"
             role="button" tabindex="0"
             style="left: ${x}px; top: ${y}px;"
             title="${sat.name}: ${sat.satelliteName || ''}"
             onclick="focusCanonicalCard('${sat.id}')"
             onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();focusCanonicalCard('${sat.id}')}">
          <div class="satellite-node-bubble">${bubbleContent}</div>
          <span class="satellite-node-label">${label}</span>
        </div>
      `;
    }).join('');
  }

  function drawConstellationLines() {
    const svg = document.getElementById('constellation-svg');
    const stage = document.getElementById('constellation-stage');
    if (!svg || !stage) return;

    const cx = 210;
    const cy = 210;
    const radius = 150;

    let svgContent = `
      <circle cx="${cx}" cy="${cy}" r="${radius}" fill="none" stroke="rgba(191,0,255,0.2)" stroke-width="1.5" stroke-dasharray="6 6"/>
      <circle cx="${cx}" cy="${cy}" r="55" fill="none" stroke="rgba(191,0,255,0.3)" stroke-width="1.5"/>
    `;

    const nodes = stage.querySelectorAll('.satellite-orbit-node');
    nodes.forEach(node => {
      const x = parseFloat(node.style.left);
      const y = parseFloat(node.style.top);
      svgContent += `
        <line x1="${cx}" y1="${cy}" x2="${x}" y2="${y}" stroke="rgba(191,0,255,0.35)" stroke-width="1.5" stroke-dasharray="4 4" class="orbit-spoke" data-target="${node.getAttribute('data-service-id')}"/>
      `;
    });

    svg.innerHTML = svgContent;
  }

  function createWantedPosterCardHtml(svc, catColor) {
    const hasLogs = svc.logs && svc.logs.enable && svc.logs.url;
    const isBrook = svc.satellite === 'brook' || svc.id === 'lidarr';
    const declaredFields = (svc.metric && svc.metric.fields) || [];
    const isHealthOnly = !svc.metric || svc.metric.mode === 'health-only' || declaredFields.length === 0;

    const hasImg = svc.icon && (svc.icon.startsWith('/') || svc.icon.endsWith('.svg') || svc.icon.endsWith('.png'));
    const iconHtml = hasImg
      ? `<img src="${svc.icon}" alt="${svc.name}" class="service-card-icon" onerror="this.src='/assets/icons/fallback.svg'">`
      : `<span class="wanted-portrait-emoji">${svc.icon || '⚓'}</span>`;

    const initialFieldsHtml = isHealthOnly
      ? `<div class="metric-health-pill">HEALTH CHECKED</div>`
      : declaredFields.map(f => {
          const label = f.replace(/([A-Z])/g, ' $1').toUpperCase();
          return `
            <div class="metric-field-item">
              <span class="metric-field-key">${label}</span>
              <span class="metric-field-val" id="metric-${svc.id}-${f}">—</span>
            </div>
          `;
        }).join('');

    return `
      <article class="wanted-poster-card ${isBrook ? 'brook-card' : ''}" data-service-id="${svc.id}" data-search-terms="${svc.name.toLowerCase()} ${(svc.onePieceSub || '').toLowerCase()}" style="--accent-color: ${catColor}">
        <div class="wanted-poster-frame">
          <div class="wanted-poster-masthead">
            <span class="wanted-text">WANTED</span>
            <span class="dead-or-alive-text">DEAD OR ALIVE</span>
          </div>

          <div class="wanted-portrait-box">
            <div class="wanted-portrait-inner">
              ${iconHtml}
            </div>
            <div class="den-den-mushi-container" id="snail-${svc.id}">
              ${DEN_DEN_MUSHI_SVGS.checking}
            </div>
          </div>

          <div class="wanted-identity">
            <h3 class="wanted-name">${svc.name}</h3>
            <span class="wanted-role">${svc.onePieceSub || 'CYBERIA SHIPMATE'}</span>
          </div>

          <div class="bounty-plaque" id="bounty-plaque-${svc.id}">
            <span class="bounty-currency">฿</span>
            <span class="bounty-figure" id="bounty-${svc.id}">FETCHING...</span>
          </div>

          <div class="card-metrics-grid" id="metrics-${svc.id}">
            ${initialFieldsHtml}
          </div>

          <div class="widget-error-container" id="error-${svc.id}" style="display: none;"></div>

          <div class="wanted-actions">
            <a href="${svc.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-primary" aria-label="Board ${svc.name}">BOARD SHIP</a>
            ${hasLogs ? `<a href="${svc.logs.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-secondary" aria-label="View logs for ${svc.name}">LOGS</a>` : ''}
          </div>
        </div>
      </article>
    `;
  }

  function createMultiInstancePosterCardHtml(group, catColor) {
    const first = group.instances[0];
    const isBrook = group.instances.some(s => s.satellite === 'brook' || s.id === 'lidarr');
    const hasImg = first.icon && (first.icon.startsWith('/') || first.icon.endsWith('.svg') || first.icon.endsWith('.png'));
    const iconHtml = hasImg
      ? `<img src="${first.icon}" alt="${group.baseName}" class="service-card-icon" onerror="this.src='/assets/icons/fallback.svg'">`
      : `<span class="wanted-portrait-emoji">${first.icon || '⚓'}</span>`;

    const allSearchTerms = `${group.baseName.toLowerCase()} ${(first.onePieceSub || '').toLowerCase()} ${group.instances.map(i => (i.targetHost || i.name)).join(' ').toLowerCase()}`;
    const allIds = group.instances.map(i => i.id).join(' ');

    const switcherPillsHtml = group.instances.map((inst, idx) => {
      const hostName = inst.targetHost || (inst.name.match(/\(([^)]+)\)/) ? inst.name.match(/\(([^)]+)\)/)[1] : 'node');
      const isFirst = idx === 0;
      return `
        <button class="instance-pill ${isFirst ? 'active' : ''}"
                role="tab"
                type="button"
                aria-selected="${isFirst ? 'true' : 'false'}"
                data-target-id="${inst.id}"
                onclick="window.switchServiceInstance(event, '${group.groupKey}', '${inst.id}')">
          <span class="instance-dot" id="dot-${inst.id}"></span>
          <span class="instance-host-label">${hostName}</span>
        </button>
      `;
    }).join('');

    const snailsHtml = group.instances.map((inst, idx) => `
      <div class="den-den-mushi-container ${idx === 0 ? '' : 'hidden'}" id="snail-${inst.id}" data-instance-id="${inst.id}">
        ${DEN_DEN_MUSHI_SVGS.checking}
      </div>
    `).join('');

    const instanceViewsHtml = group.instances.map((inst, idx) => {
      const isFirst = idx === 0;
      const hasLogs = inst.logs && inst.logs.enable && inst.logs.url;
      const declaredFields = (inst.metric && inst.metric.fields) || [];
      const isHealthOnly = !inst.metric || inst.metric.mode === 'health-only' || declaredFields.length === 0;
      const hostName = inst.targetHost || (inst.name.match(/\(([^)]+)\)/) ? inst.name.match(/\(([^)]+)\)/)[1] : 'node');

      const initialFieldsHtml = isHealthOnly
        ? `<div class="metric-health-pill">HEALTH CHECKED</div>`
        : declaredFields.map(f => {
            const label = f.replace(/([A-Z])/g, ' $1').toUpperCase();
            return `
              <div class="metric-field-item">
                <span class="metric-field-key">${label}</span>
                <span class="metric-field-val" id="metric-${inst.id}-${f}">—</span>
              </div>
            `;
          }).join('');

      return `
        <div class="instance-view ${isFirst ? '' : 'hidden'}" data-instance-id="${inst.id}">
          <div class="bounty-plaque" id="bounty-plaque-${inst.id}">
            <span class="bounty-currency">฿</span>
            <span class="bounty-figure" id="bounty-${inst.id}">FETCHING...</span>
          </div>

          <div class="card-metrics-grid" id="metrics-${inst.id}">
            ${initialFieldsHtml}
          </div>

          <div class="widget-error-container" id="error-${inst.id}" style="display: none;"></div>

          <div class="wanted-actions">
            <a href="${inst.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-primary" aria-label="Board ${inst.name}">BOARD ${hostName.toUpperCase()}</a>
            ${hasLogs ? `<a href="${inst.logs.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-secondary" aria-label="View logs for ${inst.name}">LOGS</a>` : ''}
          </div>
        </div>
      `;
    }).join('');

    const quickLinksHtml = group.instances.map(inst => {
      const hostName = inst.targetHost || (inst.name.match(/\(([^)]+)\)/) ? inst.name.match(/\(([^)]+)\)/)[1] : 'node');
      return `<a href="${inst.url}" target="_blank" rel="noopener noreferrer" class="quick-node-link" title="Open on ${hostName}">${hostName} ↗</a>`;
    }).join('');

    return `
      <article class="wanted-poster-card ${isBrook ? 'brook-card' : ''} multi-instance-card"
               data-service-id="${first.id}"
               data-group-key="${group.groupKey}"
               data-all-ids="${allIds}"
               data-search-terms="${allSearchTerms}"
               style="--accent-color: ${catColor}">
        <div class="wanted-poster-frame">
          <div class="wanted-poster-masthead">
            <span class="wanted-text">WANTED</span>
            <span class="dead-or-alive-text">DEAD OR ALIVE</span>
          </div>

          <div class="wanted-portrait-box">
            <div class="wanted-portrait-inner">
              ${iconHtml}
            </div>
            ${snailsHtml}
          </div>

          <div class="wanted-identity">
            <h3 class="wanted-name">${group.baseName} <span class="multi-instance-badge">${group.instances.length} NODES</span></h3>
            <span class="wanted-role">${first.onePieceSub || 'MULTI-NODE FLEET SERVICE'}</span>
          </div>

          <div class="instance-switcher-bar" role="tablist" aria-label="Switch node for ${group.baseName}">
            ${switcherPillsHtml}
          </div>

          ${instanceViewsHtml}

          <div class="instance-quick-links">
            <span class="quick-links-label">DIRECT:</span>
            ${quickLinksHtml}
          </div>
        </div>
      </article>
    `;
  }

  function renderSpeeddial(bookmarks) {
    const main = document.getElementById('dashboard-main');
    if (!main || !bookmarks || bookmarks.length === 0) return;

    const sec = document.createElement('section');
    sec.className = 'category-section';
    sec.id = 'cat-speeddial';
    sec.style.setProperty('--accent-color', 'var(--c-speeddial)');

    sec.innerHTML = `
      <header class="crew-header">
        <div class="crew-header-left">
          <div style="font-size: 2rem;">⚡</div>
          <div class="crew-title-group">
            <h2>Speeddial Navigation Shortcuts</h2>
            <span class="crew-subtitle">External Internet Bookmarks & Tools</span>
          </div>
        </div>
        <div class="vivre-card-summary">${bookmarks.length} BOOKMARKS</div>
      </header>
      <div class="speeddial-grid">
        ${bookmarks.map(b => `
          <a href="${b.url}" target="_blank" rel="noopener noreferrer" class="speeddial-tile" data-search-terms="${b.name.toLowerCase()} ${b.category.toLowerCase()}">
            <div class="speeddial-letter-tile">${b.name.charAt(0).toUpperCase()}</div>
            <div class="speeddial-info">
              <span class="speeddial-name">${b.name}</span>
              <span class="speeddial-cat">${b.category}</span>
            </div>
          </a>
        `).join('')}
      </div>
    `;
    main.appendChild(sec);
  }

  async function pollWidgetMetrics() {
    if (!dashboardConfig) return;
    const allServices = [];
    const categoryCounts = {};
    (dashboardConfig.categories || []).forEach(c => {
      categoryCounts[c.id] = { total: (c.services || []).length, reachable: 0 };
      (c.services || []).forEach(s => allServices.push(s));
    });

    let totalOnline = 0;

    for (const svc of allServices) {
      try {
        const res = await fetch(`/api/widget/${svc.id}`);
        const data = await res.json();

        const snailEl = document.getElementById(`snail-${svc.id}`);
        const bountyEl = document.getElementById(`bounty-${svc.id}`);
        const bountyPlaqueEl = document.getElementById(`bounty-plaque-${svc.id}`);
        const errorEl = document.getElementById(`error-${svc.id}`);
        const metricsEl = document.getElementById(`metrics-${svc.id}`);
        const orbitNode = document.getElementById(`orbit-${svc.id}`);

        const isOnline = data.health ? (data.health.state === 'online') : (data.status === 'online');
        if (isOnline) {
          totalOnline++;
          if (categoryCounts[svc.category]) categoryCounts[svc.category].reachable++;
        }

        if (snailEl) {
          snailEl.innerHTML = isOnline ? DEN_DEN_MUSHI_SVGS.online : DEN_DEN_MUSHI_SVGS.offline;
        }

        const dotEl = document.getElementById(`dot-${svc.id}`);
        if (dotEl) {
          dotEl.classList.toggle('dot-online', isOnline);
          dotEl.classList.toggle('dot-offline', !isOnline);
        }

        if (orbitNode) {
          orbitNode.style.opacity = isOnline ? '1' : '0.45';
        }

        const metricState = data.metric ? data.metric.state : (isOnline ? 'available' : 'unavailable');
        let fieldsList = [];
        if (data.metric && Array.isArray(data.metric.fields)) {
          fieldsList = data.metric.fields;
        } else if (data.metric && data.metric.fields && typeof data.metric.fields === 'object') {
          fieldsList = Object.entries(data.metric.fields).map(([k, v]) => ({ key: k, label: k, value: v }));
        }

        if (metricsEl) {
          if (!isOnline) {
            metricsEl.innerHTML = `<div class="metric-unavailable-pill error-state">Service Unreachable</div>`;
          } else if (metricState === 'unavailable') {
            const reason = (data.metric && data.metric.reason) || data.error || 'Metrics unavailable';
            metricsEl.innerHTML = `<div class="metric-unavailable-pill">${reason}</div>`;
          } else if (metricState === 'health-only' || fieldsList.length === 0) {
            metricsEl.innerHTML = `<div class="metric-health-pill">HEALTH CHECKED</div>`;
          } else {
            metricsEl.innerHTML = fieldsList.map(f => `
              <div class="metric-field-item">
                <span class="metric-field-key">${(f.label || f.key).toUpperCase()}</span>
                <span class="metric-field-val">${f.value}</span>
              </div>
            `).join('');
          }
        }

        if (bountyEl) {
          let statText = data.bountyStat || (isOnline ? 'OPERATIONAL' : 'OFFLINE');
          bountyEl.textContent = statText;
        }

        if (bountyPlaqueEl) {
          if (!isOnline) {
            bountyPlaqueEl.classList.add('bounty-offline');
          } else {
            bountyPlaqueEl.classList.remove('bounty-offline');
          }
        }

        if (errorEl) {
          if (data.error && data.error !== 'Metrics unavailable' && data.error !== 'Metrics credential unavailable' && !data.error.includes('Unreachable')) {
            errorEl.style.display = 'block';
            errorEl.innerHTML = `<div class="widget-error-pill">⚠️ ${data.error}</div>`;
          } else {
            errorEl.style.display = 'none';
          }
        }
      } catch (err) {
        const snailEl = document.getElementById(`snail-${svc.id}`);
        const bountyEl = document.getElementById(`bounty-${svc.id}`);
        const bountyPlaqueEl = document.getElementById(`bounty-plaque-${svc.id}`);
        const metricsEl = document.getElementById(`metrics-${svc.id}`);
        const orbitNode = document.getElementById(`orbit-${svc.id}`);
        if (snailEl) snailEl.innerHTML = DEN_DEN_MUSHI_SVGS.offline;
        const dotEl = document.getElementById(`dot-${svc.id}`);
        if (dotEl) {
          dotEl.classList.remove('dot-online');
          dotEl.classList.add('dot-offline');
        }
        if (bountyEl) bountyEl.textContent = 'OFFLINE';
        if (bountyPlaqueEl) bountyPlaqueEl.classList.add('bounty-offline');
        if (metricsEl) {
          metricsEl.innerHTML = '<div class="metric-unavailable-pill error-state">Service Unreachable</div>';
        }
        if (orbitNode) orbitNode.style.opacity = '0.45';
      }
    }

    const crewEl = document.getElementById('nav-crew-val');
    if (crewEl) crewEl.textContent = `${totalOnline}/${allServices.length} REACHABLE`;

    for (const [catId, counts] of Object.entries(categoryCounts)) {
      const sumEl = document.getElementById(`cat-summary-${catId}`);
      if (sumEl) sumEl.textContent = `${counts.reachable}/${counts.total} REACHABLE`;
    }
  }

  function setupSearch() {
    const input = document.getElementById('search-input');
    if (!input) return;

    input.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      const cards = document.querySelectorAll('.wanted-poster-card, .speeddial-tile');

      cards.forEach(card => {
        const terms = card.getAttribute('data-search-terms') || card.textContent.toLowerCase();
        if (!q || terms.includes(q)) {
          card.style.display = '';
          card.style.opacity = '1';
        } else {
          card.style.display = 'none';
          card.style.opacity = '0';
        }
      });
    });
  }

  function setupBrookEasterEgg() {
    document.addEventListener('click', (e) => {
      const brookCard = e.target.closest('.brook-card');
      if (brookCard) {
        let bubble = brookCard.querySelector('.brook-speech-bubble');
        if (!bubble) {
          bubble = document.createElement('div');
          bubble.className = 'brook-speech-bubble';
          bubble.textContent = 'Yohohoho! 💀🎵';
          brookCard.appendChild(bubble);
          setTimeout(() => bubble.remove(), 2500);
        }

        for (let i = 0; i < 5; i++) {
          const note = document.createElement('span');
          note.className = 'musical-note';
          note.textContent = Math.random() > 0.5 ? '♪' : '♫';
          note.style.left = `${20 + Math.random() * 60}%`;
          note.style.bottom = '10px';
          brookCard.appendChild(note);
          setTimeout(() => note.remove(), 2000);
        }
      }
    });
  }
})();
