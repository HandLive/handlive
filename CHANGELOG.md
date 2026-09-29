# Changelog

All notable changes to the HandLive hub (docs and plans) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0-beta.1] — 2026-09-30

First coordinated public beta across the HandLive workspace.

### Added

- Hub `README.md` / `README.vi.md`: clearer Status table, shorter roadmap cells, and a link to this beta.
- App version bumps for the beta tag: Android `0.1.0-beta.1` (versionCode 2), Apple marketing `0.1.0`.

### Included in this beta (code on `main`)

- Phase 0–3: clipboard sync, SMS bridge, iOS app shell, Rust relay, call metadata and control.
- Real-device QR pairing fixes (Galaxy S25 Ultra ↔ Mac, 2026-09-30).
- G6 web-spike HOME leave fix on Android 16 (spike only; product cards not started).

### Not in this beta

- Call audio (Phase 4 / G4), virtual camera/mic (Phase 5 / G5), Continue Browsing product (Phase 6).
- App Store / Play Store distribution; gates **G1** and **G2** remain open.
- Production APNs / FCM / hosted relay credentials (owner inputs).

### Coordinated commits

| Repository | Tag | Commit |
|------------|-----|--------|
| [handlive](https://github.com/HandLive/handlive) | `v0.1.0-beta.1` | (hub release commit) |
| [handlive-android](https://github.com/HandLive/handlive-android) | `v0.1.0-beta.1` | `60435aa` |
| [handlive-apple](https://github.com/HandLive/handlive-apple) | `v0.1.0-beta.1` | `0ce7f4b` |
| [handlive-shared](https://github.com/HandLive/handlive-shared) | `v0.1.0-beta.1` | `1536980` |
| [handlive-relay](https://github.com/HandLive/handlive-relay) | `v0.1.0-beta.1` | `cda13bf` (`main`) |

## [2026-09-30]

### Changed

- Hub `README.md` / `README.vi.md`: live roadmap progress table vs the implementation plan, plus a hard rule to
  update that table whenever a concrete task finishes. Matching snapshot in `docs/project-roadmap*.md`.
- Handoff (`CLAUDE.md`, `real-device-session-2026-09-29.md`): real-device QR pairing S25 Ultra ↔ Mac is stable and
  on `main`; Settings/Pair bring-forward fixed; G6 HOME on Android 16 verified (`inactive reason=left`).

### Fixed

- G6 spike report: document the HOME leave fix on `fix/g6-home-android16` (now on android `main`).
