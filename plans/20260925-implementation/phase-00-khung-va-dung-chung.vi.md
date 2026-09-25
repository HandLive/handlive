[English](phase-00-khung-va-dung-chung.md) | Tiếng Việt

# Phase 0 — Khung kho, giao thức, mã hóa, token, CI

**Mục tiêu:** ba nền tảng dựng được từ kho trống, dùng chung một bộ test vector cho mã hóa và
envelope, có token giao diện sinh từ `shared/design-tokens/tokens.json`, CI chạy test. Không có tính
năng người dùng nào ở phase này.

## Ngữ cảnh

- `docs/detailed-design/00-common-specs.md`: 0.2 định danh (`device_id` UUIDv8 từ SHA-256 khóa ký),
  0.3 kiểu dữ liệu, 0.5 envelope và khung HL, 0.6 mã hóa (XChaCha20-Poly1305 = HChaCha20 +
  ChaCha20-Poly1305; X25519 + HKDF-SHA256; `HLSTREAM1|welcome|` MAC), 0.7 bắt tay phiên và
  capability, 0.8 mã lỗi, 0.9 mô hình dữ liệu, 0.10 hằng số.
- `docs/code-standards.md`; `docs/design-system/1-foundations/01-mau-sac.md`, `03-kieu-chu.md`;
  `shared/design-tokens/README.md`.
- Kiến trúc: `plans/20260924-definitive-architecture/plan.md` §3, §5, §6.

## Yêu cầu

- Bố cục kho (I1; từ 25/09/2026 mỗi phần là kho riêng trong cùng thư mục workspace — xem `plan.md`
  I1 và `reports/repo-split.md`; `tools/vectors`, `tools/schemas` nay ở `shared/tools/`, workflow CI
  nằm trong từng kho) — tạo đủ, dựng xanh dù rỗng:

