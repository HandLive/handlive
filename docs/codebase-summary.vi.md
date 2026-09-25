[English](codebase-summary.md) | Tiếng Việt

# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại (25/09/2026)

**Phase 0 xong** — khung kho, giao thức, mã hóa, token, CI; chưa có tính năng người dùng. Khoảng 111
file Kotlin, 66 file Swift, 28 file Rust. Từ 25/09/2026 mã nguồn tách thành
**năm kho git trong một workspace** (quyết định I1 trong `plans/20260925-implementation/plan.md`,
báo cáo `reports/repo-split.md`): kho hub này chỉ giữ tài liệu, kế hoạch và công cụ tài liệu; bốn
kho thành phần clone vào bên trong thư mục hub (hub git-ignore chúng).

```
HandLive/                          # kho hub "handlive"
├── CLAUDE.md, README.md
├── docs/                          # detailed-design/ (hợp đồng), design-system/, PDR, kiến trúc, chuẩn mã…
├── plans/20260925-implementation/ # Kế hoạch triển khai, phase-00…05, reports/
├── tools/docs/                    # validate_design_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh             # clone <group-url> | status | run <git…> cho cả năm kho
├── .github/workflows/ci-docs.yml  # khuôn tài liệu + schema đối chiếu ví dụ
│
├── android/   ← kho "handlive-android": Gradle KTS, AGP 9.4, Kotlin 2.4, compileSdk 36 / targetSdk 35 / minSdk 29
│   ├── app/                       # Compose, gói app.handlive.android (màn giữ chỗ)
│   ├── buildSrc/                  # Generator HandLiveTheme từ ../shared/design-tokens/tokens.json
│   ├── core/
│   │   ├── protocol/              # Envelope, Payload, Ack, ErrorCode (0.8.1), HlFrame, chunk bảng nhớ tạm, UUIDv7, b64/b64u
│   │   ├── crypto/                # Tink XChaCha20-Poly1305, X25519, Ed25519, HKDF (JCA), device_id, PRK, lịch khóa phiên/rekey/stream, kho khóa hl_master
│   │   ├── transport/             # Ktor/Netty WSS (TLS 1.3, chứng chỉ P-256 tự ký), bắt tay phía S, capability, rekey, thay phiên 4409
│   │   └── design/                # HandLiveTheme (4 giao diện, Inter/Be Vietnam Pro/Roboto Mono), HLButton, HLSwitch, HLGroupedList, HLStatusIndicator
│   └── .github/workflows/ci-android.yml
├── apple/     ← kho "handlive-apple": XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol        # Model giao thức Codable, HLFrame, ErrorCode
│   ├── Packages/HLCrypto          # HChaCha20 tự cài + ChaChaPoly = XChaCha20-Poly1305, Curve25519, HKDF, lịch khóa, Keychain
│   ├── Packages/HLTransport       # Bắt tay phía client (logic), máy trạng thái 0.11
│   ├── Packages/HLDesignSystem    # Color Sets 4 giao diện + mã Swift sinh từ tokens.json, font Be Vietnam Pro, 3 thành phần SwiftUI
│   ├── macOS/HandLive/            # App menu bar giữ chỗ (Phase 1)
│   └── .github/workflows/ci-apple.yml
├── relay/     ← kho "handlive-relay": Cargo workspace crates/relay-server (actix-web 4, sqlx, redis), migrations/ (0.9.4), docker-compose dev
│   └── .github/workflows/ci-relay.yml
└── shared/    ← kho "handlive-shared"
    ├── test-vectors/              # 14 file vector + envelope-roundtrip{,-apple}.json (liên nền tảng)
    ├── schemas/                   # JSON Schema 2020-12: envelope, payload, ack, error, session-*, capability-*
    ├── design-tokens/             # tokens.json (giống byte với docs/design-system/tokens.json của hub), type-extras.json
    ├── tools/vectors/, tools/schemas/   # generate_vectors.py (--check), verify_vectors.py, check_schemas.py; venv tools/.venv (gitignore)
    └── .github/workflows/ci-shared.yml
```

