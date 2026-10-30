# Changelog

All notable changes to the HandLive hub (docs and plans) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.0] — 2026-10-30

### Added

- **Offline connectivity (Phase 7):** when both devices are near each other without a network, they connect over Bluetooth
  L2CAP. The control channel (clipboard text, SMS and call notifications) carries message frames over a link-security layer
  (Noise-style handshake keyed by the shared pairing secret). No relay deployment in this release; scenario Y (phone on
  mobile data, Mac on another Wi-Fi) also uses Bluetooth when the two are near. First pairing over Bluetooth: QR scan brings
  up the credential, then the phone advertises a proof and waits for the Mac to establish the link, then the user can
  confirm the pairing value or enter a PIN over Bluetooth through CPace (constant-time password-authenticated key exchange,
  X25519, SHA-512).

- Bluetooth advertisement with a 128-bit service UUID and rotating hint (0.4.5 `BT_SERVICE_UUID`, `BT_HINT_PERIOD`,
  service data format frozen by test vectors in `shared/test-vectors/`); link-security handshake (Noise prologue,
  `challenge`, `noise1`, `noise2`) with frame codec (channel IDs, `more` flag, short and long control lanes, record
  length bounds); Bluetooth admission policy (link cap, pre-auth connection cap, authentication failure block) on both
  platforms (A-SVC advertiser on Android, CoreBluetooth central and peripheral on macOS).

- CPace password-authenticated key exchange for offline PIN pairing over Bluetooth (SP2, `CPACE-X25519-SHA512`): the shared
  secret is derived from the PIN at both ends without a third party; online guessing is limited to one attempt per channel,
  with a global per-PIN counter (three failures per PIN, then lockout); the spec and test vectors (cpace.json, Android
  Kotlin and macOS Swift implementations with constant-time arithmetic in `core/crypto` or `HLCrypto`).

- **State machine update (0.11):** the Mac's connection manager now starts connecting when Bluetooth is authorized and on,
  even without a network (new condition in the state machine); network loss ends LAN or relay sessions only, not Bluetooth
  (so scenario X stays connected). Routes are prioritized: LAN > Bluetooth (on the Mac), and all pre-auth errors (PAIR_UNKNOWN,
  PAIR_REVOKED, UNSUPPORTED_VERSION, AUTH_FAILED) are checked for TLS certification (`phoneAuthenticatedByTLS`), so only
  the pinned-TLS LAN route can unpair, remove pairs, or stop reconnecting (AC8).

- **Pre-auth admission and Bluetooth bans (0.4.5, 0.5):** every pre-auth frame on Bluetooth is checked against a device-global
  nonce challenge (issued once per connection attempt) and a link-key confirmation after the handshake. Failed confirmations
  increment a counter; after `BT_AUTH_FAIL_BLOCK` consecutive failures, the pre-auth channel is blocked for `BT_AUTH_FAIL_TIMEOUT`,
  preventing slot hogging and replay attacks.

- **Bluetooth prompts (AC7):** Android 12+ — decision logic for the one-time "Nearby devices" prompt (SET-01) and a
  re-ask interval for enabling Bluetooth when there is no LAN; macOS — the system Bluetooth permission dialog
  (`NSBluetoothAlwaysUsageDescription`) before scanning starts (SET-03). iOS prompts inherited from the existing Mac
  integration.

- **Hub and shared assets for Phase 7:** detailed design spec updates (00-common-specs.md, 01-setup-settings.md, 02-pairing.md,
  03-connectivity.md, 04-clipboard.md, all en and vi); test vectors for link-security, frame codec, advertisement and CPace;
  new UI strings for the "Connected via Bluetooth" label and the Mac Bluetooth permission prompt text.

### Changed

