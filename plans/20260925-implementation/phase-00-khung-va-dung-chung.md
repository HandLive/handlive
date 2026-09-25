English | [Tiếng Việt](phase-00-khung-va-dung-chung.vi.md)

# Phase 0 — Repository scaffold, protocol, encryption, tokens, CI

**Goal:** all three platforms build from empty repositories, share one set of test vectors for
encryption and the envelope, have UI tokens generated from `shared/design-tokens/tokens.json`, and
CI runs the tests. This phase has no user-facing feature.

## Context

- `docs/detailed-design/00-common-specs.md`: 0.2 identifiers (`device_id` UUIDv8 from the SHA-256 of
  the signing key), 0.3 data types, 0.5 envelope and HL frame, 0.6 encryption (XChaCha20-Poly1305 =
  HChaCha20 + ChaCha20-Poly1305; X25519 + HKDF-SHA256; `HLSTREAM1|welcome|` MAC), 0.7 session
  handshake and capability, 0.8 error codes, 0.9 data model, 0.10 constants.
- `docs/code-standards.md`; `docs/design-system/1-foundations/01-mau-sac.md`, `03-kieu-chu.md`;
  `shared/design-tokens/README.md`.
- Architecture: `plans/20260924-definitive-architecture/plan.md` §3, §5, §6.

## Requirements

- Repository layout (I1; since 2026-09-25 each part is its own repository in the same workspace
  folder — see `plan.md` I1 and `reports/repo-split.md`; `tools/vectors` and `tools/schemas` now live
  in `shared/tools/`, and the CI workflows live in each repository) — create all of it, building
  green even while empty:

```
android/                      Gradle Kotlin DSL, latest stable AGP, Kotlin 2.x, minSdk 29, targetSdk 35
  app/                        app (Compose)
  core/protocol/              Envelope, Ack, HlFrame, error codes, JSON (kotlinx.serialization)
  core/crypto/                Tink: XChaCha20-Poly1305, X25519, HKDF; device_id; Keystore
  core/transport/             Ktor WSS server, mDNS, session handshake, capability, 0.11 state machine
  core/design/                HandLiveTheme generated from tokens.json, Apple-style Compose components
  feature/pairing, clipboard, sms, call, callaudio, camera   (added phase by phase)
apple/                        HandLive.xcworkspace; XcodeGen project.yml (do not commit xcuserdata)
  Packages/HLProtocol         envelope, HL frame, error codes (Codable)
  Packages/HLCrypto           hand-written HChaCha20 + ChaChaPoly, Curve25519, HKDF; device_id; Keychain
  Packages/HLTransport        URLSessionWebSocketTask, NWBrowser, handshake, capability, state machine
  Packages/HLDesignSystem     Color Sets for 4 appearances, Be Vietnam Pro font, text styles, SwiftUI components
  macOS/HandLive/             menu bar app (Phase 1)
  iOS/HandLive/, iOS/NotificationService/   (Phase 2)
relay/                        Cargo workspace: crates/relay-server (actix-web 4, actix-ws, sqlx, redis), migrations/
shared/
  test-vectors/               *.json (section Step 3)
  schemas/                    JSON Schema for the envelope, ack, each op (generated from 00-common-specs, checked by tests)
  design-tokens/tokens.json   already exists
tools/docs/                   already exists; tools/bench/ (Phase 1)
.github/workflows/            ci-android.yml, ci-apple.yml, ci-relay.yml
```

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| S0.1 [shared] | Write test vectors: XChaCha20-Poly1305 (vectors from draft-irtf-cfrg-xchacha), HChaCha20, ChaCha20-Poly1305 (RFC 8439), X25519 (RFC 7748), HKDF-SHA256 (RFC 5869), `device_id` from a sample signing key (0.2), a sample envelope encrypted with a fixed key, a sample HL frame, the `HLSTREAM1` MAC (0.6) | `shared/test-vectors/*.json` + `shared/test-vectors/README.md` describing each field | Each file has ≥ 2 vectors; RFC values copied verbatim, self-generated vectors have a script that regenerates them (`tools/vectors/`) |
| S0.2 [shared] | JSON Schema for the envelope, ack, errors and the `op`s of `session`, `capability` (0.5, 0.7) | `shared/schemas/*.schema.json` | The examples in 00-common-specs pass the schemas |
| A0.1 [android] | Multi-module Gradle scaffold, lint (ktlint, detekt), `core/protocol`, `core/crypto` passing S0.1, S0.2 | `android/` | `./gradlew check` green; vectors green |
| A0.2 [android] | `core/transport`: Ktor WSS server with a self-signed certificate (PKCS#12, password wrapped by the Keystore), session handshake 0.7, capability 0.7.2, state machine 0.11 (not wired to the UI yet) | `android/core/transport` | JVM test: both sides handshake over loopback; a wrong MAC is rejected with the right error code |
| A0.3 [android] | `core/design`: generate `HandLiveTheme` (4 color sets, Inter type in sp, spacing, corner radii) from `tokens.json` with a Gradle task; basic components `HLButton`, `HLSwitch`, `HLGroupedList`, `HLStatusIndicator` per `docs/design-system/components/` | `android/core/design` | Compose previews in Light, Dark, high contrast; no Material dynamic color |
| M0.1 [apple] | XcodeGen `project.yml`, workspace, three packages `HLProtocol`, `HLCrypto`, `HLTransport`; SwiftLint; tests passing S0.1, S0.2 | `apple/` | `xcodebuild test -scheme HLCrypto` green on macOS; HChaCha20 matches the vectors |
| M0.2 [apple] | `HLDesignSystem`: a script that generates Asset Catalog Color Sets (Any, Dark, High Contrast) and `Font` from `tokens.json`; text styles per `03-kieu-chu.md`; basic components (`HLButtonStyle`, `StatusIndicator`, `GroupedList`) | `apple/Packages/HLDesignSystem` | SwiftUI previews in 4 appearances; AccentColor = `accent` |
| R0.1 [relay] | Cargo workspace, `relay-server` starting with PostgreSQL + Redis (docker-compose for dev), migration for the 0.9.4 schema, self-certifying `device_id` authentication (C4), JWT HS256 (0.6.4) | `relay/` | `cargo test` green; `docker compose up` works; payloads are never read |
| T0.1 [test] | CI: Android (`./gradlew check` = test, lint, ktlint, detekt), Apple (`xcodebuild test` per package on a macOS runner, `swiftlint`, app build), relay (`cargo test`, `cargo clippy`, Postgres + Redis integration tests), shared (vectors, schemas, docs validator); caching | `.github/workflows/*.yml` | Four workflows green on the `feat/phase-00-khung` branch |

## Testing

- Cross-platform vectors: an envelope encrypted on Android decrypts on Apple and vice versa (test
  fixture written to `shared/test-vectors/envelope-roundtrip.json` by A0.1, checked by M0.1).
- `device_id` is identical when computed from the same signing key on both platforms.

## Risks and rollback

- Not every Tink version has an XChaCha20 API with a 24-byte nonce → use Tink's `XChaCha20Poly1305`
  (built in) or BouncyCastle; state the choice in the report.
- A wrong hand-written HChaCha20 → only the vectors expose it; do not drop any vector.
- XcodeGen skews the signing configuration → keep `project.yml` minimal; Developer ID signing is
  configured per `docs/deployment-guide.md`.
