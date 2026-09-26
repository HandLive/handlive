English | [Tiếng Việt](codebase-summary.vi.md)

# HandLive — Codebase Summary

> **Update this file whenever the code structure changes significantly.**

## Current status (2026-09-26)

**Phase 1 (clipboard MVP) is merged into `main`** of handlive-android, handlive-apple, handlive-shared and
handlive-relay (2026-09-26, CI green); gate G1 (latency and UI checks on real Pixel/Samsung phones and Macs) is
still open. The UI is multilingual — English by
default, Vietnamese second — with every string in the shared catalog (C20). About 297 Kotlin files, 188 Swift
files (plus generated ones), 29 Rust files and 36 Python tool files. Since 2026-09-25 the source code is split
into **five git repositories in one workspace** (decision I1 in `plans/20260925-implementation/plan.md`, report
`reports/repo-split.md`): this hub repository keeps only the docs, plans and documentation tools; the four
component repositories are cloned inside the hub directory (the hub git-ignores them).

```
HandLive/                          # hub repository "handlive"
├── CLAUDE.md, README.md (+ README.vi.md)
├── docs/                          # every page as X.md (English) + X.vi.md (Vietnamese): detailed-design/, design-system/, privacy, PDR…
├── plans/20260925-implementation/ # Implementation plan, phase-00…05 (both languages), reports/ (English)
├── tools/docs/                    # validate_design_docs.py, check_bilingual_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh             # clone | status | run | remotes | push | hooks for every repository
├── .github/workflows/ci-docs.yml  # doc templates, bilingual pairs, schemas checked against the examples
│
├── android/   ← "handlive-android": Gradle KTS, AGP 9.4, Kotlin 2.4, compileSdk 37 / targetSdk 35 / minSdk 29
│   ├── app/                       # Compose screens: setup (SET-01), devices, pairing, settings (SET-02), consent, HUD
│   ├── buildSrc/                  # generators: HandLiveTheme from tokens.json, strings.xml (en, vi) from the string catalog
│   ├── core/protocol, core/crypto, core/transport, core/design   # as in Phase 0, plus close codes 4410/4411/4429 and limits
│   ├── core/data/                 # Room database (paired_device, 0.9.1)
│   ├── core/strings/              # generated resources of shared/strings/ui-strings.json, per-app language
│   ├── feature/connection/        # HandLiveService (FGS), mDNS with hourly hints, sessions, capability, HLBENCH/1 logs
│   ├── feature/pairing/           # QR (CameraX + ZXing) and PIN pairing, devices, Security Code, unpairing
│   ├── feature/clipboard/         # Accessibility and manual sending, receive, image chunks, safe auto-clear (C17)
│   └── .github/workflows/ci-android.yml
├── apple/     ← "handlive-apple": XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol, HLCrypto   # protocol models; XChaCha20-Poly1305, pairing and session keys, Keychain
│   ├── Packages/HLTransport       # Network.framework WSS with pinning, NWBrowser discovery, handshake, 0.11 state machine
│   ├── Packages/HLAppCore         # settings, local identity, sealed pair store, clipboard engine
│   ├── Packages/HLLocalization    # Localizable/InfoPlist String Catalogs and L10n accessors generated from the catalog
│   ├── Packages/HLDesignSystem    # Color Sets and fonts from tokens.json, SwiftUI components
│   ├── Packages/HLMacUI           # menu bar menu, welcome window, pairing sheet, Settings panes, pasteboard
│   ├── macOS/HandLive/            # menu bar app entry point, generated assets and purpose strings
│   └── .github/workflows/ci-apple.yml
├── relay/     ← "handlive-relay": crates/relay-server (actix-web 4, sqlx, redis), migrations/ (0.9.4), dev docker-compose
│   └── .github/workflows/ci-relay.yml
└── shared/    ← "handlive-shared"
    ├── test-vectors/              # crypto, envelope, session, relay-auth, ed25519, pair-handshake, discovery-hint, round trips
    ├── schemas/                   # JSON Schema 2020-12: envelope, payload, ack, error, session-*, capability-*, close codes
    ├── strings/                   # ui-strings.json (every UI string, en + vi) and its schema
    ├── design-tokens/             # tokens.json (byte-identical to the hub's docs/design-system/tokens.json), type-extras.json
    ├── tools/vectors, schemas, strings, bench   # generators and checkers; HLBENCH/1 latency scripts; venv tools/.venv
    └── .github/workflows/ci-shared.yml
```

