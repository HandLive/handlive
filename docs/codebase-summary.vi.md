[English](codebase-summary.md) | Tiếng Việt

# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại (2026-09-26)

**Mã Phase 1 (bảng nhớ tạm MVP) đã xong** trên nhánh `feat/phase-01-clipboard` của handlive-android,
handlive-apple, handlive-shared và handlive-relay, CI xanh ở từng kho; chờ cổng G1 (đo trễ và kiểm giao diện
trên điện thoại Pixel/Samsung và Mac thật) rồi mới gộp vào `main`. Giao diện đa ngôn ngữ — tiếng Anh mặc định,
tiếng Việt thứ hai — mọi chuỗi nằm trong catalog dùng chung (C20). Khoảng 297 file Kotlin, 188 file Swift (chưa
tính file sinh), 29 file Rust và 36 file công cụ Python. Từ 25/09/2026 mã nguồn tách thành **năm kho git trong
một workspace** (quyết định I1 trong `plans/20260925-implementation/plan.md`, báo cáo `reports/repo-split.md`):
kho hub này chỉ giữ tài liệu, kế hoạch và công cụ tài liệu; bốn kho thành phần clone vào bên trong thư mục hub
(hub git-ignore chúng).

```
HandLive/                          # kho hub "handlive"
├── CLAUDE.md, README.md (+ README.vi.md)
├── docs/                          # mọi trang có X.md (tiếng Anh) + X.vi.md (tiếng Việt): detailed-design/, design-system/, privacy, PDR…
├── plans/20260925-implementation/ # Kế hoạch triển khai, phase-00…05 (hai ngôn ngữ), reports/ (tiếng Anh)
├── tools/docs/                    # validate_design_docs.py, check_bilingual_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh             # clone | status | run | remotes | push | hooks cho mọi kho
├── .github/workflows/ci-docs.yml  # khuôn tài liệu, cặp song ngữ, schema đối chiếu ví dụ
│
├── android/   ← "handlive-android": Gradle KTS, AGP 9.4, Kotlin 2.4, compileSdk 37 / targetSdk 35 / minSdk 29
│   ├── app/                       # màn Compose: thiết lập (SET-01), thiết bị, ghép nối, cài đặt (SET-02), công bố, HUD
│   ├── buildSrc/                  # bộ sinh: HandLiveTheme từ tokens.json, strings.xml (en, vi) từ catalog chuỗi
│   ├── core/protocol, core/crypto, core/transport, core/design   # như Phase 0, thêm mã đóng 4410/4411/4429 và giới hạn
│   ├── core/data/                 # cơ sở dữ liệu Room (paired_device, 0.9.1)
│   ├── core/strings/              # tài nguyên sinh từ shared/strings/ui-strings.json, ngôn ngữ theo ứng dụng
│   ├── feature/connection/        # HandLiveService (FGS), mDNS với hint theo giờ, phiên, capability, log HLBENCH/1
│   ├── feature/pairing/           # ghép nối QR (CameraX + ZXing) và PIN, thiết bị, Mã an toàn, hủy ghép nối
│   ├── feature/clipboard/         # gửi qua Hỗ trợ tiếp cận và thủ công, nhận, ảnh theo chunk, tự xóa an toàn (C17)
│   └── .github/workflows/ci-android.yml
├── apple/     ← "handlive-apple": XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol, HLCrypto   # model giao thức; XChaCha20-Poly1305, khóa ghép nối và phiên, Keychain
│   ├── Packages/HLTransport       # WSS Network.framework có ghim, tìm bằng NWBrowser, bắt tay, máy trạng thái 0.11
│   ├── Packages/HLAppCore         # cài đặt, định danh cục bộ, kho cặp niêm phong, bộ máy bảng nhớ tạm
│   ├── Packages/HLLocalization    # String Catalog Localizable/InfoPlist và accessor L10n sinh từ catalog
│   ├── Packages/HLDesignSystem    # Color Set và font từ tokens.json, thành phần SwiftUI
│   ├── Packages/HLMacUI           # menu thanh menu, cửa sổ chào, sheet ghép nối, pane Cài đặt, bảng dán
│   ├── macOS/HandLive/            # điểm vào app thanh menu, asset và purpose string sinh ra
│   └── .github/workflows/ci-apple.yml
├── relay/     ← "handlive-relay": crates/relay-server (actix-web 4, sqlx, redis), migrations/ (0.9.4), docker-compose dev
│   └── .github/workflows/ci-relay.yml
└── shared/    ← "handlive-shared"
    ├── test-vectors/              # mã hóa, envelope, phiên, relay-auth, ed25519, pair-handshake, discovery-hint, roundtrip
    ├── schemas/                   # JSON Schema 2020-12: envelope, payload, ack, error, session-*, capability-*, mã đóng
    ├── strings/                   # ui-strings.json (mọi chuỗi giao diện, en + vi) và schema của nó
    ├── design-tokens/             # tokens.json (giống byte với docs/design-system/tokens.json của hub), type-extras.json
    ├── tools/vectors, schemas, strings, bench   # bộ sinh và bộ kiểm; script đo trễ HLBENCH/1; venv tools/.venv
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
| Android | `cd android && ./gradlew check` (test JVM, Android Lint, ktlint, detekt); cần `JAVA_HOME` JDK 21, `ANDROID_HOME` có `platforms;android-37` |
| Apple (máy chỉ có Command Line Tools) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test` (package SwiftUI thêm `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`); `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict` |
| Apple (có Xcode, CI) | `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` trong thư mục package (không đặt `HL_SWIFT_TESTING_PACKAGE`) |
| Relay | `cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`; tích hợp: `docker compose up -d --wait`, nạp `.env.example`, `cargo test -- --ignored` |
| Hợp đồng dùng chung | `cd shared && tools/.venv/bin/python tools/vectors/verify_vectors.py`, `… tools/vectors/generate_vectors.py --check`, `… tools/schemas/check_schemas.py`, `… tools/strings/check_strings.py [--docs]` |
| Tài liệu (hub) | `python3 tools/docs/validate_design_docs.py` và `python3 tools/docs/check_bilingual_docs.py` — cả hai phải in `problems=0` |
| Cả năm kho | `tools/workspace.sh status`; `tools/workspace.sh run fetch --all` |

