English | [Tiếng Việt](deployment-guide.vi.md)

# HandLive — Deployment & Distribution

> Distribution plan following decisions D5/D7/D8 in the original plan. Release files come from tag-driven workflows:
> see Release builds.

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
  reply sent from the Mac; for Phase 3 the video also shows an incoming call on the Mac panel, answering and
  declining it from the Mac, and a missed call. `READ_PHONE_STATE`, `READ_CONTACTS` and `ANSWER_PHONE_CALLS`
  are runtime permissions and need no form. Give the published `docs/privacy.md` as the privacy policy URL
  and fill the Data safety form from the same page. The project owner submits the forms and records the
  outcome here.
- Shizuku (optional) for the Opus/WS call-audio path — a wizard guides the installation; Shizuku must be
  restarted after every device boot (plan §13 D10).
- **Call control per device (Phase 3):** `TelecomManager.acceptRingingCall()` and `endCall()` are
  deprecated since API 29 and still work (C12), but an OEM build may block them; if so, answering and
  ending wait for HFP (Phase 4). The Phase 3 risks ask to record each device model here.

| Device model | Android version | `acceptRingingCall()` | `endCall()` |
|---|---|---|---|
| Pixel | — | Not tested yet | Not tested yet |
| Samsung | — | Not tested yet | Not tested yet |

## macOS app

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1); Developer ID signing for the
  app, the camera extension and the microphone driver; the app target sets
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
- **Calls (Phase 3):** `macOS/HandLive.entitlements` also has the Communication Notifications capability
  (`com.apple.developer.usernotifications.communication`: the call communication notifications, and
  reading the Focus status with `INFocusStatusCenter`) and the Time Sensitive Notifications entitlement
  (`com.apple.developer.usernotifications.time-sensitive`: without it a time-sensitive call notification
  arrives as active and does not break through a Focus). `macOS/Info.plist` lists `INSendMessageIntent`
  and `INStartCallIntent` in `NSUserActivityTypes` and carries `NSFocusStatusUsageDescription`, whose text
  comes from the catalog key `infoplist.focus_status_usage` (next to `NSBonjourServices` = `_handlive._tcp`,
  `NSLocalNetworkUsageDescription` and `NSMicrophoneUsageDescription`). Turn both capabilities on for the
  App ID `app.handlive.mac` before signing.

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
- **Capabilities of the app (Apple Developer account and `iOS/HandLive.entitlements`):** Push Notifications
  (`aps-environment`, `development` in the file; distribution signing uses production), App Groups
  (`group.app.handlive`), Keychain Sharing (`$(AppIdentifierPrefix)app.handlive.ios`, `group.app.handlive`),
  Communication Notifications (`com.apple.developer.usernotifications.communication`) for the communication
  notifications of SMS-02 (`INSendMessageIntent`) and CALL-01 (`INStartCallIntent`), and Time Sensitive
  Notifications (`com.apple.developer.usernotifications.time-sensitive`) for incoming calls. `iOS/Info.plist`
  lists `INSendMessageIntent` and `INStartCallIntent` in `NSUserActivityTypes`. The local network purpose
  string (`NSLocalNetworkUsageDescription`, `NSBonjourServices` = `_handlive._tcp`) comes from the string
  catalog (`infoplist.*` keys, 0.12).
- **Notification Service Extension (`app.handlive.ios.nse`, `iOS/NotificationService.entitlements`,
  `iOS/NotificationService-Info.plist`):** App Groups and Keychain Sharing (`group.app.handlive`), the
  Communication Notifications entitlement, and `IntentsSupported` = `INSendMessageIntent`,
  `INStartCallIntent` in `NSExtension` › `NSExtensionAttributes` (extension point
  `com.apple.usernotifications.service`). Phase 3 added the Communication Notifications entitlement and
  `IntentsSupported` to the extension; the SMS communication notifications need them too, so a Phase 2 build
  may not have shown SMS as communication notifications on a device. The App IDs `app.handlive.ios` and
  `app.handlive.ios.nse` both need the Communication Notifications capability; the app also needs Time
  Sensitive Notifications.
- **APNs key:** create one `.p8` provider key in the Apple Developer account (Keys, Apple Push Notifications
  service). The key lives only on the relay server (`RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`,
  `RELAY_APNS_TEAM_ID`, `RELAY_APNS_TOPIC` = `app.handlive.ios`); development builds register sandbox tokens.
- **App Review:** answer App Privacy from `docs/privacy.md`, and explain in the review notes that the app
  works with the user's own Android phone running HandLive; attach a video of pairing and of an SMS.
- **Device name:** on iOS 16 and later the phone sees "iPhone" or "iPad" as the device name unless Apple grants
  the user-assigned device name entitlement (`com.apple.developer.device-information.user-assigned-device-name`);
  request it before the release (PAIR-01 field 3).
