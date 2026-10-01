# Report: brand identity 1.0

Date 2026-10-01. Plan: [../plan.md](../plan.md).

## Commits (branch `feat/brand-identity`, local, not pushed)

| Repo | Commit | What |
|---|---|---|
| handlive-shared | `204ba12` | `brand-*` token values (dawn palette, 4 appearances); usage notes rewritten |
| handlive-apple | `a0675fd` | Regenerated design tokens (colorsets, `HLColorToken.swift`, `HLTextStyle.swift`) |
| handlive-apple | `ac265ba` | `AppIcon.appiconset` (iOS any/dark/tinted 1024; macOS 16–512 pt @1x/@2x); `project.yml` names it for both targets |
| handlive-apple | `14c8a7b` | `GroupedList.swift`: the comment on icon-tile colors gives the product reason for avoiding blue |
| handlive-android | `d266ef2` | Adaptive launcher icon (background, foreground, monochrome); manifest `icon` + `roundIcon`; blue placeholder removed |
| handlive (hub) | this branch | Brand guidelines, `docs/brand/assets/`, `tools/brand/`, design-system docs, README hero, CHANGELOG, `tokens.json` copy |

`shared/` changed: Android and Apple must re-run token tests (done here, see below); relay unaffected.

## Verification

- Apple: `generate-design-tokens.py --check` OK (80 files); `HLDesignSystem` tests 24/24 pass
  (`xcodebuild test`, macOS); `actool` compiles `AppIcon` for macOS 13 (`AppIcon.icns`) and iOS 16
  (iPhone + iPad) with no warnings.
- Android: `./gradlew :core:design:testDebugUnitTest :app:assembleFossDebug` pass (JDK 21, offline).
- Hub: `check_bilingual_docs.py` 71 pairs, `validate_design_docs.py` 18 files, both `problems=0`.
- Contrast (new values): `brand-fire` 4.16:1 on white, 3.73:1 on `brand-glow` (large text only, as
  before); Dark 5.2–7.8:1, Dark IC 5.4–9.4:1.

## Not verified

- App icons on real devices / Dock / launcher (only compiled). macOS 26+ shows asset-catalog icons; the
  Liquid Glass look needs an Icon Composer `.icon` (follow-up).
- Android lint not run.
- CI not triggered (branches not pushed).

## Unresolved questions

1. Merge and push the four `feat/brand-identity` branches, and in which order (shared first)?
2. Should the apps show the logo image on the welcome/About screens (code change in apple/android)?
3. Republish the design-system artifact now or after merge?

Status: DONE_WITH_CONCERNS
Summary: Brand 1.0 delivered and wired into both apps on local branches; builds and tests pass.
Concerns/Blockers: not pushed or merged; Icon Composer `.icon` and in-app logo are follow-ups.
