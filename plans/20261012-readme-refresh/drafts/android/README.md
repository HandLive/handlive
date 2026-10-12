English | [Tiếng Việt](README.vi.md)

# handlive-android

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The HandLive companion service and application for Android phones, written in Kotlin with Jetpack Compose (minSdk 29, compileSdk 37). It connects Android with macOS, iOS, and iPadOS devices to provide two-way clipboard sync, an SMS bridge, and call notifications with action controls.

## Overview

- **Cross-platform continuity:** Seamlessly syncs clipboard, bridges SMS messages, and displays call notifications across your devices.
- **End-to-end encrypted:** All data transferred over local Wi-Fi or through the relay is protected with XChaCha20-Poly1305 and X25519 session keys.
- **Two build flavors:**
  - `foss` (default): Fully open-source build without Google Play Services or Firebase dependencies; connects directly over LAN or via WebSocket relay.
  - `gms`: Adds Firebase Cloud Messaging (FCM) high-priority data wake-ups.
- **Multilingual UI:** English by default, Vietnamese as second language, with localized strings generated from `handlive-shared`.
- **Call integration without `InCallService`:** Uses `TelecomManager` for actions (Answer, Decline, End) and system telephony listeners without invasive call-handling services. Call audio on the computer is not supported (Phase 4 stopped).

## Workspace context

This repository is one component of the HandLive workspace:
- Hub repository [`handlive`](https://github.com/HandLive/handlive) (docs, plans) is the parent directory.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) supplies shared protocol schemas, test vectors, and UI strings.
- Clone the full workspace from the hub using `tools/workspace.sh clone <group-url>`. See [`CLAUDE.md`](CLAUDE.md) for local workspace workflows.

## Layout

| Path | Contents |
|------|----------|
| `app/` | Compose app (`app.handlive.android`): first-run setup (SET-01), Devices and Settings tabs, pairing flows, per-device details, Accessibility disclosures, SMS and Calls permission primers, background execution settings, and device deregistration. Flavors: `foss` (default) and `gms` |
| `buildSrc/` | Code generation tasks: `:core:design:generateHandLiveTheme` from `../shared/design-tokens/tokens.json`; `:core:strings:generateStringResources` from `../shared/strings/ui-strings.json` |
| `core/protocol` | Wire formats: Envelope, Payload, Ack, `ErrorCode` (0.8.1), HL frames, clipboard chunks, SMS and `call_event` messages, relay wrappers, control ops, `HR` frames, REST bodies, UUIDv7, Base64/Base64URL; validates against schemas in `../shared` |
| `core/crypto` | Cryptographic engine: Tink XChaCha20-Poly1305, X25519, Ed25519, HKDF, `device_id`, PRK, session/rekey/stream key schedules, `K_push`, and `hl_master` KeyStore storage |
| `core/transport` | Embedded Ktor/Netty WSS server (TLS 1.3, self-signed P-256 certificate), handshake, capability exchange, session management (4409 replacement, 4410/4411/4429 idle/limits); OkHttp relay client with certificate pinning |
| `core/data` | Room database `handlive.db` v3 (`paired_device`, `sms_observer_state`, `push_outbox`), DataStore settings keys (0.9.5), and `HandLiveData` container |
| `core/strings` | Build-time string resources generated from the catalog; unit tests enforce catalog coverage and prevent hardcoded UI text |
| `core/design` | `HandLiveTheme` (4 appearance variants, Inter / Be Vietnam Pro / Roboto Mono typography), `HLButton`, `HLSwitch`, `HLGroupedList`, `HLStatusIndicator`, `HLIcon` |
| `feature/connection` | `HandLiveService` (foreground service), TLS server on ports 47800–47809, mDNS discovery with hourly hints, capability synchronization, envelope routing, and `HLBENCH/1` logging in debug builds |
| `feature/pairing` | Pairing via QR code (CameraX + ZXing) or PIN (Argon2id), paired device list, Security Code verification, and unpairing |
| `feature/clipboard` | Two-way clipboard synchronization: Accessibility copy detection, `ClipboardReadActivity`, Quick Settings tile, Share target, chunked image transfer, and safe auto-clear |
| `feature/sms` | SMS bridge: `ContentObserver` on SMS provider (no `RECEIVE_SMS`), `sms/new`, paged sync (`sms/sync`, `sms/history`), multi-part sending via `SmsManager`, forward-only status updates, and read state sync |
| `feature/call` | Call monitoring and controls: telephony listeners and `PHONE_STATE` receiver feeding call state contexts; `answer`, `reject`, `end` via `TelecomManager`; call log sync via `ContentObserver`; alert pushes for incoming and missed calls; app call support (`appcall/`) |
| `feature/relay` | Relay client: on-demand `/v1/relay` connection, device registration, pairing rendezvous, and alert push triggers (`K_push`) with `push_outbox` retry queue |
| `config/` | Linter configs: ktlint, detekt |

## Requirements

- **JDK:** Version 21 (e.g. OpenJDK 21)
- **Android SDK:** Compile SDK 37 (`platforms;android-37.0`), Min SDK 29, Target SDK 35
- **Build tools:** Android Gradle Plugin (AGP) 9.4 with Kotlin 2.4

## Build settings

Configuration uses Gradle properties (`~/.gradle/gradle.properties` or `-P`) or environment variables. All settings are optional; the project builds clean with defaults:

| Gradle property | Environment variable | Description |
|-----------------|----------------------|-------------|
| `handlive.relayHost` | `HANDLIVE_RELAY_HOST` | Relay server hostname (CONN-03); empty builds without relay support |
| `handlive.relayExtraPins` | `HANDLIVE_RELAY_EXTRA_PINS` | Additional `sha256/<base64>` certificate pins, comma-separated, complementing ISRG Root X1/X2 |
| `handlive.fcm.applicationId`, `.apiKey`, `.projectId`, `.senderId` | `HANDLIVE_FCM_APPLICATION_ID`, `_API_KEY`, `_PROJECT_ID`, `_SENDER_ID` | `gms` flavor only: Firebase credentials for FCM wake-up pushes; empty disables push |

## Commands

```sh
./gradlew check            # JVM tests (foss) + Android Lint + ktlint + detekt (JDK 21, platforms;android-37.0)
./gradlew assembleFossDebug assembleGmsDebug   # the default flavor and the one with FCM
./gradlew :core:transport:connectedDebugAndroidTest   # instrumented smoke test, needs a device
HL_WRITE_ROUNDTRIP=1 ./gradlew :core:crypto:test   # rewrites ../shared/test-vectors/envelope-roundtrip.json
adb logcat -s HLBENCH      # debug builds: benchmark lines for ../shared/tools/bench
```

## Documentation and community

- [System Architecture](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.md) — System design and security model
- [Detailed Design](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Protocols, formats, and specifications
- [Deployment Guide](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.md) — Packaging and distribution guidelines
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md) — PR workflow, small commits, and DCO sign-off (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md) — Vulnerability reporting policy
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.md) — Community standards

## License

Apache License 2.0 — see [LICENSE](LICENSE). Bundled fonts and icons retain their respective upstream licenses, listed in [NOTICE](NOTICE).
