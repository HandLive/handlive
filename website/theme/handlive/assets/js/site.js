// Mobile menu toggle and scroll reveal. Without JavaScript the navigation stays visible and every
// section is shown at once (see .hl-js in site.css).
(function () {
  document.documentElement.classList.add('hl-js');

  var toggle = document.querySelector('.hl-menu-toggle');
  var nav = document.getElementById('hl-nav');
  if (toggle && nav) {
    var close = function () {
      toggle.setAttribute('aria-expanded', 'false');
      nav.classList.remove('is-open');
    };
    toggle.addEventListener('click', function () {
      var open = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!open));
      nav.classList.toggle('is-open', !open);
    });
    // Same-page links (Features) leave the menu open behind them otherwise.
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a')) close();
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && nav.classList.contains('is-open')) {
        close();
        toggle.focus();
      }
    });
  }

  // Appearance toggle: flips the effective appearance (system or chosen) and remembers it; the inline script in
  // <head> applies the stored choice before the first paint.
  var themeToggle = document.querySelector('.hl-theme-toggle');
  if (themeToggle) {
    var systemDark = window.matchMedia('(prefers-color-scheme: dark)');
    var effective = function () {
      return document.documentElement.getAttribute('data-theme') || (systemDark.matches ? 'dark' : 'light');
    };
    var reflect = function () {
      var dark = effective() === 'dark';
      themeToggle.setAttribute('aria-pressed', String(dark));
      document.querySelectorAll('meta[name="theme-color"]').forEach(function (meta) {
        meta.setAttribute('content', dark ? '#140c11' : '#fff6ee');
      });
    };
    themeToggle.addEventListener('click', function () {
      var next = effective() === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('hl-theme', next); } catch (e) { /* private mode: the choice lasts for this page only */ }
      reflect();
    });
    systemDark.addEventListener('change', reflect);
    reflect();
  }

  // Sections and cards fade up as they scroll into view; people who prefer reduced motion see them at once.
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var targets = document.querySelectorAll('.hl-reveal');
  if (reduce || !('IntersectionObserver' in window)) {
    targets.forEach(function (el) { el.classList.add('is-visible'); });
    return;
  }
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, { rootMargin: '0px 0px -10% 0px', threshold: 0.1 });
  targets.forEach(function (el) { observer.observe(el); });
})();
