English | [Tiếng Việt](phase-01-bang-nho-tam-mvp.vi.md)

# Phase 1 — Android ↔ Mac clipboard on the LAN (MVP)

**Goal:** pair with a QR code, find each other automatically on Wi-Fi, send clipboard text and images
both ways with end-to-end encryption, clear them automatically after 60 seconds. A usable product for
one phone and one Mac, with an English (default) and Vietnamese UI (C20).

## Context

- Leaf functions: `01-setup-settings.md` SET-01, SET-02 (fields 1–6, 21–23, 31), SET-03 (Mac);
  `02-pairing.md` PAIR-01 (QR and PIN on the LAN), PAIR-02, PAIR-03 (flow A); `03-connectivity.md`
  CONN-01, CONN-02; `04-clipboard.md` CLIP-01, CLIP-02, CLIP-03, CLIP-05 and the common rules QC1–QC9.
- Design system: `docs/design-system/3-platforms/03-android.md`, `01-macos.md`;
  `2-patterns/01-thiet-lap-ban-dau.md`, `02-xin-quyen.md`, `04-cai-dat.md`, `05-phan-hoi-va-tai.md`;
  components `Onboarding`, `PermissionPrimer`, `ConsentSheet`, `PairingCard`, `DeviceRow`,
  `GroupedList`, `Toggle`, `MenuBarMenu`, `StatusIndicator`, `Feedback`, `Alert`.
- Decisions: D4/D12 (Accessibility), C6 (mDNS hint), C10 (Mac paste permission), C15, C16, C17, C20
  (multiple languages); plan I7, I8.
- Localization: `00-common-specs.md` 0.12; design system `1-foundations/09-viet-noi-dung.md` (the
  "English" section and the sections on Vietnamese).

## Requirements and measurable criteria

- Text < 50 ms from copying until it can be pasted on the other device (LAN); 5 MB image < 2 s;
  reconnect < 3 s after a Wi-Fi change.
- Never read the clipboard without consent (CLIP-01 fields 2, 3); sensitive content is blocked (QC3);
  loops and conflicts per QC4, QC8.
