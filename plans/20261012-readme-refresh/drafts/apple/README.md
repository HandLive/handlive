English | [Tiếng Việt](README.vi.md)

# handlive-apple

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The HandLive companion applications for macOS (menu bar app), iOS, and iPadOS, written in Swift 6 (macOS 13+, iOS 16+). They connect Apple devices to Android phones to provide two-way clipboard sync, an SMS bridge, and incoming call notifications with action controls.

## Overview

- **macOS menu bar app:** Lives in the system menu bar (`app.handlive.mac`). Handles two-way clipboard sync, full SMS conversations, and a non-activating incoming call panel with Answer, Decline, and End controls (call audio remains on the phone; Phase 4 call audio stopped).
- **iOS and iPadOS app:** Standalone app (`app.handlive.ios`) with a Notification Service Extension (`app.handlive.ios.nse`). Supports clipboard sync via Paste button, SMS messaging tab, and push-based incoming call notifications with Decline action.
- **End-to-end encrypted:** Built with hand-written HChaCha20 + CryptoKit `ChaChaPoly` (XChaCha20-Poly1305), strict Ed25519, X25519, HKDF, and Argon2id. Private keys are safeguarded in the system Keychain behind `SecretStore`.
- **Multilingual UI:** English by default, Vietnamese as second language, with String Catalogs generated from `handlive-shared`.
- **Database storage:** Encrypted local SQLite via SQLCipher 4.19 and GRDB.swift 7.11 for SMS conversations and call history.

## Workspace context

