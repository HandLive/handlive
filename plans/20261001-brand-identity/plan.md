# Brand identity 1.0 (signal fire at dawn)

Status: **done** on branches `feat/brand-identity` (hub, shared, android, apple); not merged, not pushed.
Owner sessions: 2026-10-01. Report: [reports/brand-identity-report.md](reports/brand-identity-report.md).

## Owner decisions (2026-10-01)

| Topic | Decision |
|---|---|
| Scope | Redo the brand from the start: story, voice, messages, logo, app icon, guidelines, promo images |
| Story | Product-first: what happens on the phone shows up on your screen; the logo pictures it as a signal fire on a mountaintop |
| Logo | "Signal" variant: one mountain, a flame above the summit, two pairs of signal rings |
| Colors | The first proposal (ember red on red) was rejected as muddy; owner chose the "Dawn" direction: cream sky, plum mountain, flame red → orange → amber, plus the rings |
| Tagline | "Never miss a signal." / "Không bỏ lỡ tín hiệu nào." |
| App icons | Wire into the apps now (Android adaptive icon, Apple AppIcon set), not only source files |
| Font | Be Vietnam Pro Bold downloaded (OFL) only to outline text; the font file is not committed |

## Consequences

- `brand-*` token names unchanged, values changed (shared first, then Apple regenerated; Android generates at
  build). `accent` green unchanged.
- Apple: AppIcon.appiconset (not an Icon Composer `.icon`): `ictool` is undocumented and XcodeGen support for
  `.icon` bundles is unverified; the set compiles with `actool` for macOS 13+ and iOS 16+.

## Deliverables

- `docs/brand-guidelines.md` + `.vi.md`; `docs/brand/assets/` (logo, app icon, promo); `tools/brand/`.
- Design-system docs updated (story, palette, contrast numbers, app icon section).

## Follow-ups (not started)

1. Icon Composer `.icon` from `docs/brand/assets/app-icon/icon-composer/` for Liquid Glass on macOS/iOS 26+.
2. Show the logo (lockup image) on the welcome screen and in the About window (apps still show the text
   wordmark in `brand-fire`).
3. Republish the "HandLive Design System" artifact from `docs/design-system/`.
4. Upload `github-social-preview.png` as the social preview of each GitHub repository; attach the beta banner
   to the `v0.1.0-beta.1` release notes.
