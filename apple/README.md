# apple/ — HandLive cho macOS và iOS/iPadOS

Swift 6, macOS 13+ / iOS 16+. Đặc tả: `docs/detailed-design/00-common-specs.md`; kế hoạch: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Bố cục

| Đường dẫn | Nội dung |
|-----------|----------|
| `project.yml` | XcodeGen: target app `HandLive` (menu bar, bundle `app.handlive.mac`) + 4 local package. Không cấu hình ký |
| `HandLive.xcworkspace` | Workspace tham chiếu `HandLive.xcodeproj` (sinh ra) và các package |
| `macOS/HandLive/` | App menu bar (placeholder Phase 0, tính năng từ Phase 1) |
| `Packages/HLProtocol` | Envelope, `{op, data}`, Ack, `ErrorCode` (0.8.1), khung HL (0.5.2), plaintext nhị phân `clipboard/chunk`, UUIDv7, b64/b64u, AAD, kiểu `session`/`capability` |
| `Packages/HLCrypto` | HChaCha20 tự cài + CryptoKit `ChaChaPoly` = XChaCha20-Poly1305; X25519, Ed25519, HKDF/HMAC-SHA256; `device_id`; PRK; bắt tay/rekey/`K_stream`; mã hóa envelope và khung HL; Keychain sau protocol `SecretStore` |
| `Packages/HLTransport` | Máy trạng thái 0.11, `RECONNECT_BACKOFF`, bắt tay phía client (thuần logic; mạng thật từ Phase 1) |
| `Packages/HLDesignSystem` | Token giao diện (thẻ M0.2) |

Phụ thuộc: `HLTransport → HLCrypto → HLProtocol`.

## Sinh project Xcode

```sh
cd apple && xcodegen generate     # tạo HandLive.xcodeproj (không commit, đã có trong .gitignore)
open HandLive.xcworkspace
```

## Test

Test dùng swift-testing (`import Testing`) và đọc thẳng `shared/test-vectors/*.json`, `shared/schemas/*.json` theo đường dẫn tương đối tới gốc kho.

```sh
# Có Xcode (CI): dùng Testing đi kèm Xcode
cd apple/Packages/HLCrypto && swift test
xcodebuild test -workspace apple/HandLive.xcworkspace -scheme HLCrypto -destination 'platform=macOS'

# Chỉ có Command Line Tools: kéo gói swift-testing (release/6.2)
cd apple/Packages/HLCrypto && HL_SWIFT_TESTING_PACKAGE=1 swift test
```

Vector liên nền tảng: `HL_WRITE_ROUNDTRIP=1` (trong `HLCrypto`) ghi lại `shared/test-vectors/envelope-roundtrip-apple.json`; test thường luôn giải mã file đó và `envelope-roundtrip.json` của Android nếu có.

## Lint

```sh
cd apple && swiftlint lint --strict
# chỉ có Command Line Tools: TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
```
