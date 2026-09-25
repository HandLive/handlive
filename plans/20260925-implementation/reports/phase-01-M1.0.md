# Phase 1 — M1.0 [macOS]: Phase 0 leftovers

Card M1.0 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`
(created from `main` at aa03d8c, pushed).

## What was done

- **PascalCase file names** (docs/code-standards.md): every Swift source of HLProtocol, HLCrypto,
  HLTransport, HLDesignSystem and the app is named after its main type. Files that held two public types
  were split so each is named after its type: `X25519`/`Ed25519`, `HKDFSHA256`/`HMACSHA256`,
  `EnvelopeCipher`/`HLFrameCipher`, `SessionKeys`/`SessionHandshakeCrypto`; the capability `Features`
  struct moved next to the per-feature structs (`Features.swift`). The design-token generator now writes
  `Generated/HLColorToken.swift`, `HLTextStyle.swift` and one file per metric family (`HLSpacing`,
  `HLRadius`, `HLSize`, `HLDuration`). Scripts keep kebab-case (the code-standards rule for scripts).
- **Semantic colors through system APIs** (01-mau-sac.md table "Màu ngữ nghĩa và API"): the generator maps
  each token to AppKit on macOS and UIKit on iOS — labels (`tertiaryLabelColor`, `quaternaryLabelColor`),
  `placeholderTextColor`, `separatorColor`, `windowBackgroundColor`, `controlBackgroundColor`, fills
  (`NSColor.systemFill…`, macOS 14+ only, so macOS 13 falls back to the token hex), iOS backgrounds and
  grouped backgrounds, `opaqueSeparator`, Gray 2–6 (UIKit only; AppKit has none), `link` →
  `Color.accentColor`. Aliases inherit the mapping (`status-*`, `badge`). Hex stays only where the
  platform has no API (brand, accent, `text-*`, iOS-only backgrounds on the Mac).
- **AccentColor = `accent-fill`**: in the package catalog and in a new app asset catalog
  `macOS/HandLive/Resources/Assets.xcassets/AccentColor.colorset` written by the same generator;
  `project.yml` sets `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor`.
- **Be Vietnam Pro ExtraBold for Bold Text**: `BeVietnamPro-ExtraBold.ttf` (version 1.002, same release as
  the bundled SemiBold/Bold; source `https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro/`,
  139,680 bytes, SHA-256 `44dbfa01…0650d02`), listed in `NOTICE`. `HLTextStyleSpec` carries
  `boldTextPostScriptName` (SemiBold → Bold, Bold → ExtraBold) used when `legibilityWeight == .bold`.
- **type-extras.json**: the generator now reads `relativeTo`, `emphasisWeight` and `fontFeatures` (`tnum`)
  from `shared/design-tokens/type-extras.json` instead of hard-coded tables (review item 23);
  `HLTextStyleSpec.emphasisWeight` / `emphasisFontWeight` are new.
- **New 0.11 error edges** in `ConnectionStateMachine`: ConnectingLAN → Backoff (network/TLS error that is
  not a pin mismatch), ConnectingLAN → Idle (every instance fails the pin: "Needs re-pairing"),
  ConnectingRelay → Backoff, WaitingPeer → Backoff, Discovering → Backoff (grace elapsed, relay disabled),
  Discovering/Backoff/Connected → Idle on unpair. `Idle` now carries its reason (`notPaired`, `noNetwork`,
  `needsRepair`); `ConnectionStatus` gains `notPaired` and `needsRepair` and no longer holds display text.
- **Close codes 4410/4411/4429 client side**: `HLProtocol.CloseCode` models the whole 0.8.3 table (unknown
  codes kept as `.other` for logs); `HLTransport.CloseReaction` maps close codes and `session/error` codes
  to the client's next step (4401/AUTH_FAILED → wait `ReconnectBackoff.authFailedDelay` = 300 s, 4403 and
  PAIR_UNKNOWN → remove the pair, 4426 → update required, 4409 → no reconnect, 4410/4411/4429/4408/4400 →
  backoff).

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 2a6a605 | refactor(apple): name protocol, crypto and transport sources after their main type |
| 1712ef1 | refactor(apple): name design-system sources and generated files after their types |
| 4e4bdb4 | build(apple): bundle Be Vietnam Pro ExtraBold for the Bold Text step |
| 7d1aa8c | feat(apple): map semantic colors to system APIs and AccentColor to accent-fill |
| 2220c60 | feat(apple): model WebSocket close codes including 4410, 4411 and 4429 |
| 244c387 | feat(apple): add the new 0.11 error edges and client close-code reactions |

## Files

- Renamed: all `*.swift` under `apple/Packages/*/Sources`, `apple/Packages/*/Tests`, `apple/macOS/HandLive`.
- Created: `Packages/HLCrypto/Sources/HLCrypto/{Ed25519,HMACSHA256,HLFrameCipher,SessionHandshakeCrypto}.swift`,
  `Packages/HLProtocol/Sources/HLProtocol/CloseCode.swift`, `Packages/HLProtocol/Tests/HLProtocolTests/CloseCodeTests.swift`,
  `Packages/HLTransport/Sources/HLTransport/CloseReaction.swift`,
  `Packages/HLDesignSystem/Sources/HLDesignSystem/Resources/Fonts/BeVietnamPro-ExtraBold.ttf`,
  `macOS/HandLive/Resources/Assets.xcassets/{Contents.json,AccentColor.colorset/Contents.json}`.
- Changed: `Packages/HLDesignSystem/Scripts/*.py`, generated `HLColorToken.swift`, `HLTextStyle.swift`,
  `Colors.xcassets/AccentColor.colorset`, `Typography/HLTextStyleSpec.swift`, `Typography/HLBrandFonts.swift`,
  `Tests/HLDesignSystemTests/{ColorSetTests,BrandFontTests,TextStyleMappingTests,RepositoryPaths}.swift`,
  `Packages/HLTransport/Sources/HLTransport/{ConnectionStateMachine,ReconnectBackoff}.swift`,
  `Tests/HLTransportTests/ConnectionStateMachineTests.swift`, `project.yml`, `NOTICE`.

## Tests (real output; Command Line Tools, `HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=…/MacOSX26.sdk swift test`)

```text
HLProtocol     ✔ Test run with 25 tests in 6 suites passed after 0.013 seconds.
HLCrypto       ✔ Test run with 19 tests in 5 suites passed after 0.016 seconds.
HLTransport    ✔ Test "Every edge of the diagram" with 23 test cases passed
               ✔ Test "Edges implied by CONN-02 E1 and PAIR-03" with 8 test cases passed
               ✔ Test run with 11 tests in 2 suites passed after 0.004 seconds.
HLDesignSystem ✔ Test "Màu ngữ nghĩa trên Mac gọi NSColor" with 6 test cases passed
               ✔ Test "Nền tô systemFill… chỉ có API từ macOS 14; macOS 13 dùng hex của token" passed
               ✔ Test "AccentColor = accent-fill, cả trong package và catalog của app" passed
               ✔ Test "Chữ đậm tăng một bậc weight: SemiBold → Bold, Bold → ExtraBold" passed
               ✔ Test run with 20 tests in 5 suites passed after 0.085 seconds.
$ TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict   → 0 violations
$ python3 Packages/HLDesignSystem/Scripts/generate-design-tokens.py --check  → OK (80 files)
```

`CloseCodeTests` read the 0.8.3 table from `00-common-specs.md`; `TextStyleMappingTests` now also compare
the "Nhấn mạnh" column with `emphasisWeight`.

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36154989359 — success (commit policy, `xcodebuild
  test` of every package with Xcode 26.3, SwiftLint, `xcodegen generate`, unsigned app build).

## Spec deviations and proposals

1. **Two-type files split.** Instead of umbrella names, files with two public types were split so every
   file is named after its type. `SessionMessages.swift` (eight small `session`/`stream` data types) keeps
   an umbrella name; proposal: code-standards could say "or the umbrella noun of a family of small types".
2. **`link` token → `Color.accentColor`** per 01-mau-sac.md; on a Mac with a non-multicolor accent the link
   follows the user's accent, not `accent`. Matches the doc's AppKit column (`controlAccentColor`).
3. **Unpairing from any state reaches Idle** and **no network → Idle(noNetwork)** from any non-idle state:
   0.11 draws only some of these edges; CONN-02 E1 and PAIR-03 imply the rest. Proposal: add
   "any → Idle: no network (CONN-02 E1)" and "any → Idle: last pair removed" to the 0.11 diagram.
4. **"Needs re-pairing" is decided on mDNS instances only**: a pin mismatch on the `last_host` fast path
   alone (the address may now belong to another device) just drops that candidate; only when every
   hint-matching instance fails the pin does the client stop (the hint proves the instance is our phone).
5. **4429 RATE_LIMITED backs off on the normal schedule** (reaching 30 s); the spec gives no client rule.
6. `HLConnectionStatus.cameraStreaming` was removed (no catalog string until Phase 5); `.notPaired` added.

## Pending manual checks

- Xcode previews of `StatusIndicator`, `HLButtonStyle`, `GroupedList` in the four appearances (no Xcode
  here; CI compiles the `#Preview` blocks).
- Bold Text on a real Mac: brand titles step up to ExtraBold/Bold.

Status: DONE
Summary: File names follow PascalCase, semantic colors call AppKit/UIKit (hex only as the macOS 13 or
no-API fallback), AccentColor is accent-fill in the package and the app, ExtraBold backs Bold Text, and the
client has the new 0.11 edges and close-code reactions; tests, lint and CI are green.
Concerns/Blockers: none.
