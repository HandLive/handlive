# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại (25/09/2026)

**Phase 0 xong trên nhánh `feat/phase-00-khung`** — khung kho, giao thức, mã hóa, token, CI; chưa có tính năng người dùng. Khoảng 111 file Kotlin, 66 file Swift, 28 file Rust.

```
HandLive/
├── CLAUDE.md, README.md
├── docs/                          # detailed-design/ (hợp đồng), design-system/, PDR, kiến trúc, chuẩn mã…
├── plans/20260925-implementation/ # Kế hoạch triển khai, phase-00…05, reports/phase-00-*.md
├── android/                       # Gradle KTS, AGP 9.4, Kotlin 2.4, compileSdk 36 / targetSdk 35 / minSdk 29
│   ├── app/                       # Compose, gói app.handlive.android (màn giữ chỗ)
│   ├── buildSrc/                  # Generator HandLiveTheme từ shared/design-tokens/tokens.json
│   └── core/
│       ├── protocol/              # Envelope, Payload, Ack, ErrorCode (0.8.1), HlFrame, chunk bảng nhớ tạm, UUIDv7, b64/b64u
│       ├── crypto/                # Tink XChaCha20-Poly1305, X25519, Ed25519, HKDF (JCA), device_id, PRK, lịch khóa phiên/rekey/stream, kho khóa hl_master
│       ├── transport/             # Ktor/Netty WSS (TLS 1.3, chứng chỉ P-256 tự ký), bắt tay phía S, capability, rekey, thay phiên 4409
│       └── design/                # HandLiveTheme (4 giao diện, Inter/Be Vietnam Pro/Roboto Mono), HLButton, HLSwitch, HLGroupedList, HLStatusIndicator
├── apple/                         # XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol        # Model giao thức Codable, HLFrame, ErrorCode
│   ├── Packages/HLCrypto          # HChaCha20 tự cài + ChaChaPoly = XChaCha20-Poly1305, Curve25519, HKDF, lịch khóa, Keychain
│   ├── Packages/HLTransport       # Bắt tay phía client (logic), máy trạng thái 0.11
│   ├── Packages/HLDesignSystem    # Color Sets 4 giao diện + mã Swift sinh từ tokens.json, font Be Vietnam Pro, 3 thành phần SwiftUI
│   └── macOS/HandLive/            # App menu bar giữ chỗ (Phase 1)
├── relay/                         # Cargo workspace: crates/relay-server (actix-web 4, sqlx, redis), migrations/ (0.9.4), docker-compose dev
├── shared/
│   ├── test-vectors/              # 14 file vector + envelope-roundtrip{,-apple}.json (liên nền tảng)
│   ├── schemas/                   # JSON Schema 2020-12: envelope, payload, ack, error, session-*, capability-*
│   └── design-tokens/tokens.json
├── tools/
│   ├── docs/                      # validate_design_docs.py, apple_diacritics.py, build_design_html.py
│   ├── vectors/                   # generate_vectors.py (--check), verify_vectors.py (thư viện độc lập)
│   ├── schemas/                   # check_schemas.py (schema + ví dụ trong tài liệu)
│   └── .venv/                     # venv Python cục bộ (gitignore)
└── .github/workflows/             # ci-android, ci-apple, ci-relay, ci-shared
```

## Lệnh kiểm thử

| Phần | Lệnh |
|------|------|
| Android | `cd android && ./gradlew check` (test JVM, Android Lint, ktlint, detekt); cần `JAVA_HOME` JDK 21, `ANDROID_HOME` có `platforms;android-36` |
| Apple (máy chỉ có Command Line Tools) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test`; `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict` |
| Apple (có Xcode, CI) | `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` trong thư mục package (không đặt `HL_SWIFT_TESTING_PACKAGE`) |
| Relay | `cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`; tích hợp: `docker compose up -d --wait`, nạp `.env.example`, `cargo test -- --ignored` |
| Hợp đồng dùng chung | `tools/.venv/bin/python tools/vectors/verify_vectors.py`, `… generate_vectors.py --check`, `… tools/schemas/check_schemas.py`, `python3 tools/docs/validate_design_docs.py` |

Roundtrip liên nền tảng: `HL_WRITE_ROUNDTRIP=1` khi chạy test crypto Android/Apple ghi lại `envelope-roundtrip.json` / `envelope-roundtrip-apple.json`; test thường của mỗi bên giải mã file của bên kia.

## Cấu trúc code (đã quyết: monorepo — quyết định I1 trong kế hoạch triển khai)

| Thư mục | Nền tảng | Vai trò |
|---------|----------|---------|
| `android/` | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design}`, `feature/{pairing,clipboard,sms,call,callaudio,camera}` |
| `apple/` | Swift 6 | `Packages/{HLProtocol,HLCrypto,HLTransport,HLDesignSystem,HLCallAudio}` dùng chung; `macOS/HandLive` (menu bar, extension camera, driver micro); `iOS/HandLive` + `iOS/NotificationService` |
| `relay/` | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `shared/` | — | `test-vectors/`, `schemas/`, `design-tokens/` — nguồn: `docs/detailed-design/00-common-specs.md` và design system |
| `tools/` | Python | `docs/` (tài liệu), `vectors/` (sinh/kiểm test vector), `schemas/` (kiểm schema), `bench/` (đo trễ, Phase 1) |

Chi tiết module và thẻ việc: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Điểm bắt đầu implement

Phase 0 đã xong (báo cáo: `plans/20260925-implementation/reports/phase-00-*.md`) → cổng G0 (còn chờ CI chạy thật trên GitHub) → Phase 1 (bảng nhớ tạm MVP). Xem `plans/20260925-implementation/plan.md` và `docs/project-roadmap.md`.