Kho thứ sáu `HandLive/.github` (clone thành `.github-org/`) giữ hồ sơ org và file cộng đồng mặc định cho mọi kho: CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, mẫu PR/issue.

Đường dẫn giữa các kho là tương đối và **bắt buộc**: Gradle và test Android đọc `../shared` (system property `hl.shared.dir`), test `core:design` đọc thêm
`../docs/design-system/1-foundations` (`hl.docs.dir`); test Apple đọc `../shared` và
`../docs/design-system/1-foundations/03-kieu-chu.md`; test relay đọc `../shared/test-vectors`;
`shared/tools/schemas/check_schemas.py` đọc `../docs/detailed-design` (ghi đè bằng
`HANDLIVE_DOCS_DIR`). CI của từng kho dựng lại đúng bố cục này bằng `actions/checkout` (hub ở gốc
workspace khi cần tài liệu, phần vào `<phần>/`, `handlive-shared` vào `shared/`; kho private cần
secret `HANDLIVE_REPOS_TOKEN` — `docs/deployment-guide.md`).

## Lệnh kiểm thử

| Phần | Lệnh |
|------|------|
| Android | `cd android && ./gradlew check` (test JVM, Android Lint, ktlint, detekt); cần `JAVA_HOME` JDK 21, `ANDROID_HOME` có `platforms;android-36` |
| Apple (máy chỉ có Command Line Tools) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test`; `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict` |
| Apple (có Xcode, CI) | `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` trong thư mục package (không đặt `HL_SWIFT_TESTING_PACKAGE`) |
| Relay | `cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`; tích hợp: `docker compose up -d --wait`, nạp `.env.example`, `cargo test -- --ignored` |
| Hợp đồng dùng chung | `cd shared && tools/.venv/bin/python tools/vectors/verify_vectors.py`, `… tools/vectors/generate_vectors.py --check`, `… tools/schemas/check_schemas.py` |
| Tài liệu (hub) | `python3 tools/docs/validate_design_docs.py` — phải in `problems=0` |
| Cả năm kho | `tools/workspace.sh status`; `tools/workspace.sh run fetch --all` |

Roundtrip liên nền tảng: `HL_WRITE_ROUNDTRIP=1` khi chạy test crypto Android/Apple ghi lại
`envelope-roundtrip.json` / `envelope-roundtrip-apple.json` trong `shared/test-vectors`; test thường
của mỗi bên giải mã file của bên kia.

## Cấu trúc code (năm kho — quyết định I1 trong kế hoạch triển khai)

| Kho (thư mục) | Nền tảng | Vai trò |
|---------------|----------|---------|
| `handlive` (hub, thư mục này) | Markdown, Python | `docs/`, `plans/`, `tools/docs/`, `tools/workspace.sh`; hợp đồng cho mọi kho khác |
| `handlive-android` (`android/`) | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design}`, `feature/{pairing,clipboard,sms,call,callaudio,camera}` (tạo dần theo phase) |
| `handlive-apple` (`apple/`) | Swift 6 | `Packages/{HLProtocol,HLCrypto,HLTransport,HLDesignSystem,HLCallAudio}` dùng chung; `macOS/HandLive` (menu bar, extension camera, driver micro); `iOS/HandLive` + `iOS/NotificationService` |
| `handlive-relay` (`relay/`) | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `handlive-shared` (`shared/`) | JSON, Python | `test-vectors/`, `schemas/`, `design-tokens/`, `tools/vectors/`, `tools/schemas/` — nguồn: `docs/detailed-design/00-common-specs.md` và design system; `tools/bench/` (đo trễ, Phase 1) |

Mỗi kho thành phần có `CLAUDE.md` riêng nói rõ bố cục workspace và lệnh của kho đó. Chi tiết module
và thẻ việc: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Điểm bắt đầu implement

Phase 0 đã xong (báo cáo: `plans/20260925-implementation/reports/phase-00-*.md`, rà soát
`phase-00-review.md`) → cổng G0 (còn chờ CI chạy thật trên group GitHub) → Phase 1 (bảng nhớ tạm
MVP). Xem `plans/20260925-implementation/plan.md` và `docs/project-roadmap.md`.
