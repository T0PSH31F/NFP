// LoveLain Media & Gaming Directory Client
(function () {
  'use strict';

  const navBtns = document.querySelectorAll('.nav-btn');
  const categorySections = document.querySelectorAll('.category-section');
  const userDisplayName = document.getElementById('user-display-name');
  const headerUserName = document.getElementById('header-user-name');
  const userAuthEmail = document.getElementById('user-auth-email');
  const adminDashLink = document.getElementById('admin-dash-link');
  const footerAdminLink = document.getElementById('footer-admin-link');

  function setupCategoryFilter() {
    navBtns.forEach((btn) => {
      btn.addEventListener('click', () => {
        const selected = btn.getAttribute('data-category') || 'all';
        navBtns.forEach((b) => b.classList.toggle('active', b === btn));
        categorySections.forEach((section) => {
          const matches = selected === 'all' || section.getAttribute('data-category') === selected;
          section.classList.toggle('hidden', !matches);
        });
      });
    });
  }

  function applyUserInfo(user) {
    const display = (user.name || user.username || 'Member').trim();
    const email = (user.email || user.username || 'Authenticated SSO Member').trim();
    const groups = String(user.groups || '');

    if (userDisplayName && display) userDisplayName.textContent = display;
    if (headerUserName && display) headerUserName.textContent = display;
    if (userAuthEmail && email) userAuthEmail.textContent = email;

    const isAdmin = groups.includes('NFP Admins') || groups.includes('authentik Admins');
    if (isAdmin) {
      if (adminDashLink) adminDashLink.classList.remove('hidden');
      if (footerAdminLink) footerAdminLink.classList.remove('hidden');
    }
  }

  async function loadCurrentUser() {
    try {
      const resp = await fetch('/api/me', { credentials: 'same-origin' });
      if (resp.ok) {
        const data = await resp.json();
        if (data && (data.username || data.email || data.name)) {
          applyUserInfo(data);
          return;
        }
      }
    } catch (_) {
      // Fallback gracefully to default greeting
    }
  }

  function init() {
    setupCategoryFilter();
    loadCurrentUser();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