A sixth repository, `HandLive/.github` (cloned as `.github-org/`), holds the org profile and the default community files for every repository: CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, PR/issue templates.

Paths between repositories are relative and **mandatory**: Gradle and the Android tests read `../shared` (system property `hl.shared.dir`), the `core:design` tests also read
`../docs/design-system/1-foundations` (`hl.docs.dir`); the Apple tests read `../shared` and
`../docs/design-system/1-foundations/03-kieu-chu.md`; the relay tests read `../shared/test-vectors`;
`shared/tools/schemas/check_schemas.py` reads `../docs/detailed-design` (override it with
`HANDLIVE_DOCS_DIR`). Each repository's CI rebuilds exactly this layout with `actions/checkout` (the hub at
the workspace root when docs are needed, the part into `<phần>/`, `handlive-shared` into `shared/`; private
repositories need the secret `HANDLIVE_REPOS_TOKEN` — `docs/deployment-guide.md`).

## Test commands

| Part | Command |
|------|---------|
| Android | `cd android && ./gradlew check` (JVM tests, Android Lint, ktlint, detekt); needs `JAVA_HOME` JDK 21 and `ANDROID_HOME` with `platforms;android-37` |
| Apple (machine with Command Line Tools only) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test` (SwiftUI packages add `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`); `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict` |
| Apple (with Xcode, CI) | `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` in the package directory (do not set `HL_SWIFT_TESTING_PACKAGE`) |
| Relay | `cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`; integration: `docker compose up -d --wait`, load `.env.example`, `cargo test -- --ignored` |
| Shared contracts | `cd shared && tools/.venv/bin/python tools/vectors/verify_vectors.py`, `… tools/vectors/generate_vectors.py --check`, `… tools/schemas/check_schemas.py`, `… tools/strings/check_strings.py [--docs]` |
| Docs (hub) | `python3 tools/docs/validate_design_docs.py` and `python3 tools/docs/check_bilingual_docs.py` — both must print `problems=0` |
| All five repositories | `tools/workspace.sh status`; `tools/workspace.sh run fetch --all` |

Cross-platform roundtrip: with `HL_WRITE_ROUNDTRIP=1`, the Android/Apple crypto tests rewrite
`envelope-roundtrip.json` / `envelope-roundtrip-apple.json` in `shared/test-vectors`; each side's regular
tests decrypt the other side's file.

## Code structure (five repositories — decision I1 in the implementation plan)

| Repository (directory) | Platform | Role |
|------------------------|----------|------|
| `handlive` (hub, this directory) | Markdown, Python | `docs/`, `plans/`, `tools/docs/`, `tools/workspace.sh`; contracts for every other repository |
| `handlive-android` (`android/`) | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design,data,strings}`, `feature/{connection,pairing,clipboard}`; `feature/{sms,call,callaudio,camera}` arrive phase by phase |
| `handlive-apple` (`apple/`) | Swift 6 | Shared `Packages/{HLProtocol,HLCrypto,HLTransport,HLAppCore,HLLocalization,HLDesignSystem,HLMacUI}`; `macOS/HandLive` (menu bar; camera extension and microphone driver in Phase 5); `iOS/HandLive` + `iOS/NotificationService` in Phase 2 |
| `handlive-relay` (`relay/`) | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `handlive-shared` (`shared/`) | JSON, Python | `test-vectors/`, `schemas/`, `strings/`, `design-tokens/`, `tools/{vectors,schemas,strings,bench}` — source: `docs/detailed-design/00-common-specs.md` and the design system |

Each component repository has its own `CLAUDE.md` that spells out the workspace layout and that
repository's commands. Module details and task cards: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Where to start implementing

Phase 0 and the Phase 1 code are done (reports: `plans/20260925-implementation/reports/phase-00-*.md`,
`phase-01-*.md`) → gate G1 (open): run the device matrix of `shared/tools/bench/README.md` on real phones and Macs;
Phase 1 is already merged into `main` → Phase 2 (SMS, iOS app, relay, push), in progress on
`feat/phase-02-sms-ios-relay`. See
`plans/20260925-implementation/plan.md` and `docs/project-roadmap.md`.
