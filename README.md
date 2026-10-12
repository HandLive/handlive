English | [Tiếng Việt](README.vi.md)

# HandLive

<img src="docs/brand/assets/promo/readme-hero.en.png" alt="HandLive. Never miss a signal. Clipboard, SMS and calls from your Android phone, on your Mac, iPhone and iPad." width="800">

> **Never miss a signal.** Your Android phone's clipboard, SMS, and call notifications, on your Mac, iPhone, and iPad.

[![ci-docs](https://github.com/HandLive/handlive/actions/workflows/ci-docs.yml/badge.svg)](https://github.com/HandLive/handlive/actions/workflows/ci-docs.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/badge/release-v0.1.0--beta.3-orange.svg)](https://github.com/HandLive/handlive/releases/tag/v0.1.0-beta.3)

HandLive connects Android devices with macOS, iOS, and iPadOS. It syncs your clipboard, bridges SMS conversations, and delivers call notifications with action controls—without cloud lock-in. End-to-end encryption is always on, and the entire project is open source under Apache-2.0.

## Get the beta

Download the latest pre-release [`v0.1.0-beta.3`](https://github.com/HandLive/handlive/releases/tag/v0.1.0-beta.3) (2026-10-07):
- **macOS:** Ad-hoc signed DMG (choose *Open Anyway* on first run).
- **Android:** Signed `foss` APK.
- **iOS / iPadOS:** Unsigned IPA for sideloading.

Beta builds are intended for early testers and are not yet on the App Store or Google Play. See the [Deployment Guide](docs/deployment-guide.md) for installation and packaging details.

## Features

| Feature | macOS | iOS / iPadOS |
|---------|:-----:|:------------:|
| Two-way clipboard (HTML formatted text and images) | Yes | Yes |
| Send and receive SMS | Yes | Yes |
| Call details and actions (answer, decline, end) | Yes | Details and decline only |
| Call audio on the computer | Not planned (Phase 4 stopped, 2026-10-12) | No (Apple has no HF-side HFP API) |
| Virtual camera and mic | Planned (Phase 5) | No |
| Continue Browsing (open page follows you) | Planned (Phase 6) | Planned (from the phone only) |

End-to-end encryption is always on and cannot be disabled.

## Screenshots

| | | |
|---|---|---|
| <img src="docs/screenshots/android/04-devices-connected.en.png" alt="Android: paired Mac over Wi-Fi" width="220"> | <img src="docs/screenshots/ios/04-sms-conversation.en.png" alt="iPhone: SMS from the phone" width="220"> | <img src="docs/screenshots/macos/04-incoming-call-panel.en.png" alt="Mac: incoming-call panel" width="320"> |
| Android: paired Mac over Wi-Fi | iPhone: SMS from the phone | Mac: incoming-call panel |

Full screenshot gallery (English and Vietnamese): [`docs/screenshots/README.md`](docs/screenshots/README.md).

## How it works

- **Local WebSocket & mDNS:** Fast peer-to-peer transport over Wi-Fi, powered by an embedded Ktor server on Android.
- **End-to-end encryption:** XChaCha20-Poly1305 payloads, X25519 + HKDF session keys, and QR pairing.
- **Zero-knowledge relay:** A stateless Rust relay forwards encrypted envelopes across networks without inspecting content.

For full technical details, see [`docs/system-architecture.md`](docs/system-architecture.md).

## Status

| Phase / gate | Goal | Status |
|--------------|------|--------|
| **0** Foundation | Protocol, shared test vectors, green CI | **Done** |
| **1** Clipboard sync (MVP) | Android ↔ Mac, LAN WebSocket, QR pairing | **Code done** (android #13) · Gate G1 open |
| **2** SMS bridge & iOS | Conversations, Rust relay, APNs/FCM | **Code done** · Gate G2 open |
| **3** Call info and control | Telecom APIs, Mac panel, call history | **Code done** · Real-device checks open |
| **4** Call audio | Bluetooth HFP/SCO and Opus fallback | **Stopped** (owner decision 2026-10-12) · G4 closed |
| **5** Virtual camera / mic | CMIOExtension and AudioServerPlugin | **Spike on `main`** (`CameraSpike`) · Gate G5 pending |
| **6** Continue Browsing | Foreground URL handover across devices | **Spike on `main`** · Browser decisions pending |
| **7** Connect anywhere | Auto link without a shared Wi-Fi network | **Proposed** (2026-10-01) · Spike G7 pending |
| **G0** Vectors | Shared cross-platform crypto test vectors | **Done** |
| **G1** Real devices | Real-device Phase 1 matrix validation | **Open** (before 1.0) |
| **G2** Play Console | SMS and call log permissions declaration | **Open** (before 1.0; Plan B: F-Droid/APK) |

Full roadmap and history: [`docs/project-roadmap.md`](docs/project-roadmap.md).

### Rule: keep this roadmap current

Whenever a concrete task completes (phase card merged, gate closed, spike resolved, or real-device fix on `main`), the same change set must update this table, the snapshot in [`docs/project-roadmap.md`](docs/project-roadmap.md), and hub [`CHANGELOG.md`](CHANGELOG.md) for user-visible changes.

## Repositories

| Repository | Description |
|------------|-------------|
| [handlive](https://github.com/HandLive/handlive) | Documentation hub, plans, and workspace tools |
| [handlive-android](https://github.com/HandLive/handlive-android) | Android service and client application (Kotlin) |
| [handlive-apple](https://github.com/HandLive/handlive-apple) | macOS menu bar app, iOS, and iPadOS apps (Swift) |
| [handlive-relay](https://github.com/HandLive/handlive-relay) | Zero-knowledge encrypted relay server (Rust) |
| [handlive-shared](https://github.com/HandLive/handlive-shared) | Shared protocol schemas, crypto test vectors, and UI strings |

```
HandLive/                 # hub: handlive
├── docs/  plans/  tools/
├── android/              # handlive-android
├── apple/                # handlive-apple
├── relay/                # handlive-relay
├── shared/               # handlive-shared
└── .github-org/          # HandLive/.github (CONTRIBUTING, SECURITY, …)
```

## Documentation

- [`docs/project-overview-pdr.md`](docs/project-overview-pdr.md) — Goals, scope, and product constraints
- [`docs/system-architecture.md`](docs/system-architecture.md) — Transports, protocol, and security model
- [`docs/project-roadmap.md`](docs/project-roadmap.md) — Phases, progress snapshot, and effort
- [`docs/deployment-guide.md`](docs/deployment-guide.md) — Packaging, signing, and distribution
- [`docs/design-guidelines.md`](docs/design-guidelines.md) — UX, ergonomics, and security principles
- [`docs/code-standards.md`](docs/code-standards.md) — Cross-platform conventions and standards
- [`docs/privacy.md`](docs/privacy.md) — Privacy principles, data storage, and relay retention
- [`docs/codebase-summary.md`](docs/codebase-summary.md) — Code map and architecture overview
- [`docs/detailed-design/README.md`](docs/detailed-design/README.md) — Specifications, protocols, and error codes
- [`docs/screenshots/README.md`](docs/screenshots/README.md) — App screenshots and galleries

## Contributing and community

- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md) — Developer Certificate of Origin (`git commit -s`), PR workflow, and standards
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.md) — Community standards and expectations
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md) — Vulnerability reporting and disclosure policy

## License

Apache License 2.0 — [LICENSE](LICENSE). Applies to all repositories under [HandLive](https://github.com/HandLive).

Website and blog content in `website/` are licensed under GPL-2.0-or-later.