Roundtrip liên nền tảng: `HL_WRITE_ROUNDTRIP=1` khi chạy test crypto Android/Apple ghi lại
`envelope-roundtrip.json` / `envelope-roundtrip-apple.json` trong `shared/test-vectors`; test thường
của mỗi bên giải mã file của bên kia.

## Cấu trúc code (năm kho — quyết định I1 trong kế hoạch triển khai)

| Kho (thư mục) | Nền tảng | Vai trò |
|---------------|----------|---------|
| `handlive` (hub, thư mục này) | Markdown, Python | `docs/`, `plans/`, `tools/docs/`, `tools/workspace.sh`; hợp đồng cho mọi kho khác |
| `handlive-android` (`android/`) | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design,data,strings}`, `feature/{connection,pairing,clipboard}`; `feature/{sms,call,callaudio,camera}` thêm dần theo phase |
| `handlive-apple` (`apple/`) | Swift 6 | `Packages/{HLProtocol,HLCrypto,HLTransport,HLAppCore,HLLocalization,HLDesignSystem,HLMacUI}` dùng chung; `macOS/HandLive` (thanh menu; extension camera và driver micro ở Phase 5); `iOS/HandLive` + `iOS/NotificationService` ở Phase 2 |
| `handlive-relay` (`relay/`) | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `handlive-shared` (`shared/`) | JSON, Python | `test-vectors/`, `schemas/`, `strings/`, `design-tokens/`, `tools/{vectors,schemas,strings,bench}` — nguồn: `docs/detailed-design/00-common-specs.md` và design system |

Mỗi kho thành phần có `CLAUDE.md` riêng nói rõ bố cục workspace và lệnh của kho đó. Chi tiết module
và thẻ việc: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Điểm bắt đầu implement

Phase 0 và mã Phase 1 đã xong (báo cáo: `plans/20260925-implementation/reports/phase-00-*.md`,
`phase-01-*.md`) → cổng G1: chạy ma trận thiết bị của `shared/tools/bench/README.md` trên điện thoại và Mac
thật, rồi gộp `feat/phase-01-clipboard` vào `main` ở từng kho → Phase 2 (SMS, app iOS, relay, push). Xem
`plans/20260925-implementation/plan.md` và `docs/project-roadmap.md`.
