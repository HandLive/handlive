English | [Tiếng Việt](website.vi.md)

# Website

The product site and blog for HandLive, in English and Vietnamese. It runs WordPress on nginx and PHP-FPM
with MariaDB, all in Docker; the code lives in `website/` of this repository.

## Overview

| Part | What it is |
|---|---|
| Stack | `website/docker-compose.yml`: `nginx:alpine` → `wordpress:php8.3-fpm-alpine` → `mariadb:10.11`; a `wpcli` service for setup |
| Theme | `website/theme/handlive/`: a classic theme with `theme.json`; pages and posts are written in the block editor |
| Languages | Polylang: English at `/`, Vietnamese at `/vi/`; every page and post is linked to its translation |
| Content | `website/seed/content/`: home page and blog posts as block markup per language, `site.json` lists them |
| Privacy page | Built from `docs/privacy.md` and `docs/privacy.vi.md` by `website/bin/build_privacy_content.py` |
| Brand files | Copied from `docs/brand/assets/` by `website/bin/sync-brand-assets.sh` |
| License | `website/` is GPL-2.0-or-later, as WordPress requires of themes; the rest of HandLive stays Apache-2.0 |

## Running it locally

```bash
website/bin/setup.sh
```

- Needs Docker (OrbStack or Docker Desktop) and Python 3.
- The first run creates `website/.env` from `.env.example` with random passwords (git-ignored), starts the
  stack, installs WordPress and Polylang, activates the theme, and seeds the content.
- The site is at http://localhost:8080; the admin is at `/wp-admin/` with the user and password from
  `website/.env`.
- Rerunning is safe: pages and posts are matched by slug and updated in place, media by its source path.
  Edits made in the admin to seeded pages are overwritten by the next run.

## Pages and URLs

| Page | English | Vietnamese |
|---|---|---|
| Home | `/` | `/vi/` |
| Privacy | `/privacy/` | `/vi/quyen-rieng-tu/` |
| Blog | `/blog/` | `/vi/bai-viet/` |
| Post | `/<slug>/` | `/vi/<slug>/` |

Polylang adds `hreflang` links between translations; the theme adds the description and Open Graph tags
(the GitHub social preview image, or the post's featured image).

## Writing and translating

- Blog posts: write them in the admin (Posts → Add New), set the language in the Languages box, then use
  the + next to the other language to create the translation. Use the "News" / "Tin tức" category.
- Theme text (menu, footer, buttons): English in the PHP templates, Vietnamese in
  `website/theme/handlive/languages/vi.l10n.php`; add a line there for every new string.
- Vietnamese copy follows the brand guidelines: Apple-style diacritics and the design system's terms
  ([Brand guidelines](brand-guidelines.md)).
- The landing page uses the theme's block classes: `hl-hero`, `hl-section`, `hl-section--tint`, `hl-grid`,
  `hl-card`, `hl-feature`, `hl-steps`, `hl-step`, `hl-shots`, `hl-table`, `hl-checks`, `hl-cta`.

## Design

- Colors, type, and voice follow the [brand guidelines](brand-guidelines.md): dawn background, plum text,
  Be Vietnam Pro headings (Black for titles, Bold for cards), system font for body text, the system monospace
  for section labels and tags, green buttons. Light and dark appearance: the site follows the system, and a
  toggle in the header lets the visitor choose; the choice is remembered in the browser (`localStorage`).
- Landing page layout: centered hero with the tagline as a two-tone title, a stats row and a framed real
  screenshot; sections with a monospace eyebrow, feature cards with icon tiles and category tags, numbered
  steps, platform chips, the compatibility table and the privacy checklist. Sections fade in on scroll
  (`.hl-reveal`; off with reduced motion).
- No third-party requests: fonts and images are served by the site itself, and there are no analytics.

## Going live

Not deployed yet. Before going live on `handlive.app`:

1. A host with Docker; set `SITE_URL=https://handlive.app` and `WP_ENVIRONMENT_TYPE=production` in `.env`.
2. TLS in front of nginx (a reverse proxy such as Caddy, or certificates mounted into nginx).
3. Backups of the `db` and `wordpress` volumes.
4. Run `website/bin/setup.sh` once, then manage content in the admin; rerun the seed only on purpose.
