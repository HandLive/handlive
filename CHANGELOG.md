# Changelog

All notable changes to the HandLive hub (docs and plans) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- iPhone and iPad keep their session up to `IOS_BACKGROUND_GRACE` (25 s, or what iOS grants minus 5 s) after the app
  goes to the background, instead of closing at once (CONN-02 E3, 00-common-specs): a quick switch to another app no
  longer drops the connection. Notification actions share the same hold; a clip that arrives while held is written only
  if the user copied nothing new (CLIP-04 E2, `changeCount`); SMS and calls in that window raise local notifications
  under the same content rules as the push path. Longer background sync is not possible on iOS: SMS and call alerts
  while away need the relay and APNs (gate G2). Code: apple #4.
- Android, Auto-Send on Copy (SET-02 field 39, E10): tapping the switch while it reads "Auto-send isn't on yet" opens an
  action sheet (Turn On, Send Manually, Cancel) instead of turning automatic sending off silently. Strings:
  handlive-shared#5; code: android #7.

- Clipboard HTML (CLIP-01 API 5 `html`, 0.7.2 `text/html` in `features.clipboard.mimes`, 0.10 `CLIP_MAX_HTML`): a text clip
  carries the sanitized HTML of its text when the peer lists `text/html`, so an article copied in a browser on the phone pastes
  in Notes, Pages, Word or Mail with its headings, links and pictures (fetched from their URLs by the pasting app). Both ends run
  the same `HtmlClipSanitizer`, pinned by `shared/test-vectors/clipboard-html.json`; identity, loops, conflicts and the
  sensitive-content rules still look at the plain text. Plan: `plans/20261005-clipboard-html/plan.md`.
- `release-collect` (hub workflow): the APK, the iOS IPA and the Mac DMG of a version tag, with their SHA-256, are
  copied from the handlive-android and handlive-apple Releases into the hub's Release after a checksum check, so users
  download every platform from one page (`docs/deployment-guide.md`, Release builds). Done for `v0.1.0-beta.2`.

### Changed

- Website: the home page badge names `v0.1.0-beta.2` and opens its release; `docs/website.md` lists it among the
  places to change on each release.

### Fixed

- Calls from other apps, CALL-05 (en and vi): the Mac panel names the calling app ("Telegram Call") instead of its
  package name; Android 11+ hid the app from HandLive until the call feature declared a launcher-intent `<queries>`
  (not `QUERY_ALL_PACKAGES`). On Android 14+, swiping the app's in-call notification away no longer ends the call on
  the Mac: only the app's own removal means `ended`; a swiped call stays `ongoing` with End hidden while the phone is in
  communication mode and ends as `unknown` when it leaves it (E11; below API 31, or outside that mode, it ends as
  `unknown` at once); only a later in-call notification of the same app (`CallStyle` or category `call`) re-attaches
  the call and brings End back, so End never fires another notification's action (an upload's Cancel). Code:
  android #8; spec: hub #15. Owner check on the S25 pending.
- Setup, SET-01 (en and vi): an Android 13+ phone that installed HandLive outside Google Play no longer stays silent
  when Android's restricted setting keeps the Accessibility service (automatic clipboard sending) or Notification
  access (calls from other apps) off. The user who comes back from that system page without turning HandLive on sees
  field 14 again, once per return, with Open Settings for App info; the disclosure is asked only once (SET-02 field 2,
  CLIP-01 A1), and the first Agree is no longer lost when the disclosure closes. HandLive cannot read Android's own
  verdict (the app op needs `GET_APP_OPS_STATS`, Android 15 answers `SecurityException`), so the rule stays the install
  source. Code: android #6. Report:
  `plans/20260925-implementation/reports/restricted-settings-detect-2026-10-05.md`.
- Clipboard, CLIP-01 API 2 logic 2 and CLIP-03 API 1 logic 1 (en and vi): an Android item whose URI is an image is the
  copied image even when the source app put the image's URL, its alt text or an empty string beside it; the text rule
  came first before, so such copies went out as text or were dropped. CLIP-03 E10: a URI the clipboard never let the
  phone read is told on Send Clipboard ("Couldn't read the image") and logged as `clip_read_failed` in debug builds.
  Code: android `fix/clipboard-image-item-precedence`; e2e coverage for phone → Mac images: shared
  `feat/e2e-phone-to-mac-image`. Investigation: `plans/20261005-clipboard-image-sync-fix/plan.md`.
