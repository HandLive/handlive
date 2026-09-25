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

## Cloud relay (Rust)

- Environment variables: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (raw UTF-8 bytes, ≥ 32 bytes,
  rotated on a schedule). Per-IP limits trust `X-Forwarded-For` only from the reverse proxy placed in
  front of the relay (Caddy or nginx).

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
