English | [Tiếng Việt](code-standards.vi.md)

# HandLive — Code Standards

> Conventions for every repository in the workspace. Extend this file when a new convention appears.

## General

- Prefer YAGNI, KISS, DRY (in that order).
- File >200 lines → consider modularizing along logical boundaries (function/class/concern).
- New files: kebab-case, long descriptive names (self-documenting for LLM tools) for scripts, documents,
  resources, web. Source code follows the platform convention: Kotlin and Swift name the file after the
  main type inside it (PascalCase), Rust uses snake_case.
- No fake data/mocks/shortcuts just to pass a check. Implement real behavior.
- Never commit secrets, dotenv files, tokens, keys, credentials.
- Conventional commits, no AI references in messages.

## Wire protocol (stable — every platform must match)

- JSON envelope: `{v, type, id (uuid-v7), ts (ms), payload (base64 XChaCha20-Poly1305)}`.
- Audio binary frame: `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]`.
- Magic bytes `0x484C` ("HL"). Do not change the format ad hoc between platforms.

## Android (Kotlin)

- minSdk 29, targetSdk 35, compileSdk 37 (required by Compose 1.12 and later). Foreground Service with
  the right type (`FOREGROUND_SERVICE_CONNECTED_DEVICE` / `camera|microphone`).
- Crypto through Tink (HKDF may be implemented on top of `HmacSHA256`, checked against vectors); audio
  codec libopus through JNI.
- WSS server: Ktor 3 with the Netty engine (CIO does not support server-side TLS); exclude the native
  libraries that are not used (QUIC, HTTP/3, epoll, kqueue) and duplicate META-INF files to keep the APK
  small.
- Every BT-HFP call sits behind the `CallAudioRelay` abstraction (impl: `HfpCallAudioRelay`,
  `OpusWsCallAudioRelay` through Shizuku, `CdmCallAudioRelay` in the future).
- Call control through public APIs (`TelecomManager`, `TelephonyCallback`), no
  `InCallService` (plan §13 D9).
- OEM fragmentation → strategy pattern (`BtAdapterStrategy`: Samsung/Pixel/Generic).
- Libraries bundled in the app must be open source, with no proprietary components (ML Kit, Play
  Services); the only exception is FCM in a separate flavor (Phase 2). QR scanning: CameraX + ZXing core
  (Apache-2.0).

## macOS / iOS (Swift 6)

- Crypto through CryptoKit (`Curve25519`, `ChaChaPoly`). XChaCha20-Poly1305 = hand-written HChaCha20 +
  `ChaChaPoly`, checked against cross-platform test vectors (`docs/detailed-design/00-common-specs.md`
  §0.6.1).
- Wrap every `IOBluetooth*` call in a protocol abstraction (legacy API, deprecation risk).
- CMIOExtension / AudioServerPlugin are signed with Developer ID (mandatory; ad-hoc signing is rejected).
- Keys go into the Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; macOS uses the
  data-protection keychain (`kSecUseDataProtectionKeychain`) and the `keychain-access-groups` entitlement.

## Localization (C20, `docs/detailed-design/00-common-specs.md` 0.12)

- English is the default language, Vietnamese the second. Every displayed string comes from the catalog
  `shared/strings/ui-strings.json` through generated resources: Android `R.string`/`R.plurals`
  (`stringResource`, `pluralStringResource`), Apple accessors generated from the String Catalog. Never
  hard-code displayed text in code.
- Adding or changing a string: edit the detailed design (both versions), then the catalog in `shared`
  (separate commit), then the code.
- Logs, error codes, event names, commit messages, work reports: English, never translated.
- Format dates, times, numbers and sizes with locale-aware formatters; never build strings by concatenation.
- Android: lint `HardcodedText`, `MissingTranslation` are errors; `locales_config.xml`,
  `androidResources.localeFilters` = en, vi. Apple: `developmentLanguage: en`, `knownRegions` en,
  vi; purpose strings through `InfoPlist.xcstrings`.

## Documentation

- Bilingual: `X.md` in English (canonical), `X.vi.md` in Vietnamese, same structure; edit both in the
  same commit; line 1 is the language switcher (`English | [Tiếng Việt](X.vi.md)` /
  `[English](X.md) | Tiếng Việt`). Check: `python3 tools/docs/check_bilingual_docs.py`.
- Plans and reports from before 2026-09-25 (`plans/20260924-*`, `reports/phase-00-*`) stay in
  Vietnamese as an archive; their file names stay unchanged as identifiers.

## Rust (cloud relay)

- Actix-web + actix-ws. Stateless so it scales horizontally.
- Zero-knowledge: never decrypt, never log payloads. Minimal metadata only.

## Testing

- Run the narrowest test first, broaden when a shared contract is touched.
- Audio: verify E2E on the Opus/WS path; the HFP path relies on Bluetooth encryption (plan §13 D11). BT
  and Shizuku capture: test matrix of ≥6 real devices (Samsung/Pixel/Xiaomi/OPPO).
- Never hide test/lint/type/build failures.

## License and dependencies

- Every repository: Apache License 2.0 (`LICENSE`); no license header needed in each source file.
- New dependencies only under Apache-2.0-compatible licenses: Apache, MIT, BSD, ISC, MPL-2.0, OFL (fonts). No GPL, LGPL or AGPL in any form (dynamic linking included).
- Third-party assets bundled in the app (fonts, icons) are listed in the repository's `NOTICE` with their copyright and the path to the license file.
- Commits are made under a real person's name with a DCO sign-off (`git commit -s`); never name an AI tool as author or co-author (hook `.githooks/commit-msg`, CI job `commit-policy`).
