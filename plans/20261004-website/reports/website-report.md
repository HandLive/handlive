# Report: product website and blog

Date 2026-10-04. Plan: [../plan.md](../plan.md). Branch: hub `feat/website` (local, not pushed).

## What was built

- `website/docker-compose.yml`: nginx:alpine → wordpress:php8.3-fpm-alpine (WordPress 7.1.2, PHP 8.3) →
  mariadb:10.11; `wpcli` service. nginx denies hidden files, `xmlrpc.php`, `wp-config.php`, PHP in uploads;
  security headers; 30-day static caching with file-mtime cache busting.
- Theme `website/theme/handlive/`: header (lockup, nav, EN/VI switcher, "Get the Beta"), footer, landing,
  page, post, blog list, 404; OG/description tags; light and dark; mobile menu.
- Polylang 3.8.10: `/` EN, `/vi/` VI front pages, translated Privacy and Blog pages, `hreflang` links.
- Seed: landing page (85 blocks per language), Privacy (from `docs/privacy*.md`, internal spec references
  removed), 2 posts per language with covers and the News / Tin tức category.

## Verification

- HTTP: all pages 200 in both languages with the right `lang` and `<title>`; 404 page translated;
  `xmlrpc.php` and `wp-config.php` 403.
- Block editor: 0 invalid blocks (home EN/VI 85 each, Privacy 39, post 11), checked in the browser with a
  temporary local admin session (destroyed afterwards).
- Visual: desktop 1280 and mobile 375, light and dark; mobile menu opens and closes.
- `php -l` on all theme and seed PHP, `bash -n` on scripts, `docker compose config`, `nginx -t`: all pass.
- Hub doc checks: bilingual 72 pairs and design docs, both `problems=0`.

## Not verified

- Production deployment (TLS, backups); performance under load; email (none configured).
- Screen readers beyond semantic markup checks.

## Unresolved questions

1. Hosting for `handlive.app`: which VPS, and should it share the relay host?
2. Should the site show store badges once builds are published, or keep linking to GitHub releases?

Status: DONE_WITH_CONCERNS
Summary: Bilingual WordPress site runs locally on nginx + PHP-FPM with seeded content; all checks pass.
Concerns/Blockers: not deployed; branch not pushed or merged.
