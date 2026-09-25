# Phase 1 — A1.0 [android]: Phase 0 leftovers

Card A1.0 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-android, branch `feat/phase-01-clipboard` (from an up-to-date `main`), pushed; CI `ci-android` green on every push after the CI fix below.

## What was done

- **Toolchain.** Installed `platforms;android-37.0` (the SDK names API 37 `android-37.0`) with the Homebrew `sdkmanager`; every module compiles against 37, `targetSdk` stays 35. Compose BOM 2026.09.00 (Compose 1.12), the latest stable. CI installs `platforms;android-37.0`. The deprecated `createComposeRule` moved to the v2 rule. `androidx.core` 1.19.1 (needs compileSdk 37) is now usable.
- **Close codes 4410 / 4411 / 4429** (0.8.3, CONN-01 API 3–4, CONN-02):
  - `/v1/ctl` now runs as a raw Ktor WebSocket (`webSocketRaw`) read by `InboundFrames`, so every frame — client pings included, which a default Ktor session answers internally and never shows — refreshes the session's activity clock. A session silent for 45 s is closed **4411 `IDLE_TIMEOUT`**; if the peer never answers the close, the TCP connection is dropped 2 s later. Pings are answered with the same payload; fragmented text is reassembled up to 256 KiB (1009 above that).
  - `ConnectionAdmission`: at most **16** connections waiting for their handshake; the 17th is closed **4429**. An IP whose `session/hello` is rejected with `AUTH_FAILED` 5 times within 60 s is blocked for 5 minutes: its connections are closed **4429** right after the WebSocket upgrade, before any hello is read. Memory is bounded (256 tracked addresses, blocked ones kept).
  - A failed rekey (no `ack` in 10 s, error `ack`, bad data) now closes **4410 `REKEY_FAILED`** instead of 4500.
  - `WsCloseCode` equals `shared/schemas/common.schema.json#/$defs/ws-close-code` (new test).
  - `session/error.message` is now an English diagnostic (0.8, 0.12.4); it was Vietnamese.