This repository is one component of the HandLive workspace:
- Hub repository [`handlive`](https://github.com/HandLive/handlive) (docs, plans) is the parent directory.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) supplies shared protocol schemas, test vectors, and UI strings.
- Clone the full workspace from the hub using `tools/workspace.sh clone <group-url>`. See [`CLAUDE.md`](CLAUDE.md) for local workspace workflows.

## Layout

| Path | Contents |
|------|----------|
| `project.yml` | XcodeGen definition: targets for `HandLive` (macOS menu bar app), `HandLiveiOS` (iOS/iPadOS), `HandLiveNotificationService` (NSE), localization settings, and local Swift packages |
| `HandLive.xcworkspace` | Workspace referencing the generated `HandLive.xcodeproj` and local packages |
| `macOS/HandLive/` | macOS app entry point (`HandLiveMacApp`), app delegate, generated `Assets.xcassets`, and `InfoPlist.xcstrings` |
| `macOS/Info.plist` | Service identifiers (`NSBonjourServices`), Intents, and generated permission descriptions |
| `macOS/HandLive.entitlements` | Data-protection keychain groups, communication notifications, and time-sensitive notifications |
| `iOS/HandLive/` | iOS app entry point (`HandLiveIOSApp`), root UI (`HLiOSUI`), and generated String Catalogs |
| `iOS/NotificationService/` | Notification Service Extension: decrypts APNs push envelopes using `K_push` and constructs communication notifications |
| `iOS/Info.plist`, `iOS/*.entitlements` | iOS entitlements, App Group and Keychain sharing (`group.app.handlive`), and push environments |
| `ThirdParty/GRDB` | GRDB.swift 7.11.1 vendored package configured to build against SQLCipher |
| `ThirdParty/SQLCipher` | SQLCipher 4.19.0 XCFramework package wrapper (downloaded via `fetch.sh`) |
| `Packages/HLProtocol` | Wire formats: Envelope, Payload, Ack, `ErrorCode` (0.8.1), HL frames, chunked clipboard structures, UUIDv7, Base64/Base64URL |
| `Packages/HLCrypto` | Cryptographic primitives: XChaCha20-Poly1305, X25519, strict Ed25519, HKDF, Argon2id, pairing attestations, and Keychain storage |
| `Packages/HLTransport` | Connection manager state machine (0.11), mDNS discovery (`NWBrowser`), WebSocket connector (TLS 1.3), relay client (`RelayAPIClient`), and control sessions (`/v1/ctl`) |
| `Packages/HLDesignSystem` | Design tokens, dynamic colors, typography, layout metrics, and reusable UI components |
| `Packages/HLAppCore` | Shared app state: settings, pair storage, pairing controller (QR and rendezvous), clipboard engine, and call event controller |
| `Packages/HLSMS` | SMS engine: SQLCipher database, synchronization cursors, history paging, outbox state machine, and notification decoding |
| `Packages/HLSMSUI` | Shared SwiftUI messaging views: conversations list, thread view, compose bar, and message bubbles |
| `Packages/HLCalls` | Call management: call log engine, missed call tracking, retention pruning, and notification payload decoding |
| `Packages/HLMacUI` | macOS UI: menu bar icon, status menus, Messages window, call panel (`NSPanel`), Settings panes, and pairing sheets |
| `Packages/HLiOSUI` | iOS UI: tab navigation, Messages view, Calls history, Clipboard paste flow, and Settings |
| `Packages/HLLocalization` | Type-safe `L10n` accessors and String Catalogs generated from `../shared/strings/ui-strings.json` |
| `Tools/HandLiveDevClient` | Developer CLI tool: headless Mac client for testing against Android emulators over `adb forward` |
| `Tools/CameraSpike` | Exploratory spike for Phase 5 (virtual camera extension and audio HAL plugin; not built in CI) |

## Requirements

- **macOS & Xcode:** Xcode 26 or later on macOS 26 or later to build the Mac app (avoids `actool` asset compilation crashes; built apps run on macOS 13+ and iOS 16+)
- **XcodeGen:** Pinned XcodeGen (`xcodegen`) to generate the Xcode project from `project.yml`
- **Swift:** Swift 6 toolchain with `swift-testing` support

## Setup and generated files

Fetch the vendor SQLCipher XCFramework once after cloning:

```sh
apple/ThirdParty/SQLCipher/fetch.sh
```

Generate design tokens and localized strings from `../shared` (tests run these with `--check`):

```sh
python3 apple/Packages/HLDesignSystem/Scripts/generate-design-tokens.py   # tokens.json → colors, text styles, metrics
python3 apple/Packages/HLLocalization/Scripts/generate-strings.py        # ui-strings.json → String Catalogs, L10n
```

## Generate Xcode project

```sh
cd apple && xcodegen generate     # creates HandLive.xcodeproj (not committed, listed in .gitignore)
open HandLive.xcworkspace
```

## Tests

Tests use swift-testing (`import Testing`) and validate against schemas and test vectors in `../shared`:

```sh
# With Xcode: uses the Testing module bundled with Xcode
cd apple/Packages/HLCrypto && swift test
# Every package with one build of the shared ones (CI runs HLTests-core and HLTests-features in parallel lanes)
cd apple && Tools/make-test-scheme.sh HLTests-all all
xcodebuild test -workspace HandLive.xcworkspace -scheme HLTests-all -destination 'platform=macOS' -parallel-testing-enabled NO

# Command Line Tools only: pulls the swift-testing package (release/6.2) and uses the .lproj fallback of the
# String Catalogs. SwiftUI packages (HLDesignSystem, HLSMSUI, HLCalls, HLMacUI, HLiOSUI) need the macOS 26 SDK when a
# newer SDK is installed.
cd apple/Packages/HLCrypto && HL_SWIFT_TESTING_PACKAGE=1 swift test
cd apple/Packages/HLMacUI && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test
```

## Lint

```sh
cd apple && swiftlint lint --strict
# Command Line Tools only: TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
```

## Documentation and community

- [System Architecture](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.md) — System design and security model
- [Detailed Design](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Protocols, formats, and specifications
- [Deployment Guide](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.md) — Packaging and distribution guidelines
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md) — PR workflow, small commits, and DCO sign-off (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md) — Vulnerability reporting policy
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.md) — Community standards

## License

Apache License 2.0 — see [LICENSE](LICENSE). Bundled fonts retain their respective upstream licenses, listed in [NOTICE](NOTICE).
