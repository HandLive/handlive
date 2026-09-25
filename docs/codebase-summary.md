English | [Tiếng Việt](codebase-summary.vi.md)

# HandLive — Codebase Summary

> **Update this file whenever the code structure changes significantly.**

## Current status (2026-09-25)

**Phase 0 is done** — repository scaffolding, protocol, encryption, tokens, CI; no user-facing features
yet. About 111 Kotlin files, 66 Swift files, 28 Rust files. Since 2026-09-25 the source code is split into
**five git repositories in one workspace** (decision I1 in `plans/20260925-implementation/plan.md`,
report `reports/repo-split.md`): this hub repository keeps only the docs, plans and documentation tools;
the four component repositories are cloned inside the hub directory (the hub git-ignores them).

```
HandLive/                          # hub repository "handlive"
├── CLAUDE.md, README.md
├── docs/                          # detailed-design/ (contracts), design-system/, PDR, architecture, code standards…
├── plans/20260925-implementation/ # Implementation plan, phase-00…05, reports/
├── tools/docs/                    # validate_design_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh             # clone <group-url> | status | run <git…> for all five repositories
├── .github/workflows/ci-docs.yml  # doc templates + schemas checked against the examples
│
├── android/   ← repository "handlive-android": Gradle KTS, AGP 9.4, Kotlin 2.4, compileSdk 36 / targetSdk 35 / minSdk 29
│   ├── app/                       # Compose, package app.handlive.android (placeholder screen)
│   ├── buildSrc/                  # HandLiveTheme generator from ../shared/design-tokens/tokens.json
│   ├── core/
│   │   ├── protocol/              # Envelope, Payload, Ack, ErrorCode (0.8.1), HlFrame, clipboard chunk, UUIDv7, b64/b64u
│   │   ├── crypto/                # Tink XChaCha20-Poly1305, X25519, Ed25519, HKDF (JCA), device_id, PRK, session/rekey/stream key schedule, hl_master key store
│   │   ├── transport/             # Ktor/Netty WSS (TLS 1.3, self-signed P-256 certificate), S-side handshake, capability, rekey, session replacement 4409
│   │   └── design/                # HandLiveTheme (4 appearances, Inter/Be Vietnam Pro/Roboto Mono), HLButton, HLSwitch, HLGroupedList, HLStatusIndicator
│   └── .github/workflows/ci-android.yml
├── apple/     ← repository "handlive-apple": XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol        # Codable protocol models, HLFrame, ErrorCode
│   ├── Packages/HLCrypto          # hand-written HChaCha20 + ChaChaPoly = XChaCha20-Poly1305, Curve25519, HKDF, key schedule, Keychain
│   ├── Packages/HLTransport       # client-side handshake (logic), 0.11 state machine
│   ├── Packages/HLDesignSystem    # Color Sets for 4 appearances + Swift code generated from tokens.json, Be Vietnam Pro font, 3 SwiftUI components
│   ├── macOS/HandLive/            # placeholder menu bar app (Phase 1)
│   └── .github/workflows/ci-apple.yml
├── relay/     ← repository "handlive-relay": Cargo workspace crates/relay-server (actix-web 4, sqlx, redis), migrations/ (0.9.4), dev docker-compose
│   └── .github/workflows/ci-relay.yml
└── shared/    ← repository "handlive-shared"
    ├── test-vectors/              # 14 vector files + envelope-roundtrip{,-apple}.json (cross-platform)
    ├── schemas/                   # JSON Schema 2020-12: envelope, payload, ack, error, session-*, capability-*
    ├── design-tokens/             # tokens.json (byte-identical to the hub's docs/design-system/tokens.json), type-extras.json
    ├── tools/vectors/, tools/schemas/   # generate_vectors.py (--check), verify_vectors.py, check_schemas.py; venv tools/.venv (gitignored)
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
| Android | `cd android && ./gradlew check` (JVM tests, Android Lint, ktlint, detekt); needs `JAVA_HOME` JDK 21, `ANDROID_HOME` with `platforms;android-36` |
| Apple (machine with Command Line Tools only) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test`; `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict` |
| Apple (with Xcode, CI) | `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` in the package directory (do not set `HL_SWIFT_TESTING_PACKAGE`) |
| Relay | `cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`; integration: `docker compose up -d --wait`, load `.env.example`, `cargo test -- --ignored` |
| Shared contracts | `cd shared && tools/.venv/bin/python tools/vectors/verify_vectors.py`, `… tools/vectors/generate_vectors.py --check`, `… tools/schemas/check_schemas.py` |
| Docs (hub) | `python3 tools/docs/validate_design_docs.py` — must print `problems=0` |
| All five repositories | `tools/workspace.sh status`; `tools/workspace.sh run fetch --all` |

Cross-platform roundtrip: with `HL_WRITE_ROUNDTRIP=1`, the Android/Apple crypto tests rewrite
`envelope-roundtrip.json` / `envelope-roundtrip-apple.json` in `shared/test-vectors`; each side's regular
tests decrypt the other side's file.

## Code structure (five repositories — decision I1 in the implementation plan)

| Repository (directory) | Platform | Role |
|------------------------|----------|------|
| `handlive` (hub, this directory) | Markdown, Python | `docs/`, `plans/`, `tools/docs/`, `tools/workspace.sh`; contracts for every other repository |
| `handlive-android` (`android/`) | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design}`, `feature/{pairing,clipboard,sms,call,callaudio,camera}` (added phase by phase) |
| `handlive-apple` (`apple/`) | Swift 6 | Shared `Packages/{HLProtocol,HLCrypto,HLTransport,HLDesignSystem,HLCallAudio}`; `macOS/HandLive` (menu bar, camera extension, microphone driver); `iOS/HandLive` + `iOS/NotificationService` |
| `handlive-relay` (`relay/`) | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `handlive-shared` (`shared/`) | JSON, Python | `test-vectors/`, `schemas/`, `design-tokens/`, `tools/vectors/`, `tools/schemas/` — source: `docs/detailed-design/00-common-specs.md` and the design system; `tools/bench/` (latency measurement, Phase 1) |

Each component repository has its own `CLAUDE.md` that spells out the workspace layout and that
repository's commands. Module details and task cards: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Where to start implementing

Phase 0 is done (reports: `plans/20260925-implementation/reports/phase-00-*.md`, review
`phase-00-review.md`) → gate G0 (still waiting for CI to run for real on the GitHub group) → Phase 1
(clipboard MVP). See `plans/20260925-implementation/plan.md` and `docs/project-roadmap.md`.