- **App icon:** the AppIcon set (macOS and iOS) and the Android adaptive icon are in the app repositories,
  generated from `docs/brand-guidelines.md` by `tools/brand/build_brand_assets.py`; store listings use the 1024 px
  and 512 px files in `docs/brand/assets/app-icon/`.

## Cloud relay (Rust)

- Environment variables: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (raw UTF-8 bytes, ≥ 32 bytes,
  rotated on a schedule). Per-IP limits trust `X-Forwarded-For` only from the reverse proxy placed in
  front of the relay (Caddy or nginx).
- **Push (Phase 2):** APNs is enabled when `RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID`
  and `RELAY_APNS_TOPIC` are set; FCM when `RELAY_FCM_PROJECT_ID` and `RELAY_FCM_SERVICE_ACCOUNT_PATH` (a
  Google service-account JSON with access to the Firebase Cloud Messaging API) are set. Keep the key files
  outside the repository, readable only by the relay's user. The full list of variables is in
  relay/README.md.
- **Limits:** at most 10 new device registrations per hour per IP (IPv6 counted per /64) and at most
  `RELAY_MAX_REGISTRATIONS_PER_HOUR` (default 1,000) on the whole relay; `/v1/auth/*` allows 30 requests per
  minute per IP. When the relay binds a loopback address and `RELAY_TRUSTED_PROXIES` is empty, it trusts
  `X-Forwarded-For` from `127.0.0.1` and `::1` (the local reverse proxy). A reverse proxy on another host needs
  `RELAY_TRUSTED_PROXIES` set to its address; the relay logs a warning at startup when the variable is empty and
  it binds a non-loopback address, and when an untrusted peer sends `X-Forwarded-For`.
- **Several instances:** every instance uses the same PostgreSQL and Redis; Redis holds presence and forwards
  frames between instances (C5). `RELAY_INSTANCE_ID` names an instance in `presence:<device_id>`.

- **D5:** self-host 1 VPS (Hetzner/OVH, ~$20/month) for Phase 2. Docker + systemd. Stateless.
- Scale: monitor CPU/bandwidth, alert >70% → add a VPS. Migrate to a managed platform
  (fly.io/Railway) at >500 concurrent users.
- TLS: Let's Encrypt + cert pinning on the client side.
- Estimate: 100 concurrent Opus calls ≈ 12GB/hour; a commodity VPS with 20TB/month is enough for ~1000 users.

## Release builds

A version tag builds the installable files and attaches them, each with a `.sha256`, to that tag's GitHub Release
(created when missing; a tag with a suffix such as `-beta.1` makes a pre-release). The relay ships from source (D5).

| Repository | Workflow | Files |
|---|---|---|
| handlive-android | `release-android` | `HandLive-<version>-android-foss.apk`: the `foss` flavor, signed with the release key |
| handlive-apple | `release-apple` | `HandLive-<version>-ios-unsigned.ipa`; `HandLive-<version>-macos-unsigned.dmg` (ad hoc), or `HandLive-<version>-macos.dmg` (Developer ID, notarized) once the macOS secrets exist |

**Cutting a release:** set the version in every repository (Android `versionName` and a higher `versionCode` in
`app/build.gradle.kts`; Apple `MARKETING_VERSION`, the version core without the suffix, and `CURRENT_PROJECT_VERSION`
in `project.yml`), commit, then tag `vX.Y.Z` or `vX.Y.Z-suffix` in each repository and push the hub and handlive-shared
tags first: the workflows check those two out at the same tag, and one without it falls back to `main` with a warning.
A workflow stops when the tag does not match its repository's version and warns when the build number (`versionCode`,
`CURRENT_PROJECT_VERSION`) is not above the previous tag's. To rebuild the files of an existing tag, run the workflow by
hand: GitHub › Actions › `release-android` or `release-apple` › Run workflow, or
`gh workflow run release-android.yml --repo HandLive/handlive-android -f tag=v0.1.0-beta.1 -f publish=false`
(`publish=false` keeps the files as workflow artifacts and leaves the Release alone; a file already attached is
replaced only with `replace=true`).

**Who holds the keys:** each workflow builds in a job with read-only rights and no secret, then signs and publishes in
a separate job of the environment `release` that runs only the platform's signing tools and `gh`: third-party build
code never runs next to a signing key or a token that can write Releases. Keep the signing secrets in that environment
(Settings › Environments › `release` › Environment secrets), add yourself as a required reviewer and limit it to tags
`v*`, and protect the tags with a ruleset (Settings › Rules › Rulesets › Tag, `v*`, restrict creation, update and
deletion).

**Android signing (owner, once):** the APK is signed after the build with `apksigner`; without the secrets the sign job
stops (the unsigned build stays a workflow artifact) rather than publish an APK nobody can install or update. Create
the key and keep the keystore and its password in a safe offline place: an installed app accepts updates only from the
same key.

