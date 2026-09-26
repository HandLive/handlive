[English](codebase-summary.md) | Tiếng Việt

# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại (2026-09-26)

**Phase 1 (bảng nhớ tạm MVP) đã gộp vào `main`** của handlive-android, handlive-apple, handlive-shared và
handlive-relay (26/09/2026, CI xanh). **Mã Phase 2 (SMS, app iPhone/iPad, relay, push) đã xong trên nhánh
`feat/phase-02-sms-ios-relay`** ở cùng bốn kho (CI xanh, chưa gộp). Cổng G1, cổng G2 và việc kiểm Phase 2 trên
máy thật, relay thật, APNs và FCM vẫn còn mở. Giao diện đa ngôn ngữ — tiếng Anh mặc định,
tiếng Việt thứ hai — mọi chuỗi nằm trong catalog dùng chung (C20). Khoảng 416 file Kotlin, 307 file Swift (chưa
tính file sinh và GRDB vendor), 78 file Rust và 48 file công cụ Python. Từ 25/09/2026 mã nguồn tách thành **năm kho git trong
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
│   ├── core/data/                 # cơ sở dữ liệu Room bản 2 (paired_device, sms_observer_state, push_outbox; 0.9.1)
│   ├── core/strings/              # tài nguyên sinh từ shared/strings/ui-strings.json, ngôn ngữ theo ứng dụng
│   ├── feature/connection/        # HandLiveService (FGS), mDNS với hint theo giờ, phiên, capability, log HLBENCH/1
│   ├── feature/pairing/           # ghép nối QR (CameraX + ZXing) và PIN, thiết bị, Mã an toàn, hủy ghép nối
│   ├── feature/clipboard/         # gửi qua Hỗ trợ tiếp cận và thủ công, nhận, ảnh theo chunk, tự xóa an toàn (C17)
│   ├── feature/sms/               # SMS-01…05: theo dõi provider, đồng bộ và tải lịch sử theo trang, gửi với SendRegistry
│   ├── feature/relay/             # CONN-03/04: relay khi cần, phiên qua relay, cặp, push SMS; FCM chỉ có trong `gms`
│   └── .github/workflows/ci-android.yml
├── apple/     ← "handlive-apple": XcodeGen project.yml (+ HandLive.xcworkspace), .swiftlint.yml
│   ├── Packages/HLProtocol, HLCrypto   # model giao thức; XChaCha20-Poly1305, khóa ghép nối và phiên, Keychain
│   ├── Packages/HLTransport       # WSS Network.framework có ghim, tìm bằng NWBrowser, trạng thái 0.11, client relay
│   ├── Packages/HLAppCore         # cài đặt, định danh cục bộ, kho cặp niêm phong, bộ máy bảng nhớ tạm
│   ├── Packages/HLLocalization    # String Catalog Localizable/InfoPlist và accessor L10n sinh từ catalog
│   ├── Packages/HLDesignSystem    # Color Set và font từ tokens.json, thành phần SwiftUI
│   ├── Packages/HLMacUI           # menu thanh menu, cửa sổ chào, sheet ghép nối, pane Cài đặt, bảng dán
│   ├── Packages/HLSMS             # bộ máy SMS và kho SQLCipher/GRDB của 0.9.3, bộ đếm số phần
│   ├── Packages/HLSMSUI, HLiOSUI  # màn Tin nhắn dùng chung cho Mac và iOS; các màn của app iPhone/iPad
│   ├── iOS/HandLive, iOS/NotificationService   # app iOS 16+ và extension mở push bằng K_push
│   ├── ThirdParty/                # mã nguồn GRDB (MIT); SQLCipher/fetch.sh tải XCFramework có kiểm tổng
│   ├── macOS/HandLive/            # điểm vào app thanh menu, asset và purpose string sinh ra
│   └── .github/workflows/ci-apple.yml
├── relay/     ← "handlive-relay": crates/relay-server (REST, /v1/relay), crates/relay-push (APNs, FCM), migrations/, docker-compose
│   └── .github/workflows/ci-relay.yml
└── shared/    ← "handlive-shared"
    ├── test-vectors/              # mã hóa, envelope, phiên, relay-auth, ed25519, ghép nối, hint, push-envelope, relay-frame
    ├── schemas/                   # JSON Schema 2020-12 (39): envelope, session-*, capability-*, sms-*, relay-*, push
    ├── strings/                   # ui-strings.json (mọi chuỗi giao diện, en + vi; 304 ở Phase 2) và schema của nó
    ├── design-tokens/             # tokens.json (giống byte với docs/design-system/tokens.json của hub), type-extras.json
    ├── tools/vectors, schemas, strings, bench   # bộ sinh và bộ kiểm; script HLBENCH/1 gồm SMS; load test relay
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
| Android | `cd android && ./gradlew check` (test JVM, Android Lint, ktlint, detekt); cần `JAVA_HOME` JDK 21, `ANDROID_HOME` có `platforms;android-37`; `./gradlew assembleFossDebug assembleGmsDebug` build cả hai flavor |
| Apple (máy chỉ có Command Line Tools) | `cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 swift test` (package SwiftUI thêm `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`); `cd apple && xcodegen generate`; `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict`; chạy `ThirdParty/SQLCipher/fetch.sh` một lần sau khi clone |
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
| `handlive` (hub, thư mục này) | Markdown, Python | `docs/`, `plans/`, `tools/docs/`, `tools/workspace.sh`; đặc tả cho mọi kho khác |
| `handlive-android` (`android/`) | Kotlin, Gradle KTS | App điện thoại: `app/` (flavor `foss`, `gms`), `core/{protocol,crypto,transport,design,data,strings}`, `feature/{connection,pairing,clipboard,sms,relay}`; `feature/{call,callaudio,camera}` thêm dần theo phase |
| `handlive-apple` (`apple/`) | Swift 6 | `Packages/{HLProtocol,HLCrypto,HLTransport,HLAppCore,HLSMS,HLSMSUI,HLLocalization,HLDesignSystem,HLMacUI,HLiOSUI}` dùng chung; `macOS/HandLive` (thanh menu; extension camera và driver micro ở Phase 5); `iOS/HandLive` + `iOS/NotificationService`; `ThirdParty/` (GRDB, SQLCipher) |
| `handlive-relay` (`relay/`) | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `handlive-shared` (`shared/`) | JSON, Python | `test-vectors/`, `schemas/`, `strings/`, `design-tokens/`, `tools/{vectors,schemas,strings,bench}` — nguồn: `docs/detailed-design/00-common-specs.md` và design system |

Mỗi kho thành phần có `CLAUDE.md` riêng nói rõ bố cục workspace và lệnh của kho đó. Chi tiết module
và thẻ việc: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Điểm bắt đầu implement

Phase 0 và Phase 1 đã gộp vào `main`. Mã Phase 2 đã xong trên nhánh `feat/phase-02-sms-ios-relay` (báo cáo:
`plans/20260925-implementation/reports/phase-02-*.md`, tổng quan `phase-02-summary.md`). Còn mở: cổng G1 (ma trận
thiết bị của `shared/tools/bench/README.md` trên điện thoại và Mac thật), cổng G2 (Play Console) và việc kiểm
Phase 2 trên máy thật với relay thật, APNs và FCM → gộp Phase 2 → Phase 3 (cuộc gọi). Xem
`plans/20260925-implementation/plan.md` và `docs/project-roadmap.md`.
