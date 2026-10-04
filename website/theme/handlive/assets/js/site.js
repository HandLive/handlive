// Mobile menu toggle. Without JavaScript the navigation stays visible (see .hl-js in site.css).
(function () {
  document.documentElement.classList.add('hl-js');
  var toggle = document.querySelector('.hl-menu-toggle');
  var nav = document.getElementById('hl-nav');
  if (!toggle || !nav) return;
  toggle.addEventListener('click', function () {
    var open = toggle.getAttribute('aria-expanded') === 'true';
    toggle.setAttribute('aria-expanded', String(!open));
    nav.classList.toggle('is-open', !open);
  });
  // Same-page links (Features) leave the menu open behind them otherwise.
  nav.addEventListener('click', function (event) {
    if (event.target.closest('a')) {
      toggle.setAttribute('aria-expanded', 'false');
      nav.classList.remove('is-open');
    }
  });
  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && nav.classList.contains('is-open')) {
      toggle.setAttribute('aria-expanded', 'false');
      nav.classList.remove('is-open');
      toggle.focus();
    }
  });
})();