- **Room `paired_device`** (0.9.1) in the new module `core/data`: `HandLiveDatabase` (`handlive.db`, schema exported to `core/data/schemas`), `PairedDeviceEntity`/`PairedDeviceDao` with the queries of PAIR-01…03 and CONN-01 (active count, lookup for the handshake, list ordered by last seen, replace-for-peer in one transaction, record seen, tombstone, delete). `PairStore` seals the `PRK` into `prk_enc` with an AEAD bound to `prk/<pair_id>` (a sealed PRK copied to another row cannot be opened) and computes the Security Code (8 hex of SHA-256(`attestation`)). The DataStore settings of 0.9.5 (`SettingsStore`, `HandLiveSettings` with the spec defaults) and a process-wide `HandLiveData` container live there too.
- **Identity keys.** `DeviceIdentityStore` (core/crypto) loads or creates `ik_sig`/`ik_dh` in the `hl_master`-wrapped secret store and derives `device_id`; `AeadSecretSealer` seals per-record secrets; `AndroidKeystoreSecretStore.destroy()` supports the full data wipe (SET-02 API 7).
- **Material Symbols Rounded and Inter 700.** 74 Material Symbols Rounded vector drawables (37 symbols, outline and filled; weight 400, grade 0, opsz 24; Apache 2.0) from `google/material-design-icons` `symbols/android`, with the theme tint attribute removed; new `HLSymbol`/`HLIcon`. `HLStatusIndicator` now shows `wifi`, `public`, `usb`, `wifi_off` next to its text. Inter 4.1 Bold (byte-identical to the rsms/inter release, like the three faces already bundled) answers the system Bold Text setting (Compose adds `fontWeightAdjustment` to every weight). Both are listed in `NOTICE`; the Apache text is in `core/design/src/main/assets/licenses/MaterialSymbols-Apache-2.0.txt`.
- **Instrumented smoke test** `core/transport/src/androidTest/.../NettyTlsSmokeTest.kt`: on a device, the server with the on-device certificate negotiates TLS 1.3 through Conscrypt, upgrades `/v1/ctl`, closes a malformed hello with 4400, answers 404 elsewhere, refuses TLS 1.2, and the Keystore-backed TLS identity reloads unchanged. It compiles and packages (`assembleDebugAndroidTest`); it was not run (no device).
- **Shared vectors of S1.1** wired into core/crypto: `ed25519.json` (RFC 8032 TEST 1–3 re-signed bit for bit, 6 negatives rejected by Tink's strict verifier) and `relay-auth.json` (HLREG1/HLAUTH1 messages rebuilt by the new `RelaySignatureMessages`, signatures reproduced, 10 negatives fail). `VectorFileCoverageTest` covers the two files.
- **CI fix.** `ci-android.yml` ran its first step in `android/` before any checkout, so every run on `main` failed at "Resolve matching branches" since 346c788; the step now runs in `${{ github.workspace }}` (the controller cherry-picked it to `main`).

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| 4d3ed07 | build(android): compile against API 37 with Compose BOM 2026.09.00 |
| d107597 | feat(android): limit pending handshakes, block abusive IPs and close idle sessions |
| 8164a10 | test(android): cover close codes 4410, 4411 and 4429 on the TLS server |
| 9539568 | test(android): use the v2 Compose test rule |
| 4ebf76b | feat(android): load or create identity keys and seal per-record secrets |
| adcb5a5 | test(android): cover identity reload and context-bound sealing |
| 89f280b | feat(android): keep paired_device in Room and settings in DataStore |
| d233f65 | test(android): cover the pair store and the settings defaults |
| 45b84a0 | feat(android): bundle Material Symbols Rounded and Inter Bold |
| e742144 | test(android): add an instrumented Netty and TLS 1.3 smoke test |
| d910fb8 | docs: describe core:data, the icon set and the API 37 toolchain |
| c13b4f5 | feat(android): build the HLREG1 and HLAUTH1 relay signature messages |
| 8671c57 | test(android): verify the Ed25519 and relay authentication vectors |
| 86d025d | test(android): check the close codes against the shared schema |
| 5676e9c | ci: resolve the matching branches before android/ exists |

## Files

Created: `core/data/**` (module, entity, DAO, database, `PairStore`, `SettingsStore`, `HandLiveSettings`, `HandLiveData`, tests, `schemas/…/1.json`); `core/crypto/.../identity/DeviceIdentity.kt`, `keystore/SecretSealer.kt`, `derivation/RelaySignatureMessages.kt` and tests `DeviceIdentityStoreTest`, `SignatureVectorTest`; `core/transport/.../server/ConnectionAdmission.kt`, `InboundFrames.kt`, tests `ConnectionAdmissionTest`, `ControlChannelLimitsTest`, `CloseCodeCatalogTest`, `src/androidTest/.../NettyTlsSmokeTest.kt`; `core/design/.../component/HLSymbol.kt`, `HLIcon.kt`, `res/drawable/ic_symbol_*.xml` (74), `res/font/inter_bold.ttf`, `assets/licenses/MaterialSymbols-Apache-2.0.txt`.
Changed: all module `build.gradle.kts` (compileSdk 37), `gradle/libs.versions.toml`, `settings.gradle.kts`, root `build.gradle.kts` (KSP, Room plugin), `config/detekt/detekt.yml` (Room entities/DAOs and composables), `core/transport` server classes (`ControlServer`, `ControlConnectionHandler`, `ControlSession`, `ControlSessionDispatcher`, `EncryptedEnvelopeChannel`, `ServerHandshake`, `TransportConstants`), `AndroidKeystoreSecretStore`, `HandLiveFontFamilies`, `HLStatusIndicator`, `HLConnectionStatus`, `NOTICE`, `README.md`, `README.vi.md`, `CLAUDE.md`, `.github/workflows/ci-android.yml`.

No change under `shared/` for this card.

## Tests (real output)

```text
$ ./gradlew check        # JDK 21, platforms;android-37.0
BUILD SUCCESSFUL in 1m 16s
525 actionable tasks: 181 executed, 13 from cache, 331 up-to-date

per module (build/test-results): core/transport tests=44, core/crypto tests=35, core/data tests=11,
core/design tests=21, core/protocol tests=25 — 0 failures, 0 errors, 0 skipped

ControlChannelLimitsTest (real Netty, TLS 1.3): 17th pending connection → 4429; five AUTH_FAILED hellos then a
valid hello → 4429 with no frame before the close; silent session → 4411 after the 1 s test timeout; client pings
every 333 ms keep it open for 2.6 s; error ack to the server's rekey → 4410.
ConnectionAdmissionTest: 16 pending then refused; 5 failures in a minute block for exactly 5 minutes; older
failures do not count; 1 000 other addresses do not evict a blocked one.

$ ./gradlew :core:transport:assembleDebugAndroidTest
BUILD SUCCESSFUL
$ gh run list -R HandLive/handlive-android --branch feat/phase-01-clipboard
completed success … ci-android feat/phase-01-clipboard push 36160158618 4m10s
```

APK: `app-debug.apk` 46.9 MB (was 42 MB at the end of Phase 0: Compose 1.12, AppCompat, CameraX, ZXing, Room, icons, Inter Bold).

## Spec deviations and proposals

1. **CHECK constraint of `peer_platform`.** Room cannot declare `CHECK` constraints; the column is written only through the `PeerPlatform` enum converter, so values stay within `macos|ios|ipados`. Proposal: keep 0.9.1 as the logical schema and note that Android enforces it in code.
2. **Which failures block an IP.** CONN-01 API 4 says "wrong `mac`"; Android counts every `session/hello` rejected with `AUTH_FAILED` (wrong `mac`, wrong `device_id`, low-order ephemeral key), not `PAIR_UNKNOWN`/`PAIR_REVOKED`. A blocked or over-limit connection gets only the close code, no `session/error`. Proposal: say so in API 3–4.
3. **Idle detection needs the raw WebSocket.** Documented in code; nothing to change in the spec.
4. **Security Code case.** 8 lowercase hex digits (like the mDNS hints); the Mac must use the same case. Proposal: write "lowercase" in PAIR-02 field 10.
5. **Keystore names.** SET-01 API 1 names the keyset prefs `hl_keys`/`hl_identity`; Phase 0 stores them as `handlive_keyset`/`hl_secret_keyset`. Harmless; proposal: align the spec text with the code.
6. **MissingTranslation / Bold Text details** are in the A1.5 and A1.0 notes: Compose raises every weight by `fontWeightAdjustment` (+300), so Bold Text renders Inter 700 rather than "one step" heavier; exact one-step mapping would need a custom font resolver.

## Pending manual checks (no device here)

- `./gradlew :core:transport:connectedDebugAndroidTest` on a Pixel (Android 14/15) and a Samsung: TLS 1.3 through Conscrypt, 4400/404/TLS 1.2 refusal, Keystore identity reload.
- The 45 s idle close with a real Mac client pinging every 15 s (session must stay up).
- Bold Text on Android 12+ renders Inter Bold without clipping.

```text
Status: DONE_WITH_CONCERNS
Summary: compileSdk 37 + Compose 1.12, close codes 4410/4411/4429 with the 16-connection limit, IP block and 45 s idle close on a raw WebSocket, Room paired_device with sealed PRKs, identity keys, Material Symbols and Inter Bold, the shared signature vectors, and an instrumented Netty/TLS smoke test; ./gradlew check and CI green.
Concerns/Blockers: the instrumented test has not run on a device; no CHECK constraint in Room.
```
