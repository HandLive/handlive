# Phase 1 — M1.5 [macOS]: localization (0.12.2–0.12.3)

Card M1.5 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`.
Input: `shared/strings/ui-strings.json` from handlive-shared `feat/phase-01-clipboard` (S1.2).

## What was done

- **New package `Packages/HLLocalization`** (`defaultLocalization: "en"`, macOS 13 / iOS 16):
  - `Scripts/generate-strings.py` (+ `strings_catalog.py`, `strings_apple_resources.py`,
    `strings_swift_accessors.py`; standard library only) reads the catalog and writes, committed:
    - `Sources/HLLocalization/Resources/Localizable.xcstrings` — every key whose `platforms` has `macos` or
      `ios` (the package is shared by the Mac and the future iPhone/iPad app), `sourceLanguage` en, keys kept
      with dots, plurals as String Catalog plural variations (en `one`/`other`, vi `other`), `{name}` →
      `%1$@` / `%1$lld` numbered in `args` order, `%` escaped only when the string takes arguments,
      Xcode's JSON layout (no diff when opened in Xcode).
    - `Sources/HLLocalization/Generated/L10n.swift` — type-safe accessors: `L10n.Status.connecting`,
      `L10n.Pairing.pairedWith(deviceName:)`, `L10n.Status.messagesWaiting(count:)`; nested enums per key
      segment, Swift keywords escaped (`` L10n.Common.`continue` ``), each accessor documented with the
      English source text.
    - `Sources/HLLocalization/CommandLineToolsResources/{en,vi}.lproj/Localizable.strings|.stringsdict` —
      what Xcode compiles the String Catalog into; used only by `swift test` with Command Line Tools
      (no `xcstringstool` there). `Package.swift` picks the String Catalog under Xcode and the `.lproj` files
      otherwise, like HLDesignSystem does for its asset catalog.
    - The app's `macOS/HandLive/Resources/InfoPlist.xcstrings` (purpose strings, en + vi) and the English
      purpose strings in `macOS/Info.plist` (only the catalog's `plist_key`s are rewritten; `NSBonjourServices`
      stays).
    - `--check` renders everything in memory and fails on a missing, different or stray file.
  - `L10nLookup` resolves keys in the package bundle in the language the system picks; plurals use the
    locale of that language; tests can ask for one language explicitly.
- **project.yml**: `options.developmentLanguage: en`; XcodeGen reads the String Catalog and lists
  `knownRegions = (Base, en, vi)` (checked in the generated `project.pbxproj`); HLLocalization added;
  `INFOPLIST_FILE: macOS/Info.plist` merged with the generated keys.
- **Strings moved into the catalog**: the purpose strings (microphone, Focus, local network) now come from
  `infoplist.*`; HLDesignSystem's `HLConnectionStatus` text, short label and VoiceOver sentence come from
  `status.*`; previews use catalog labels; the menu bar placeholder uses `L10n`. The only Vietnamese
  literal left in code (a `precondition` message) became English (developer-facing).
- **CI** tests HLLocalization too; README/README.vi describe the package and both generators.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| d6bc2a1 | feat(apple): add HLLocalization with a generator for String Catalogs and accessors |
| 000c33c | test(apple): check the generated strings in English and Vietnamese |
| 34a941a | feat(apple): localize the Mac app with English as the development language |
| c875a9b | refactor(apple): take design-system text from the string catalog |
| 092f37f | docs: describe HLLocalization, the generated files and the new layout |

No change in handlive-shared.

## Files

Created: `apple/Packages/HLLocalization/**` (Package.swift, Scripts/*.py, Sources, Tests),
`apple/macOS/Info.plist`, `apple/macOS/HandLive/Resources/InfoPlist.xcstrings`.
Changed: `apple/project.yml`, `apple/macOS/HandLive/HandLiveMacApp.swift`,
`apple/Packages/HLDesignSystem/{Package.swift,Sources/…/Components/*.swift,Tests/…/StatusIndicatorTests.swift}`,
`apple/Packages/HLProtocol/Sources/HLProtocol/HLUUID.swift`, `apple/.github/workflows/ci-apple.yml`,
`apple/HandLive.xcworkspace/contents.xcworkspacedata`, `apple/README.md`, `apple/README.vi.md`.

## Tests (real output)

```text
$ cd apple/Packages/HLLocalization && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=…/MacOSX26.sdk swift test
✔ Test "Strings without arguments" with 2 test cases passed          (en, vi: every Apple key = catalog text)
✔ Test "Strings with arguments keep them in place" with 2 test cases passed
✔ Test "Plurals: English one and other, Vietnamese other only" passed (counts 0, 1, 2, 21)
✔ Test "A percent sign in a formatted string stays a percent sign" passed
✔ Test "Accessors resolve in the process language, never to the bare key" passed
✔ Test "Localizable.xcstrings: source en, every Apple key in en and vi with the same placeholders" passed
✔ Test "Purpose strings: InfoPlist.xcstrings in en and vi, Info.plist in en" passed
✔ Test "UI calls take text from L10n, not from string literals" passed
✔ Test "generate-strings.py --check: every generated file matches ui-strings.json" passed
✔ Test run with 9 tests in 3 suites passed after 0.083 seconds.

$ python3 apple/Packages/HLLocalization/Scripts/generate-strings.py --check
OK: 8 files match ui-strings.json
HLDesignSystem: ✔ Test run with 21 tests in 5 suites passed   (status text from the catalog, en + vi)
swiftlint --strict: 0 violations
```

The scan test (0.12.5 "no hard-coded UI text") looks at every Swift source of `apple/macOS` and
`apple/Packages/*/Sources` except generated files for UI calls (`Text(`, `Button(`, `Label(`, `Toggle(`,
`Section(`, `.help(`, `.accessibilityLabel(`, `MenuBarExtra(`, `GroupedSection(` …) with a literal, text
properties assigned a literal, and any literal written in Vietnamese.

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36156221193 — success. Under Xcode 26.3 the
  package compiles `Localizable.xcstrings` (`CompileXCStrings`) and the same tests pass against the compiled
  catalog (en/vi lookups, positional `%1$lld` inside plural variations); the unsigned app builds with
  `InfoPlist.xcstrings`.

## Spec deviations and proposals

1. **Command Line Tools fallback.** 0.12.2 names only String Catalogs; without Xcode they cannot be compiled,
   so the generator also writes the equivalent `.lproj` files, used only in that mode. Both are checked by
   `--check`; CI tests the real String Catalog.
2. **`infoplist.*` keys also get accessors** (`L10n.Infoplist.localNetworkUsage`): SET-03 step 9 needs a
   local-network explanation before the system prompt and the catalog has only its title
   (`permission.local_network_primer_title`); the purpose string says exactly what the primer must say
   (benefit, where data goes), so the primer body reuses it instead of a duplicate key.
3. **Double arguments** map to `%N$f`; 0.12.2 names only `%1$@`/`%1$lld` and no Apple string uses `double`
   yet. Proposal: state the Apple specifier for `double` in 0.12.2 (or forbid `double`, since numbers are
   formatted before they are passed, 0.12.3).
4. **Plural strings take exactly one argument `count`** (the generator fails otherwise; `check_strings.py`
   already requires `count`). A plural with a second argument would need String Catalog substitutions.
5. The catalog lacks texts the Mac screens of M1.1/M1.3 need (SET-03 E1, E3–E5 guidance, a PIN instruction,
   PAIR-02 detail labels); they are added under the lock while implementing those cards and listed in their
   reports.

## Pending manual checks

- Run the app with the system in English and with `-AppleLanguages (vi)` (no Xcode here to launch it; CI
  only builds it): menus, windows and purpose strings in both languages; per-app language in System
  Settings › General › Language & Region › Applications lists HandLive with English and Tiếng Việt.
- Largest text size in both languages once the M1.1 screens exist.

Status: DONE
Summary: HLLocalization generates Localizable.xcstrings, InfoPlist.xcstrings, the Info.plist purpose strings
and type-safe L10n accessors from the shared catalog with a --check test; project.yml uses en as development
language with en and vi regions, existing UI text comes from the catalog, and tests pass locally and on CI.
Concerns/Blockers: none for the card; running the app in both languages is a pending manual check.