- Delete All on the Mac deletes HandLive's keys in both keychains (SET-02 API 7 logic 6, en and vi), so a user who ran
  both the ad-hoc signed download (login keychain) and a team-signed build (data-protection keychain) keeps neither
  build's `ik_sig`, `ik_dh`, `db_key` or pair keys; login-keychain items travel in backups and Migration Assistant
  (security scan of 2026-10-04, LOW). 0.6.1: the login keychain is deleted with `SecKeychainItemDelete`, since
  `SecItemDelete` answers errSecInvalidOwnerEdit (-25244) for items another code signature created, which also kept an
  updated ad-hoc build from erasing or starting over; SET-03 API 1 logic 1 keeps the fresh-install cleanup to this
  build's keychain; PAIR-03 names the call. Code: apple `fix/erase-both-keychains`.

### Security

- Calls from other apps (CALL-05 API 1 logic 6): "Answer" from the Mac starts the app from the background only for a
  call Android vouches for (from Android 14: a foreground service, a user-initiated job or a granted full-screen
  intent; Android 12–13: any `CallStyle` notification; Android 10–11: never); any other call is answered through the
  phone's "tap to answer" notification.
- Android release signing: the secrets moved to the environment `release`, limited to tags `v*` and `main`; a new
  release key (`CN=Ho Xuan Dung, O=HandLive, C=VN`) replaced the first one before any user installed it.

## [0.1.0-beta.2] — 2026-10-04

### Added

- The brand mark on the welcome screens of the Mac, iPhone/iPad and Android apps (apple and android
  `feat/brand-in-app`), generated into both repositories by `tools/brand/build_brand_assets.py`.

- `docs/deployment-guide.md` (en, vi): Release builds — tag-driven `release-android` (signed `foss` APK) and
  `release-apple` (unsigned iOS IPA; ad-hoc signed Mac DMG, or a Developer ID notarized one once the paid team's secrets
  exist); Mac builds without a team signature keep their keys in the login keychain (0.6.1); how to cut a release,
  rebuild an existing tag, and the secrets the owner creates.
- CALL-05 (calls from other apps): `AppCallListenerService` (`NotificationListenerService`) reads Telegram and other calling apps' notifications on Android and sends them to the Mac; the user can answer, decline or end from the Mac (audio stays on the phone in v1). Requires Notification access, a special access the user enables by hand. Cellular calls unchanged.
- Product website and blog (`website/`, `docs/website.md`): WordPress on nginx + PHP-FPM + MariaDB in Docker,
  English at `/` and Vietnamese at `/vi/` with Polylang, a theme in the brand's dawn colors with light and dark
  appearance, a landing page, a Privacy page built from `docs/privacy.md`, and two blog posts per language.
  `website/` is GPL-2.0-or-later.
- Brand identity 1.0: `docs/brand-guidelines.md` (story: a signal fire at dawn; voice, messages, logo, app
  icon, colors, promo images) and its files in `docs/brand/assets/`, generated by
  `tools/brand/build_brand_assets.py`. Tagline: "Never miss a signal." README hero images in English and
  Vietnamese.
- App icons from the brand files: the macOS and iOS AppIcon set (apple `feat/brand-identity`) and the Android
  adaptive launcher icon replacing the blue placeholder (android `feat/brand-identity`).

### Changed

- Brand palette: the `brand-*` tokens take dawn values (handlive-shared `feat/brand-identity`, Apple tokens
  regenerated); the design-system branding pages describe the new logo and palette.
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
- Android: the last rows of Settings and the other grouped lists ended under the floating tab bar; the Devices tab
  without a paired phone crashed when a status banner showed, and its Add Device button could hide under the tab bar in
  a short window.
- Mac and iPhone/iPad: "Last synced" read "in 0 seconds" right after a sync; it now reads "now" under a minute.

### Security

Security scan of every change since v0.1.0-beta.1 (no critical or high finding):

- Android, calls from other apps: a notification counts as a call only with the platform `CallStyle` template (API
  31+), which Android posts only with a foreground service, a user-initiated job or a full-screen intent request.
  Before, any app could fake a call with the bare `android.callType` extra and, when answered from the Mac, have its
  own activity started from the background with HandLive's exemption. Still open: below API 31, and for an app that
  posts a real `CallStyle` notification. CALL-05 API 3 logic 1 updated.
- Website: nginx denies the WordPress web installer and `setup.sh` starts nginx only after WP-CLI installed WordPress,
  so no one can create the admin during a first setup; the admin's login name no longer shows in the feed or oEmbed;
  Polylang updates itself; `docs/website.md` explains the login limit behind a reverse proxy.
- Apple release workflow: the ad-hoc DMG is signed and launched in the read-only build job; the Developer ID app is
  launched only after the signing keychain and notary key are removed, without secrets in its environment (the job
  still holds them in memory: splitting it is planned before those secrets exist); XcodeGen is pinned by checksum.
  `docs/deployment-guide.md` updated.

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
