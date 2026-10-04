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
