English | [Tiếng Việt](deployment-guide.vi.md)

# HandLive — Deployment & Distribution

> No build pipeline yet. This is the distribution plan following decisions D5/D7/D8 in the original plan.

## Android app

- **Play Store:** needs the Permissions Declaration Form for `READ_SMS` /`SEND_SMS`/`READ_CALL_LOG` under
  the "Cross-device synchronization or transfer of SMS or calls" exception, plus a declaration of
  Accessibility API use (D4/D12) — prepare a demo video + use-case doc + privacy policy and submit early
  (P1 milestone 2) to know the outcome before shipping.
- **Distribution fallback** (if the Play Store rejects SMS): F-Droid + direct APK. Read SMS through the
  Notification Listener if `SEND_SMS` is lost.
- **Flavors (plan I8):** `foss` is the default build, with no Play Services and no Firebase (F-Droid, direct
  APK); `gms` adds FCM wake-ups for the Play Store. The Firebase options of `gms` come from the Gradle
  properties `handlive.fcm.applicationId`, `handlive.fcm.apiKey`, `handlive.fcm.projectId`,
  `handlive.fcm.senderId` or the environment variables `HANDLIVE_FCM_APPLICATION_ID`, `HANDLIVE_FCM_API_KEY`,
  `HANDLIVE_FCM_PROJECT_ID`, `HANDLIVE_FCM_SENDER_ID`; the repository holds no `google-services.json`. With
  empty options the app still builds and simply gets no pushes.
- **Gate G2 checklist (before the Phase 2 release):** in the Play Console, submit the Permissions Declaration
  Form for `READ_SMS` and `SEND_SMS` (`READ_CALL_LOG` joins in Phase 3). Attach a short video that shows the
  SMS permission primer (SET-01 part B), the system permission prompt, a new SMS appearing on the Mac and a
  reply sent from the Mac. Give the published `docs/privacy.md` as the privacy policy URL and fill the Data
  safety form from the same page. The project owner submits the forms and records the outcome here.
- Shizuku (optional) for the Opus/WS call-audio path — a wizard guides the installation; Shizuku must be
  restarted after every device boot (plan §13 D10).

## macOS app

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1); Developer ID signing for the
  app, the camera extension and the microphone driver; the app target sets
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.

- **Virtual mic (AudioServerPlugin):** cannot be installed through the Mac App Store (the sandbox blocks
  `/Library/Audio/Plug-Ins/HAL/`). Distribution:
  - PKG installer **signed + notarized** (`xcrun notarytool submit` + `stapler staple`), embedded in the
    app; the first run detects the missing plugin → opens the PKG with Installer (Installer asks for
    administrator rights itself) → `postinstall` runs `killall coreaudiod` as root. No privileged helper
    needed (`SMJobBless` deprecated since macOS 13; `launchctl kickstart` blocked since macOS 14.4).
  - In parallel: `brew install --cask handlive` (installs both app + plugin).
- **Virtual camera (CMIOExtension):** system extension inside the app bundle — App Store compatible. The
  user approves it in System Settings > Login Items & Extensions.
- macOS 13+.

## iOS/iPadOS app

- Regular App Store. APNs for push. iOS 16+.
- **Identifiers:** bundle id `app.handlive.ios`, with a Notification Service Extension target inside the
  app. The App Group `group.app.handlive` is shared by the app and the extension and is also the Keychain
  access group of the service `app.handlive.keys` (0.6.1), so the extension can read `PRK` while the device
  is unlocked (C3).
- **Capabilities (Apple Developer account and entitlements):** Push Notifications (`aps-environment`), App
  Groups, Keychain Sharing, and Communication Notifications
  (`com.apple.developer.usernotifications.communication`) for the `INSendMessageIntent` notifications of
  SMS-02; the app lists `INSendMessageIntent` in `NSUserActivityTypes`. The local network purpose string
  (`NSLocalNetworkUsageDescription`, `NSBonjourServices` = `_handlive._tcp`) comes from the string catalog
  (`infoplist.*` keys, 0.12).
