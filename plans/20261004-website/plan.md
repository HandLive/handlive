# Product website and blog (WordPress, EN/VI)

Status: **done locally** on hub branch `feat/website` (based on the brand branch); not deployed, not pushed.
Runbook: [docs/website.md](../../docs/website.md). Report: [reports/website-report.md](reports/website-report.md).

## Owner decisions (2026-10-04)

| Topic | Decision |
|---|---|
| Location | Inside the hub repository, `website/` |
| License | `website/` is GPL-2.0-or-later (WordPress theme); everything else stays Apache-2.0 |
| Multilingual | Polylang (free): English at `/`, Vietnamese at `/vi/` |
| Server | nginx + PHP-FPM (+ MariaDB), Docker |
| Downloads | WordPress FPM and CLI images, Polylang: approved. Inter font: declined (body text uses the system font) |

## Design choices

- Classic theme with `theme.json`, content in the block editor: the owner edits pages and posts in WordPress;
  the theme keeps structure and brand styles. Theme strings translated in `languages/vi.l10n.php`.
- Seeded content (landing page, Privacy from `docs/privacy*.md`, two posts per language) is idempotent.
- No external requests (self-hosted font and images, no analytics); WordPress core language packs are not
  installed (Vietnamese dates are numeric).

## Layout revision (2026-10-04, evening)

Owner found the first layout dull and pointed to xermius.com. Decisions: keep automatic light/dark (no
dark-first), download Be Vietnam Pro ExtraBold and Black (OFL) for display titles, real screenshots only (no
HTML mockups). Result: centered hero with two-tone title, stats row, framed screenshot, monospace eyebrows and
tags, icon tiles, numbered steps, platform chips, scroll reveal.

## Follow-ups (not started)

1. Deploy to `handlive.app`: host, TLS, backups (runbook "Going live").
2. Set `github-social-preview.png` on the GitHub repositories; link the site from the apps' About screens.
3. When the store builds exist, replace "Get the Beta" links with store badges.