- Android 12+ shows a system toast on every read — accepted and disclosed.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| S1.1 [shared] | Leftover from Phase 0: vectors `relay-auth.json` (`HLREG1`/`HLAUTH1` with the RFC 8032 TEST 1–3 keys) and `ed25519.json` (§7.1 TEST 1–3 plus negative vectors) for the `attestation` signature; the `session/error` schema requires `min_protocol` with `UNSUPPORTED_VERSION`; close codes 4410/4411/4429 into the schema and catalog | `shared/test-vectors`, `shared/schemas` | Relay, Android and Apple all pass the new vectors |
| S1.2 [shared] | UI string catalog (0.12, C20): `shared/strings/ui-strings.json`, schema `ui-strings.schema.json`, `shared/tools/strings/check_strings.py` (checks 0.12.5; `--docs` cross-checks the docs, warnings only), a check step in `ci-shared`; load every UI string of the Phase 1 leaf functions (SET-01…03, PAIR-01…03, CONN-01/02, CLIP-01/02/03/05, the 0.11 states, Mac purpose strings, Android notification channels, the `push.*` keys of CONN-04): `vi` verbatim from the docs, `en` per the design system's "English" section; extend `check_schemas.py` to accept catalog examples | `shared/strings`, `shared/tools/strings`, `shared/tools/schemas` | `check_strings.py` green; every Phase 1 UI string has a key, with both `en` and `vi`; commit and push early because Android and Apple depend on it |
| A1.0 [android] | Leftover from Phase 0: raise compileSdk to 37 (`platforms;android-37`) and move to the latest Compose BOM; close codes 4410/4411/4429; a limit of 16 connections that have not completed the handshake, IP blocking, silent close after 45 s (CONN-01 API 3–4, CONN-02); instrumented smoke test of Netty + TLS 1.3 on a real device; bundle Material Symbols Rounded and Inter 700 (Bold Text); Room `paired_device` | `android/` | `./gradlew check` green; instrumented tests pass on a Pixel |
| M1.0 [macOS] | Leftover from Phase 0: Swift file names in PascalCase (code-standards); map every semantic color token to a system API where one exists (hex only for macOS 13); `AccentColor` = `accent-fill` and `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` in `project.yml`; Be Vietnam Pro ExtraBold for Bold Text; the new error edges of 0.11 and close codes 4410/4411/4429 on the client side | `apple/` | `swift test` green for the packages; previews in 4 appearances |
| A1.1 [android] | `HandLiveService`: FGS `connectedDevice`, channel `hl_service`, start WSS on 47800–47809, mDNS advertising with an hourly hint (CONN-01 API 1, C6), session keep-alive and reconnect (CONN-02) | `android/feature/…`, `android/app` | The Mac finds it in < 2 s; the hint changes every hour; the ongoing notification uses exactly the string of CONN-01 field 6 |
| A1.2 [android] | Pairing: QR scanning (CameraX + ZXing core, no ML Kit — I8), ECDH X25519 + HKDF → `PRK`, mutual signed attestation, TLS certificate pinning, 6-digit PIN + Argon2id (PAIR-01 LAN); device list and Security Code (PAIR-02); unpair flow A (PAIR-03) | `android/feature/pairing` | Every E of PAIR-01…03 has a test; the Security Code is the same on both devices |
| A1.3 [android] | Clipboard: `ClipboardAccessibilityService` + `ClipboardReadActivity` + disclosure (CLIP-01), manual paths (notification button, Quick Settings tile, Share), receive and write (CLIP-02 API 3), chunked images (CLIP-03), safe auto-clear (CLIP-05, C17), sensitive-content blocking QC3, conflicts QC8, forwarding to other clients QC6 | `android/feature/clipboard` | Latency measured with `tools/bench/clip-latency` meets the target; never clears the user's own content by mistake (C17 test) |
| A1.4 [android] | UI: onboarding SET-01 (permission explainer screens with a single "Continue" button), Settings SET-02 (Clipboard group; Internet Connection can be turned off), Devices, the Accessibility disclosure (`ConsentSheet`), feedback (toast/HUD) — per `03-android.md`; check the English and Vietnamese system setting names on real devices | `android/app` | Strings from the catalog, with both `en` and `vi`; TalkBack reads the state; 200% font scale truncates no text in either language |
| M1.1 [macOS] | Menu bar app: menu-style `MenuBarExtra`, switching the activation policy `.accessory` ↔ `.regular` (SET-03 step 6, SET-02 field 31), welcome window (`Onboarding`), a six-pane `Settings` scene, `SMAppService` login item, local-network explainer screen, paste-permission check C10 | `apple/macOS/HandLive` | The menu matches `MenuBarMenu`; with "Show HandLive in Menu Bar" off, the app has a Dock icon and the File/Edit/View/Window/Help menu bar (Tệp/Sửa/Xem/Cửa sổ/Trợ giúp when running in Vietnamese) |
| M1.2 [macOS] | `HLTransport` for real: `NWBrowser` `_handlive._tcp`, WSS with certificate pinning, handshake, capability, CONN-02 backoff, the `StatusIndicator` status indicator | `apple/Packages/HLTransport`, app | Reconnect < 3 s after a Wi-Fi change; the 0.11 state machine has tests |
| M1.3 [macOS] | Pairing: the `PairingCard` sheet showing the QR code (content per PAIR-01 API 1), countdown to the next code, fallback PIN, device row and Security Code, unpair with an alert (Alert README) | app | Pairs with A1.2 on real devices; Esc/Return behave per the HIG |
| M1.4 [macOS] | Clipboard: read `changeCount` every 500 ms, write `NSPasteboard` with the `app.handlive.clip-id` type, chunked PNG/JPEG images, auto-clear (CLIP-05), sensitive-content blocking (`org.nspasteboard.*` types + Luhn), conflicts QC8, feedback as a checkmark in the menu bar (`Feedback`; check Magic Replace on a real device, with a static fallback) | app | Measured latency meets the target; no content is read while `changeCount` is unchanged |
| A1.5 [android] | Localization (0.12.2–0.12.3): a Gradle task in `buildSrc` generates `values/strings.xml` (en) and `values-vi/strings.xml` from the catalog into the build folder; `locales_config.xml` + `android:localeConfig`; `androidResources.localeFilters` en, vi; AppCompat `setApplicationLocales` for SET-02 field 32 (Android 10–12) and opening the system app-language page (13+); lint `HardcodedText`, `MissingTranslation` as errors; a pseudo-locale for debug; move the app's existing strings into the catalog | `android/buildSrc`, `android/app`, `android/core/design` | `./gradlew check` green; a test compares the generated resources with the catalog; switching the language en ↔ vi switches the whole UI |
| M1.5 [macOS] | Localization (0.12.2–0.12.3): a script generates `Localizable.xcstrings`, `InfoPlist.xcstrings` and type-safe Swift accessors from the catalog (like the token generator: generated files are committed, `--check` in the tests); `project.yml` `developmentLanguage: en`, `knownRegions` en, vi; move the purpose strings (microphone, Focus, local network) and the existing strings into the catalog | `apple/` | `swift test` green; `--check` matches the catalog; the app runs in English by default and in Vietnamese with `-AppleLanguages (vi)` |
| T1.1 [test] | `shared/tools/bench/`: scripts measuring text/image latency and reconnect time (timestamp logs on both sides, synchronized with NTP or the envelope `ts`); manual test scenarios per the device matrix | `shared/tools/bench/`, `reports/phase-01-T1.1.md` | A table of measurements for Pixel, Samsung, Intel Mac and Apple silicon |

Order: S1.2 before any UI task; A1.5 before A1.4; M1.5 before M1.1 and M1.3. Commit S1.1 and S1.2
and push them early to the `feat/phase-01-clipboard` branch of `handlive-shared`, because Android and
Apple read them.

## Testing

- Unit: 64 KiB chunking, SHA-256, `clip_id` deduplication (256 entries/10 minutes), Luhn, `origin_ts`
  comparison.
- Integration: an Android emulator (API 34) + the Mac app on the same machine over loopback is not
  enough (mDNS) → use real devices; JVM tests emulate the Mac client with a Ktor client for the
  protocol part.
- UI in `en` and `vi`: on Android, switch the app language (`adb shell cmd locale set-app-locales` or
  SET-02 field 32), pseudo-locale `en-XA` for debug builds; on macOS, run with `-AppleLanguages (vi)`.
- End-of-phase acceptance: gate G1 in `plan.md`.

## Risks and rollback

- The OEM blocks the Accessibility service or `ClipboardReadActivity` cannot take focus → the manual
  path is always there; record the failing devices in `docs/deployment-guide.md`.
- macOS 15.4+ `accessBehavior` `.ask` → the "Send Clipboard to Phone" menu item still sends.
- Google Play rejects Accessibility (C15 accepted the risk) → distribute the APK directly for the
  build with Accessibility.
