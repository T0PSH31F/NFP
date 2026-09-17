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
      </svg>`
  };

  let dashboardConfig = null;

  document.addEventListener('DOMContentLoaded', initDashboard);

  async function initDashboard() {
    try {
      const res = await fetch('/api/config');
      if (!res.ok) throw new Error(`Config HTTP error: ${res.status}`);
      dashboardConfig = await res.json();

      renderNavbarStats(dashboardConfig.stats);
      renderCategories(dashboardConfig.categories);
      renderConstellation(dashboardConfig.constellation);
      renderSpeeddial(dashboardConfig.bookmarks);

      setupSearch();
      setupBrookEasterEgg();

      // Poll widget live metrics
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
      <div class="stat-pill" aria-label="Crew Online Count">
        <span>🏴‍☠️</span>
        <span class="stat-pill-val">${stats.crewUp || 0}/${stats.crewTotal || 0} CREW</span>
      </div>
      <div class="stat-pill" aria-label="Vegapunk Satellites Count">
        <span>📡</span>
        <span class="stat-pill-val">${stats.satellites || 7} SATELLITES</span>
      </div>
      <div class="stat-pill" aria-label="Fleet Uptime">
        <span>⛵</span>
        <span class="stat-pill-val">${stats.uptime || '99.9'}%</span>
      </div>
    `;
  }

  function renderCategories(categories) {
    const main = document.getElementById('dashboard-main');
    if (!main || !categories) return;

    // Filter out Vegapunk Records from main categories list as it has a custom showcase layout
    const regularCats = categories.filter(c => c.id !== 'vegapunk');

    regularCats.forEach(cat => {
      if (!cat.services || cat.services.length === 0) return; // Only render enabled services

      const sec = document.createElement('section');
      sec.className = 'category-section';
      sec.id = `cat-${cat.id}`;
      sec.style.setProperty('--accent-color', cat.color);

      sec.innerHTML = `
        <header class="crew-header">
          <div class="crew-header-left">
            <img src="${cat.avatar}" alt="${cat.crewMember}" class="crew-avatar-img">
            <div class="crew-title-group">
              <h2>${cat.title}</h2>
              <span class="crew-subtitle">${cat.subtitle}</span>
            </div>
          </div>
          <div class="vivre-card-summary">${cat.services.length} SERVICES ACTIVE</div>
        </header>
        <div class="services-grid">
          ${cat.services.map(svc => createServiceCardHtml(svc, cat.color)).join('')}
        </div>
      `;
      main.appendChild(sec);
    });
  }

  function createServiceCardHtml(svc, catColor) {
    return `
      <article class="wanted-card" data-service-id="${svc.id}" data-search-terms="${svc.name.toLowerCase()} ${svc.onePieceSub.toLowerCase()}" style="--accent-color: ${catColor}">
        <div class="card-top">
          <div class="card-icon-container">
            ${svc.icon.endsWith('.png') ? `<img src="${svc.icon}" alt="${svc.name}">` : `<span class="service-icon-text">${svc.icon}</span>`}
          </div>
          <div class="card-identity">
            <h3 class="card-title">${svc.name}</h3>
            <span class="card-onepiece-sub">${svc.onePieceSub}</span>
          </div>
          <div class="den-den-mushi-container" id="snail-${svc.id}">
            ${DEN_DEN_MUSHI_SVGS.online}
          </div>
        </div>

        <div class="card-bounty-box">
          <span class="bounty-label">BOUNTY STAT</span>
          <span class="bounty-value" id="bounty-${svc.id}">฿ FETCHING...</span>
        </div>

        <div class="widget-error-container" id="error-${svc.id}" style="display: none;"></div>

        <div class="card-actions">
          <a href="${svc.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-primary" aria-label="Board ${svc.name}">BOARD SHIP</a>
          <a href="${svc.url}" target="_blank" rel="noopener noreferrer" class="action-btn action-btn-secondary" aria-label="View logs for ${svc.name}">LOGS</a>
        </div>
      </article>
    `;
  }

  function renderConstellation(constellation) {
    const main = document.getElementById('dashboard-main');
    if (!main || !constellation) return;

    const sec = document.createElement('section');
    sec.className = 'category-section';
    sec.id = 'cat-vegapunk';
    sec.style.setProperty('--accent-color', 'var(--c-vegapunk)');

    sec.innerHTML = `
      <header class="crew-header">
        <div class="crew-header-left">
          <img src="/assets/images/Stella.png" alt="Vegapunk Stella" class="crew-avatar-img">
          <div class="crew-title-group">
            <h2>🎵 Vegapunk Records — Satellite Network</h2>
            <span class="crew-subtitle">Egghead Holographic Media Constellation</span>
          </div>
        </div>
        <div class="vivre-card-summary">SATELLITE ARRAY ACTIVE</div>
      </header>
      <div class="constellation-container">
        <div class="constellation-layout">
          <svg class="constellation-lines-svg" id="constellation-svg"></svg>
          
          <div class="constellation-stella-center" id="stella-center" aria-label="Vegapunk Stella Center">
            <img src="${constellation.center.icon}" alt="Stella" style="width: 44px; height: 44px;">
            <h3 style="font-family: var(--font-header); font-size: 0.9rem; color: #fff; margin-top: 4px;">STELLA</h3>
            <span style="font-size: 0.7rem; color: var(--c-vegapunk);" id="bounty-jellyfin">฿ 12K RECORDS</span>
          </div>

          <div class="satellite-grid">
            ${constellation.satellites.map(sat => `
              <div class="satellite-card ${sat.id === 'lidarr' ? 'brook-card' : ''}" data-service-id="${sat.id}" id="sat-${sat.id}">
                <div class="card-top">
                  <span style="font-size: 1.5rem;">${sat.avatarIcon}</span>
                  <div>
                    <h4 style="font-family: var(--font-header); font-size: 0.95rem; color: #fff;">${sat.name}</h4>
                    <span style="font-size: 0.75rem; color: var(--text-muted);">${sat.satelliteName}</span>
                  </div>
                </div>
                <div class="bounty-value" id="bounty-${sat.id}" style="font-size: 0.85rem;">฿ FETCHING...</div>
                <a href="${sat.url}" target="_blank" rel="noopener" class="action-btn action-btn-primary" style="font-size: 0.7rem; padding: 4px 8px;">CONNECT</a>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `;
    main.appendChild(sec);
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
    (dashboardConfig.categories || []).forEach(c => (c.services || []).forEach(s => allServices.push(s)));
    if (dashboardConfig.constellation) {
      allServices.push(dashboardConfig.constellation.center);
      (dashboardConfig.constellation.satellites || []).forEach(s => allServices.push(s));
    }

    for (const svc of allServices) {
      try {
        const res = await fetch(`/api/widget/${svc.id}`);
        const data = await res.json();

        const snailEl = document.getElementById(`snail-${svc.id}`);
        const bountyEl = document.getElementById(`bounty-${svc.id}`);
        const errorEl = document.getElementById(`error-${svc.id}`);

        if (data.error) {
          if (snailEl) snailEl.innerHTML = DEN_DEN_MUSHI_SVGS.offline;
          if (bountyEl) bountyEl.textContent = '฿ OFFLINE';
          if (errorEl) {
            errorEl.style.display = 'block';
            errorEl.innerHTML = `<div class="widget-error-pill">⚠️ ${data.error}</div>`;
          }
        } else {
          if (snailEl) snailEl.innerHTML = DEN_DEN_MUSHI_SVGS.online;
          if (bountyEl) bountyEl.textContent = `฿ ${data.bountyStat || 'ONLINE'}`;
          if (errorEl) errorEl.style.display = 'none';
        }
      } catch (err) {
        const snailEl = document.getElementById(`snail-${svc.id}`);
        const bountyEl = document.getElementById(`bounty-${svc.id}`);
        const errorEl = document.getElementById(`error-${svc.id}`);
        if (snailEl) snailEl.innerHTML = DEN_DEN_MUSHI_SVGS.offline;
        if (bountyEl) bountyEl.textContent = '฿ UNREACHABLE';
        if (errorEl) {
          errorEl.style.display = 'block';
          errorEl.innerHTML = `<div class="widget-error-pill">⚠️ Connection Failed</div>`;
        }
      }
    }
  }

  function setupSearch() {
    const input = document.getElementById('search-input');
    if (!input) return;

    input.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      const cards = document.querySelectorAll('.wanted-card, .speeddial-tile, .satellite-card');

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
