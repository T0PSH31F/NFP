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
      renderCategories(dashboardConfig.categories, dashboardConfig.constellation);
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
      <div class="stat-pill" aria-label="Fleet Uptime">
        <span>⛵</span>
        <span class="stat-pill-val">${stats.uptime ? stats.uptime + '%' : 'Not measured'}</span>
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
              
              <div class="constellation-stella-node" id="stella-node" role="button" tabindex="0" aria-label="Vegapunk Stella Center" onclick="document.querySelector('[data-service-id=\\'${constellation.center.id}\\']')?.scrollIntoView({behavior: 'smooth'})" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();document.querySelector('[data-service-id=\\'${constellation.center.id}\\']')?.scrollIntoView({behavior: 'smooth'})}">
                <img src="${constellation.center.icon}" alt="Stella" class="stella-node-icon" onerror="this.src='/assets/icons/fallback.svg'">
                <span class="stella-node-title">STELLA</span>
                <span class="stella-node-sub">${constellation.center.name}</span>
              </div>

              ${renderOrbitalSatellites(constellation.satellites)}
            </div>
          </div>

          <div class="services-grid">
            ${cat.services.map(svc => createServiceCardHtml(svc, cat.color)).join('')}
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
            ${cat.services.map(svc => createServiceCardHtml(svc, cat.color)).join('')}
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
             onclick="document.querySelector('[data-service-id=\\'${sat.id}\\']')?.scrollIntoView({behavior: 'smooth'})"
             onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();document.querySelector('[data-service-id=\\'${sat.id}\\']')?.scrollIntoView({behavior: 'smooth'})}">
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

  function createServiceCardHtml(svc, catColor) {
    const hasLogs = svc.logs && svc.logs.enable && svc.logs.url;
    const isBrook = svc.satellite === 'brook' || svc.id === 'lidarr';
    const declaredFields = (svc.metric && svc.metric.fields) || [];
    const isHealthOnly = !svc.metric || svc.metric.mode === 'health-only' || declaredFields.length === 0;

    const hasImg = svc.icon && (svc.icon.startsWith('/') || svc.icon.endsWith('.svg') || svc.icon.endsWith('.png'));
    const iconHtml = hasImg
      ? `<img src="${svc.icon}" alt="${svc.name}" class="service-card-icon" onerror="this.src='/assets/icons/fallback.svg'">`
      : `<span class="service-icon-text">${svc.icon || '⚓'}</span>`;

    const initialFieldsHtml = isHealthOnly
      ? `<div class="metric-health-pill">HEALTH CHECKED</div>`
      : declaredFields.map(f => {
          const label = f.replace(/([A-Z])/g, ' $1').toLowerCase();
          return `
            <div class="metric-field-item">
              <span class="metric-field-key">${label}</span>
              <span class="metric-field-val" id="metric-${svc.id}-${f}">—</span>
            </div>
          `;
        }).join('');

    return `
      <article class="wanted-card ${isBrook ? 'brook-card' : ''}" data-service-id="${svc.id}" data-search-terms="${svc.name.toLowerCase()} ${(svc.onePieceSub || '').toLowerCase()}" style="--accent-color: ${catColor}">
        <div class="card-top">
          <div class="card-icon-container">
            ${iconHtml}
          </div>
          <div class="card-identity">
            <h3 class="card-title">${svc.name}</h3>
            <span class="card-onepiece-sub">${svc.onePieceSub || ''}</span>
          </div>
          <div class="den-den-mushi-container" id="snail-${svc.id}">
            ${DEN_DEN_MUSHI_SVGS.checking}
          </div>
        </div>

        <div class="card-metrics-grid" id="metrics-${svc.id}">
          ${initialFieldsHtml}
        </div>

        <div class="card-bounty-box">
          <span class="bounty-label" id="bounty-label-${svc.id}">${isHealthOnly ? 'SERVICE STATUS' : 'LIVE METRICS'}</span>
          <span class="bounty-value" id="bounty-${svc.id}">FETCHING...</span>
        </div>

        <div class="widget-error-container" id="error-${svc.id}" style="display: none;"></div>

        <div class="card-actions">
          <a href="${svc.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-primary" aria-label="Board ${svc.name}">BOARD SHIP</a>
          ${hasLogs ? `<a href="${svc.logs.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-secondary" aria-label="View logs for ${svc.name}">LOGS</a>` : ''}
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
        const bountyLabelEl = document.getElementById(`bounty-label-${svc.id}`);
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
            const reason = (data.metric && data.metric.reason) || data.error || 'Metrics credential unavailable';
            metricsEl.innerHTML = `<div class="metric-unavailable-pill">${reason}</div>`;
          } else if (metricState === 'health-only' || fieldsList.length === 0) {
            metricsEl.innerHTML = `<div class="metric-health-pill">HEALTH CHECKED</div>`;
          } else {
            metricsEl.innerHTML = fieldsList.map(f => `
              <div class="metric-field-item">
                <span class="metric-field-key">${f.label || f.key}</span>
                <span class="metric-field-val">${f.value}</span>
              </div>
            `).join('');
          }
        }

        if (bountyLabelEl) {
          bountyLabelEl.textContent = (isOnline && metricState === 'available') ? 'LIVE METRICS' : 'SERVICE STATUS';
        }

        if (bountyEl) {
          let statText = data.bountyStat || (isOnline ? 'OPERATIONAL' : 'OFFLINE');
          bountyEl.textContent = statText;
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
        const bountyLabelEl = document.getElementById(`bounty-label-${svc.id}`);
        const metricsEl = document.getElementById(`metrics-${svc.id}`);
        const orbitNode = document.getElementById(`orbit-${svc.id}`);
        if (snailEl) snailEl.innerHTML = DEN_DEN_MUSHI_SVGS.offline;
        if (bountyLabelEl) bountyLabelEl.textContent = 'SERVICE STATUS';
        if (bountyEl) bountyEl.textContent = 'OFFLINE';
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
      const cards = document.querySelectorAll('.wanted-card, .speeddial-tile');

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