- Device label in the connection status: "Connected via Bluetooth" appears on both Android and Mac when the active route is
  Bluetooth (`core/design`'s `HLConnectionStatus` + `ui/devices` for Android, `HLMacUI`/`HLiOSUI` for Apple).

- Android foreground service `connectedDevice` (A-SVC): now advertises the Bluetooth service UUID and rotates the hint with the
  shared secret, independent of the LAN server; the existing `ControlServer.serveRelayPeer` pattern is extended to `serveBluetoothPeer`
  for `SessionTransport.BLUETOOTH`.

- macOS and iOS connection manager: `ConnectionManager` now routes to `.bluetooth` alongside `.relay`, with upgrades from Bluetooth
  to LAN when a network appears; `ControlSession` enforces the pre-auth rule `phoneAuthenticatedByTLS` (originally only checking
  `route == .relay`).

### Fixed

- ~~Relay routes kept in the code but not deployed; the `relay` constant and existing relay code paths are left untouched~~ (no
  changes here; relay is intact for future gates G4, G5, G6 or if scenario Y demands it in a later phase).

### Security

- Offline pairing (PAIR-01 flow B and C): no pre-shared public key (QR-encoded `pr`) is required; the proof is an HMAC of the
  pairing secret, and every pairing frame on a secured Bluetooth link is MAC'd with the link key before a slot is granted (D7.1).
  PIN guessing is limited by the per-PIN counter (3 attempts, then lockout), and the CPace exchange runs at each attempt with the
  PIN as the shared secret, so no stable state is exposed to a passive sniffer (AC9, `K_bt_pin` never leaves the channel).

- Bluetooth link-security (D7.1 0.4.5): an unbonded L2CAP CoC link is encrypted with a Noise-style handshake keyed by the shared
  pairing secret (`K_bt_disc` and `K_bt_link`, derived once per link and rotated at an interval); link-layer encryption is
  assumed to be absent (no bond), so frame-level encryption is mandatory. The prologue is bound to the peer's rotating hint and
  the sender's discovery key, so a replayed or cloned advertiser cannot form a valid handshake (AC9).

- Pre-auth errors (CONN-01 E4, CONN-03 E9): forged PAIR_UNKNOWN, PAIR_REVOKED, UNSUPPORTED_VERSION or AUTH_FAILED on Bluetooth
  cannot unpair, remove a pair, or stop reconnecting — only the pinned-TLS LAN route is exempt from this rule (AC8).

### Specs

Designed in the Phase 7 detailed-design update (00-common-specs.md 0.4.6/0.4.7, 01-setup-settings.md) but not implemented
on either platform yet — tracked for a later release:

- **Wi-Fi Direct** (A7.5 / M7.5): randomly-generated SSID and passphrase per group, the Mac socket bound to the P2P
  interface only, and the Android 10–12 Location prompt it needs. No Android or Apple code exists for this today.
- **Per-connection bulk stream keys** (`K_bulk` and nonces, A7.4 / M7.4): a bulk transfer (images via CLIP-03) with its own
  handshake and encryption keys per stream. Android's `core/transport` reserves channel `0x02` and the chunk/priority
  scheduler for this lane, but nothing encrypts or sends bulk content through it yet; there is no Apple code at all.
- **Bluetooth status UI beyond the connected label:** the Mac "Bluetooth off" / "Bluetooth denied" status lines, their
  settings button, the Bluetooth permission-primer screens and the Settings feature-card label all exist as strings in
  `handlive-shared/strings/ui-strings.json`, but no Android or Apple view calls them yet.

## [0.1.1] — 2026-10-22

### Added

- Release `v0.1.1`, the first tag without a pre-release suffix, on all five repositories: the hub's Release holds the
  signed `foss` APK, the unsigned iOS IPA and the ad-hoc Mac DMG with their SHA-256 (`release-collect`); README (en,
  vi), roadmap snapshot and the website's Get the Beta link and home page badge point at it. Android ships with its
  new application id `com.handlive.android`, so a beta install is not updated: remove it first, then pair again
  (handlive-android changelog). Security scan of everything since beta.3: 0 critical, 0 high, 0 medium, 1 low deferred
  (`plans/20260925-implementation/reports/security-scan-0.1.1-2026-10-22.md`).
- Google Play preparation: store listing text (en, vi) and the 1024×500 feature graphic (`docs/brand/`,
  `tools/brand/build_play_feature_graphic.py`), the Play Console guide, `tools/release/play-release.zsh` (merges the
  Android PR and dispatches `play-bundle`) and `tools/release/setup-fcm.zsh` (stores the FCM values as environment
  secrets; `google-services.json` is git-ignored).

### Changed

- Store screenshots: all 11 iOS App Store Connect screenshots recaptured on the iPhone 6.9" Simulator at the native
  1320×2868 size (was downscaled to a 1200px-tall gallery crop), and the 8 Android Play Console screenshots recaptured
  on a 1080×1920 emulator (was 540x1200, over Play's 2:1 max aspect ratio); the paired-device screens now show a real
  device name instead of the test pairing identity (`docs/screenshots/android/`, `docs/screenshots/ios/`).
- iPhone and iPad: the App Group is `group.app.hxd.handlive` (was `group.app.handlive`) and the Notification Service
  Extension's bundle id is `app.handlive.ios.notifications` (was `app.handlive.ios.nse`): both old identifiers are held
  by the free Personal Team used before the paid team and cannot be registered to it. The App Group is no longer
  listed under Keychain Sharing (an App Group name is a keychain access group by itself), and the extension no longer
  claims the Communication Notifications entitlement (Apple grants that capability to the app target only). A beta install updated to
  this build loses its settings and keys and must pair again; the Mac app and Android are unchanged.

### Security

- Clipboard images on Android: reading copied images now opens only items shared by other apps via a content provider;
  any other URI (file, resource, HandLive's own provider, or unresolved provider) is rejected with "Couldn't read the image"
  (android #13).

## [0.1.0-beta.3] — 2026-10-07

### Added

- iPhone, iPad and Mac: the app icon is an Icon Composer `AppIcon.icon` with Liquid Glass layers (signal rings, flame,
  mountain; light, dark and tinted) on iOS 26+ and macOS 26+, generated by `tools/brand/build_brand_assets.py
  --apple-icon`; older systems get the images Xcode derives from it. On the Mac this drops the compact mark at 16 and
  32 pt (owner decision 2026-10-07), and the icon set `AppIcon.appiconset` is gone. Building the Mac app now needs
  macOS 26 and Xcode 26+ (`actool` on a macOS 15 host crashes rendering a Mac `.icon`): CI and the release's signing
  job run on `macos-26`, the release's launch check stays on `macos-15`. Code: apple #7, #8; tooling and guidelines:
  hub #17, #19.
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

- Calls from other apps, CALL-05 (en and vi): the call feature declares a launcher-intent `<queries>` (not
  `QUERY_ALL_PACKAGES`) so the Mac panel names the calling app ("Telegram Call") even where Android hides other apps
  from HandLive; on an Android 15 emulator the notification listener already sees an app once it posts, so the query
  is a safeguard for other versions and OEM builds (Android 11–14 not measured). On Android 14+, swiping the app's
  in-call notification away no longer ends the call on the Mac: only the app's own removal means `ended`; a swiped
  call stays `ongoing` with End hidden while the phone is in communication mode and ends as `unknown` when it leaves
  it (E11; below API 31, or outside that mode, it ends as `unknown` at once); only a later in-call notification of the
  same app (`CallStyle` or category `call`) re-attaches the call and brings End back, so End never fires another
  notification's action (an upload's Cancel). Code: android #8; spec: hub #15. Owner check on the S25 pending.
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

- Clipboard HTML: the sanitizer runs in linear time on every platform and in the shared reference (shared #8, apple
  #10, android #12). Before, a page whose copied HTML held many unclosed tag starts or an unclosed quote took time
  quadratic in its size, so copying a large page froze the Mac or iPhone app while reading the clipboard; the output is
  unchanged, pinned by three new shared vectors and a timing test on each port. Found by the security scan before
  this release (`plans/20260925-implementation/reports/security-scan-beta3-2026-10-07.md`).
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