```sh
keytool -genkeypair -v -keystore handlive-release.jks -alias handlive -keyalg RSA -keysize 4096 -validity 10000
base64 -i handlive-release.jks | gh secret set ANDROID_RELEASE_KEYSTORE_BASE64 --repo HandLive/handlive-android
gh secret set ANDROID_RELEASE_KEYSTORE_PASSWORD --repo HandLive/handlive-android
gh secret set ANDROID_RELEASE_KEY_ALIAS --repo HandLive/handlive-android --body handlive
```

`gh secret set` without `--body` asks for the value, so the password stays out of the shell history; add
`--env release` to keep the secrets in the environment. `keytool` writes a PKCS12 keystore, whose key password is the
store password; `ANDROID_RELEASE_KEY_PASSWORD` is needed only for an older JKS keystore with a separate key password. The repository
variables `HANDLIVE_RELAY_HOST` and `HANDLIVE_RELAY_EXTRA_PINS` (Settings › Secrets and variables › Variables)
configure the relay of release builds; without them a release has no relay.

**iOS/iPadOS:** the IPA is a Release build for devices with its Notification Service Extension and is not signed:
sideloading tools re-sign it with the installer's own Apple ID. TestFlight and the App Store need the paid Apple
Developer Program team (signing, the App Group and Keychain Sharing identifiers, `aps-environment` = production).

**macOS:** without Developer ID the workflow publishes `HandLive-<version>-macos-unsigned.dmg`, the universal app
signed ad hoc, like many open-source Mac apps. Gatekeeper blocks its first launch until the user allows it once in
System Settings › Privacy & Security › Open Anyway (or runs `xattr -dr com.apple.quarantine /Applications/HandLive.app`).
Such a build carries no restricted entitlements: it keeps its keys in the login keychain (0.6.1; macOS asks once per
new build whether the app may read them), cannot read the Focus status, and its call notifications are not
time-sensitive. A tag older than this login-keychain fallback (`v0.1.0-beta.1`) publishes no Mac app without
Developer ID, since its app needs the data-protection keychain. With all seven secrets below the workflow publishes
`HandLive-<version>-macos.dmg` instead (with some but not all it fails): it signs the universal Release build inside
out (embedded `SQLCipher.framework`, then the app with `macOS/HandLive.entitlements`, the hardened runtime and a
secure timestamp), puts it in a DMG signed with the same identity, notarizes the DMG with `notarytool`, staples it and
checks that the app still runs after ten seconds. Before signing it checks that the profile is a Developer ID profile of
`app.handlive.mac` made for the certificate and granting the three capabilities. The virtual camera and microphone of
Phase 5 will need this signed build. Secrets of handlive-apple:

| Secret | Content |
|---|---|
| `APPLE_TEAM_ID` | the team ID (10 characters) |
| `APPLE_DEVELOPER_ID_P12_BASE64`, `APPLE_DEVELOPER_ID_P12_PASSWORD` | the "Developer ID Application" certificate with its private key, exported from Keychain Access as `.p12`, base64 |
| `APPLE_MAC_PROFILE_BASE64` | a Developer ID provisioning profile of the App ID `app.handlive.mac` with Keychain Sharing, Communication Notifications and Time Sensitive Notifications, base64 |
| `APPLE_NOTARY_KEY_P8_BASE64`, `APPLE_NOTARY_KEY_ID`, `APPLE_NOTARY_ISSUER_ID` | an App Store Connect API key (Developer role) for notarization: the `.p8` file base64, its key ID and the issuer ID |

When the Mac app gains resources the hardened runtime guards (microphone for call audio, Apple Events for Continue
Browsing), add their entitlements (`com.apple.security.device.audio-input`,
`com.apple.security.automation.apple-events`) to `macOS/HandLive.entitlements`; an app extension or system
extension needs its own signing step, which the workflow asks for when it finds one.

## CI

One GitHub Actions CI workflow per repository (plus the release workflows of Release builds), in that repository's
`.github/workflows/`: `ci-android` (`./gradlew
check`), `ci-apple` (four parallel macOS lanes: core package tests, feature package tests + Mac app build, iOS app build,
and a tools lane with SwiftLint, a check that package imports stay within declared dependencies, an Intel (x86_64)
Mac build and the dev tools; each test lane builds its packages once through a shared scheme of
`HandLive.xcworkspace`), `ci-relay` (fmt, clippy,
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

handlive-apple downloads SQLCipher's XCFramework with `ThirdParty/SQLCipher/fetch.sh`, which checks its SHA-256;
the framework is not committed. Run the script once after cloning; CI runs it and allows 90 minutes for the job.

## USB boost (optional)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`), auto-detected through IOKit
`IOServiceAddMatchingNotification`. A 3-step wizard turns on USB debugging the first time; after that
it switches automatically. Native UVC is left for v2.
