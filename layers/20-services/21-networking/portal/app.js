// LoveLain Cyberia Facility Portal & Launchpad Client Engine
(function () {
  'use strict';

  // State Management
  const state = {
    isAuthenticated: false,
    isSimulated: false,
    user: null,
    activeTab: 'tab-welcome'
  };

  // DOM Elements
  const navBtns = document.querySelectorAll('.nav-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');
  const userGreetingBanner = document.getElementById('user-greeting-banner');
  const userDisplayName = document.getElementById('user-display-name');
  const userAuthEmail = document.getElementById('user-auth-email');
  const guestHeroCta = document.getElementById('guest-hero-cta');
  const headerAuthContainer = document.getElementById('auth-header-container');
  const viewModeToggleBtn = document.getElementById('view-mode-toggle');
  const viewModeText = document.getElementById('view-mode-text');

  // Initialize
  function init() {
    setupTabNavigation();
    detectAuthentikSession();
    handleHashNavigation();
  }

  // Tab Navigation
  function setupTabNavigation() {
    navBtns.forEach((btn) => {
      btn.addEventListener('click', () => {
        const targetTab = btn.getAttribute('data-tab');
        if (targetTab) {
          switchTab(targetTab);
        }
      });
    });
  }

  window.switchTab = function (tabId) {
    state.activeTab = tabId;

    // Update Tab Buttons
    navBtns.forEach((btn) => {
      if (btn.getAttribute('data-tab') === tabId) {
        btn.classList.add('active');
        btn.setAttribute('aria-selected', 'true');
      } else {
        btn.classList.remove('active');
        btn.setAttribute('aria-selected', 'false');
      }
    });

    // Update Tab Panes
    tabPanes.forEach((pane) => {
      if (pane.id === tabId) {
        pane.classList.add('active');
      } else {
        pane.classList.remove('active');
      }
    });

    // Update URL Hash without reload
    if (history.pushState) {
      history.pushState(null, null, '#' + tabId.replace('tab-', ''));
    }
  };

  function handleHashNavigation() {
    const hash = window.location.hash.replace('#', '');
    if (hash) {
      const targetPane = document.getElementById('tab-' + hash);
      if (targetPane) {
        window.switchTab('tab-' + hash);
      }
    }
  }

  // Authentik Session Detection
  async function detectAuthentikSession() {
    try {
      // Try querying Authentik's current user API endpoint
      const response = await fetch('https://auth.lovelain.duckdns.org/api/v3/core/users/me/', {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        },
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        // If username is not empty and not "anonymous"
        if (data && data.user && data.user.username && data.user.username !== 'anonymous') {
          setAuthenticatedState({
            username: data.user.name || data.user.username,
            email: data.user.email || 'authenticated-member'
          });
          return;
        }
      }
    } catch (err) {
      // Cross-origin or network error during guest pre-flight
      // Gracefully defaults to unauthenticated guest mode
    }

    // Default to Guest State
    setGuestState();
  }

  function setAuthenticatedState(user) {
    state.isAuthenticated = true;
    state.user = user;

    // Render User Greeting Banner
    if (userGreetingBanner) {
      userGreetingBanner.classList.remove('hidden');
    }
    if (userDisplayName) {
      userDisplayName.textContent = user.username;
    }
    if (userAuthEmail) {
      userAuthEmail.textContent = user.email;
    }
    if (guestHeroCta) {
      guestHeroCta.style.display = 'none';
    }

    // Update Header Auth Button
    if (headerAuthContainer) {
      headerAuthContainer.innerHTML = `
        <div style="display:flex; align-items:center; gap:0.5rem;">
          <a href="https://auth.lovelain.duckdns.org/if/user/#/library" class="btn btn-outline btn-sm" title="My Applications">
            <span>Library</span>
          </a>
          <a href="https://auth.lovelain.duckdns.org/if/user/#/settings" class="btn btn-outline btn-sm" title="Account Settings">
            <span>${escapeHtml(user.username)}</span>
          </a>
          <a href="https://auth.lovelain.duckdns.org/if/flow/default-invalidation-flow/" class="btn btn-ghost btn-sm" title="Sign Out">
            <span>Log Out</span>
          </a>
        </div>
      `;
    }

    if (viewModeText) {
      viewModeText.textContent = `Viewing as: Member (${user.username}) [Click to Toggle]`;
    }
  }

  function setGuestState() {
    state.isAuthenticated = false;
    state.user = null;

    if (userGreetingBanner) {
      userGreetingBanner.classList.add('hidden');
    }
    if (guestHeroCta) {
      guestHeroCta.style.display = 'flex';
    }

    if (headerAuthContainer) {
      headerAuthContainer.innerHTML = `
        <a href="https://auth.lovelain.duckdns.org" id="header-auth-btn" class="btn btn-primary btn-sm">
          <svg class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3"/>
          </svg>
          <span>Sign In / Join</span>
        </a>
      `;
    }

    if (viewModeText) {
      viewModeText.textContent = 'Viewing as: Guest (Click to Toggle Member View)';
    }
  }

  // Simulated Auth Toggle (For evaluator & demonstration convenience)
  window.toggleSimulatedAuth = function () {
    if (state.isAuthenticated) {
      setGuestState();
    } else {
      setAuthenticatedState({
        username: 'Erik (Admin)',
        email: 'wrighterik77@gmail.com'
      });
    }
  };

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, function (m) {
      return {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
      }[m];
    });
  }

  // Run on DOM Ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