```
android/                      Gradle Kotlin DSL, AGP mới nhất ổn định, Kotlin 2.x, minSdk 29, targetSdk 35
  app/                        ứng dụng (Compose)
  core/protocol/              Envelope, Ack, HlFrame, mã lỗi, JSON (kotlinx.serialization)
  core/crypto/                Tink: XChaCha20-Poly1305, X25519, HKDF; device_id; Keystore
  core/transport/             Ktor WSS server, mDNS, bắt tay phiên, capability, máy trạng thái 0.11
  core/design/                HandLiveTheme sinh từ tokens.json, thành phần Compose kiểu Apple
  feature/pairing, clipboard, sms, call, callaudio, camera   (tạo dần theo phase)
apple/                        HandLive.xcworkspace; XcodeGen project.yml (không commit xcuserdata)
  Packages/HLProtocol         envelope, HL frame, mã lỗi (Codable)
  Packages/HLCrypto           HChaCha20 tự cài + ChaChaPoly, Curve25519, HKDF; device_id; Keychain
  Packages/HLTransport        URLSessionWebSocketTask, NWBrowser, bắt tay, capability, máy trạng thái
  Packages/HLDesignSystem     Color Sets 4 giao diện, font Be Vietnam Pro, text style, thành phần SwiftUI
  macOS/HandLive/             app menu bar (Phase 1)
  iOS/HandLive/, iOS/NotificationService/   (Phase 2)
relay/                        Cargo workspace: crates/relay-server (actix-web 4, actix-ws, sqlx, redis), migrations/
shared/
  test-vectors/               *.json (thẻ S0.1)
  schemas/                    JSON Schema cho envelope, ack, từng op (sinh từ 00-common-specs, kiểm bằng test)
  design-tokens/tokens.json   đã có
tools/docs/                   đã có; tools/bench/ (Phase 1)
.github/workflows/            ci-android.yml, ci-apple.yml, ci-relay.yml
```

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| S0.1 [shared] | Viết test vector: XChaCha20-Poly1305 (vector của draft-irtf-cfrg-xchacha), HChaCha20, ChaCha20-Poly1305 (RFC 8439), X25519 (RFC 7748), HKDF-SHA256 (RFC 5869), `device_id` từ khóa ký mẫu (0.2), envelope mẫu mã hóa bằng khóa cố định, khung HL mẫu, MAC `HLSTREAM1` (0.6) | `shared/test-vectors/*.json` + `shared/test-vectors/README.md` mô tả từng trường | Mỗi file có ≥ 2 vector; giá trị RFC chép nguyên văn, vector tự sinh có script sinh lại (`tools/vectors/`) |
| S0.2 [shared] | JSON Schema cho envelope, ack, lỗi và các `op` của `session`, `capability` (0.5, 0.7) | `shared/schemas/*.schema.json` | Ví dụ trong 00-common-specs qua được schema |
| A0.1 [android] | Khung Gradle đa module, lint (ktlint, detekt), `core/protocol`, `core/crypto` qua S0.1, S0.2 | `android/` | `./gradlew check` xanh; vector xanh |
| A0.2 [android] | `core/transport`: Ktor WSS server với chứng chỉ tự ký (PKCS#12, mật khẩu bọc bởi Keystore), bắt tay phiên 0.7, capability 0.7.2, máy trạng thái 0.11 (chưa nối UI) | `android/core/transport` | Test JVM: hai phía bắt tay qua loopback, sai MAC bị từ chối đúng mã lỗi |
| A0.3 [android] | `core/design`: sinh `HandLiveTheme` (màu 4 bộ, chữ Inter sp, khoảng cách, bo góc) từ `tokens.json` bằng Gradle task; thành phần cơ bản `HLButton`, `HLSwitch`, `HLGroupedList`, `HLStatusIndicator` theo `docs/design-system/components/` | `android/core/design` | Preview Compose ở Sáng, Tối, tương phản cao; không dùng màu động Material |
| M0.1 [apple] | XcodeGen `project.yml`, workspace, ba package `HLProtocol`, `HLCrypto`, `HLTransport`; SwiftLint; test qua S0.1, S0.2 | `apple/` | `xcodebuild test -scheme HLCrypto` xanh trên macOS; HChaCha20 khớp vector |
| M0.2 [apple] | `HLDesignSystem`: script sinh Asset Catalog Color Sets (Any, Dark, High Contrast) và `Font` từ `tokens.json`; text style theo `03-kieu-chu.md`; thành phần cơ bản (`HLButtonStyle`, `StatusIndicator`, `GroupedList`) | `apple/Packages/HLDesignSystem` | Xem trước SwiftUI ở 4 giao diện; AccentColor = `accent` |
| R0.1 [relay] | Cargo workspace, `relay-server` khởi động với PostgreSQL + Redis (docker-compose cho dev), migration lược đồ 0.9.4, xác thực `device_id` tự chứng thực (C4), JWT HS256 (0.6.4) | `relay/` | `cargo test` xanh; `docker compose up` chạy được; không đọc payload |
| T0.1 [test] | CI: Android (`./gradlew check` = test, lint, ktlint, detekt), Apple (`xcodebuild test` từng package trên runner macOS, `swiftlint`, build app), relay (`cargo test`, `cargo clippy`, test tích hợp Postgres + Redis), shared (vector, schema, validator tài liệu); cache | `.github/workflows/*.yml` | Bốn workflow xanh trên nhánh `feat/phase-00-khung` |

## Kiểm thử

- Vector liên nền tảng: cùng một envelope mã hóa trên Android giải mã được trên Apple và ngược lại
  (test fixture ghi ra `shared/test-vectors/envelope-roundtrip.json` bởi A0.1, kiểm bởi M0.1).
- `device_id` giống nhau khi tính từ cùng khóa ký trên hai nền tảng.

## Rủi ro và quay lui

- Tink không có API XChaCha20 với nonce 24 byte trên mọi phiên bản → dùng `XChaCha20Poly1305` của
  Tink (có sẵn) hoặc BouncyCastle; ghi rõ trong báo cáo.
- HChaCha20 tự cài sai → chỉ lộ qua vector; không được bỏ vector nào.
- XcodeGen làm lệch cấu hình ký → giữ `project.yml` tối giản, ký Developer ID cấu hình ở
  `docs/deployment-guide.md`.
