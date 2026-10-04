# Changelog

All notable changes to the HandLive hub (docs and plans) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- CALL-05 (calls from other apps): `AppCallListenerService` (`NotificationListenerService`) reads Telegram and other calling apps' notifications on Android and sends them to the Mac; the user can answer, decline or end from the Mac (audio stays on the phone in v1). Requires Notification access, a special access the user enables by hand. Cellular calls unchanged.

### Changed

- Merged remaining spike/fix branches into `main`: apple `fix/real-device-pairing`,
  `feat/phase-04-call-audio`, `feat/phase-05-camera-mic`, `feat/phase-06-web-handoff`; android
  `fix/real-device-pairing`. Relay local checkout moved to `main`. README roadmap updated.
- `CLAUDE.md`: progress report handoff of 2026-10-01 (done / in progress / plan next) for coding agents.
- Detailed design: CALL-05 spec (leaves 06-call-control, 00-common-specs, 01-setup-settings); capability formula for Mac app calls clarified.

### Fixed

- Mac and iPhone/iPad: after the Keychain lost HandLive's keys (or a build signed by another team was run), the app
  made new keys but kept its pair store and SMS database sealed with the old key, so it showed no phone while every
  new pairing failed to save (the phone said paired: a one-sided pair) and SMS stayed off. Such files now stay where
  they are and the app uses a second slot (`*.alt`), so switching back to the other build finds its data again; with
  a third key the older foreign file gives way (one generation). The user pairs again; the SQLCipher format is pinned
  (SET-03 API 1 logic 5).

### Compatibility note

- Versions v0.1.0-beta.1 and earlier on Mac and iOS: a new `NOTIFICATION_LISTENER` entry in `permissions_missing` will display as a generic "missing permission" hint until the app is updated to understand app calls. No action needed from the user.

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
| [handlive](https://github.com/HandLive/handlive) | `v0.1.0-beta.1` | `e3c2a63` |
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