- **APNs key:** create one `.p8` provider key in the Apple Developer account (Keys, Apple Push Notifications
  service). The key lives only on the relay server (`RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`,
  `RELAY_APNS_TEAM_ID`, `RELAY_APNS_TOPIC` = `app.handlive.ios`); development builds register sandbox tokens.
- **App Review:** answer App Privacy from `docs/privacy.md`, and explain in the review notes that the app
  works with the user's own Android phone running HandLive; attach a video of pairing and of an SMS.

## Cloud relay (Rust)

- Environment variables: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (raw UTF-8 bytes, ≥ 32 bytes,
  rotated on a schedule). Per-IP limits trust `X-Forwarded-For` only from the reverse proxy placed in
  front of the relay (Caddy or nginx).
- **Push (Phase 2):** APNs is enabled when `RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID`
  and `RELAY_APNS_TOPIC` are set; FCM when `RELAY_FCM_PROJECT_ID` and `RELAY_FCM_SERVICE_ACCOUNT_PATH` (a
  Google service-account JSON with access to the Firebase Cloud Messaging API) are set. Keep the key files
  outside the repository, readable only by the relay's user. The full list of variables is in
  relay/README.md.
- **Limits:** at most 10 new device registrations per hour per IP. Behind a reverse proxy, set
  `RELAY_TRUSTED_PROXIES` to the proxy's address so that `X-Forwarded-For` is believed; a load test from one
  machine needs `RELAY_TRUSTED_PROXIES=127.0.0.1` (`shared/tools/bench/relay_load.py`).
- **Several instances:** every instance uses the same PostgreSQL and Redis; Redis holds presence and forwards
  frames between instances (C5). `RELAY_INSTANCE_ID` names an instance in `presence:<device_id>`.

- **D5:** self-host 1 VPS (Hetzner/OVH, ~$20/month) for Phase 2. Docker + systemd. Stateless.
- Scale: monitor CPU/bandwidth, alert >70% → add a VPS. Migrate to a managed platform
  (fly.io/Railway) at >500 concurrent users.
- TLS: Let's Encrypt + cert pinning on the client side.
- Estimate: 100 concurrent Opus calls ≈ 12GB/hour; a commodity VPS with 20TB/month is enough for ~1000 users.

## CI

One GitHub Actions workflow per repository, in that repository's `.github/workflows/`: `ci-android` (`./gradlew
check`), `ci-apple` (`xcodebuild test` per package, SwiftLint, app build), `ci-relay` (fmt, clippy,
test; PostgreSQL 16 and Redis 7 services for integration tests), `ci-shared` (vector check, regenerated
vectors, schemas checked against the doc examples) and `ci-docs` in the hub (doc templates, schemas). Each
workflow rebuilds the workspace layout with `actions/checkout`: the hub at the root (checked out first when
docs are needed), the part into
`<phần>/`, `handlive-shared` into `shared/`; repository names are derived from
`${{ github.repository_owner }}/handlive-<phần>`, so all five repositories must live in the same
group/organization and keep their exact names (`handlive`, `handlive-android`, `handlive-apple`, `handlive-relay`,
`handlive-shared`). Private repositories: create the secret `HANDLIVE_REPOS_TOKEN` (a fine-grained PAT or a
GitHub App token with Contents: read on the five repositories) at the organization level; for public
repositories `github.token` is enough.
Changes to `shared/` or the docs do not trigger platform CI by themselves — run it by hand with `workflow_dispatch`. Each workflow takes the same-named branch of `handlive-shared` and of the hub when it exists (for example `feat/phase-01-clipboard` in every repository), otherwise `main`. Turn on
branch protection that requires the matching check on `main` of every repository.

## USB boost (optional)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`), auto-detected through IOKit
`IOServiceAddMatchingNotification`. A 3-step wizard turns on USB debugging the first time; after that
it switches automatically. Native UVC is left for v2.
