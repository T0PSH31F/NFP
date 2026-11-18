// LoveLain Wired Directory Client
(function () {
  'use strict';

  const navBtns = document.querySelectorAll('.nav-btn');
  const categorySections = document.querySelectorAll('.category-section');
  const userDisplayName = document.getElementById('user-display-name');
  const headerUserName = document.getElementById('header-user-name');
  const userAuthEmail = document.getElementById('user-auth-email');
  const userTierBadges = document.getElementById('user-tier-badges');
  const adminDashLink = document.getElementById('admin-dash-link');
  const footerAdminLink = document.getElementById('footer-admin-link');
  const footerAdminSep = document.getElementById('footer-admin-sep');
  const wiredPhraseEl = document.getElementById('wired-phrase');

  const WIRED_PHRASES = [
    "[let's all love lain]",
    "[present day, present time]",
    "[no matter where you go, everyone is connected]",
    "[close the world, open the next]",
    "[⌈いとをひく⌋]"
  ];

  function setupCategoryFilter() {
    navBtns.forEach((btn) => {
      btn.addEventListener('click', () => {
        const selected = btn.getAttribute('data-category') || 'all';
        navBtns.forEach((b) => b.classList.toggle('active', b === btn));
        categorySections.forEach((section) => {
          const cats = (section.getAttribute('data-category') || '').split(/\s+/);
          const matches = selected === 'all' || cats.includes(selected);
          section.classList.toggle('hidden', !matches);
        });
      });
    });
  }

  function setupWiredPhraseTicker() {
    if (!wiredPhraseEl) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    let idx = 0;
    window.setInterval(() => {
      idx = (idx + 1) % WIRED_PHRASES.length;
      wiredPhraseEl.textContent = WIRED_PHRASES[idx];
    }, 3600);
  }

  function renderGroupBadges(groupsStr) {
    if (!userTierBadges) return;
    const rawGroups = groupsStr
      .split('|')
      .map((g) => g.trim())
      .filter((g) => g && g !== 'authentik Admins');

    userTierBadges.textContent = '';
    rawGroups.forEach((groupName) => {
      const span = document.createElement('span');
      span.className = 'tier-pill';
      span.textContent = groupName;
      userTierBadges.appendChild(span);
    });
  }

  function applyUserInfo(user) {
    const display = (user.name || user.username || 'Member').trim();
    const email = (user.email || user.username || 'Authenticated SSO Member').trim();
    const groups = String(user.groups || '');

    if (userDisplayName && display) userDisplayName.textContent = display;
    if (headerUserName && display) headerUserName.textContent = display;
    if (userAuthEmail && email) userAuthEmail.textContent = email;

    renderGroupBadges(groups);

    const isAdmin = groups.includes('NFP Admins') || groups.includes('authentik Admins');
    if (isAdmin) {
      if (adminDashLink) adminDashLink.classList.remove('hidden');
      if (footerAdminLink) footerAdminLink.classList.remove('hidden');
      if (footerAdminSep) footerAdminSep.classList.remove('hidden');
    }
  }

  async function loadCurrentUser() {
    try {
      const resp = await fetch('/api/me', { credentials: 'same-origin' });
      if (resp.ok) {
        const data = await resp.json();
        if (data && (data.username || data.email || data.name)) {
          applyUserInfo(data);
        }
      }
    } catch (_) {
      // Fallback gracefully to default greeting
    }
  }

  function init() {
    setupCategoryFilter();
    setupWiredPhraseTicker();
    loadCurrentUser();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
