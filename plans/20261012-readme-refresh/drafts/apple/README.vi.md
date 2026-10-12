[English](README.md) | Tiếng Việt

# handlive-apple

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Bộ ứng dụng HandLive dành cho macOS (thanh menu), iOS và iPadOS, viết bằng Swift 6 (macOS 13+, iOS 16+). Ứng dụng kết nối các thiết bị Apple với điện thoại Android để đồng bộ bảng nhớ tạm hai chiều, làm cầu nối SMS và hiển thị thông báo cuộc gọi đến kèm nút thao tác.

## Tổng quan

- **Ứng dụng thanh menu macOS:** Nằm trên thanh menu hệ thống (`app.handlive.mac`). Xử lý đồng bộ bảng nhớ tạm hai chiều, nhắn tin SMS đầy đủ và bảng thông báo cuộc gọi đến không chiếm quyền kích hoạt kèm nút Trả lời, Từ chối và Kết thúc (âm thanh cuộc gọi vẫn ở trên điện thoại; Phase 4 đã dừng).
- **Ứng dụng iOS và iPadOS:** Ứng dụng độc lập (`app.handlive.ios`) kèm Notification Service Extension (`app.handlive.ios.nse`). Hỗ trợ đồng bộ bảng nhớ tạm qua nút Dán, thẻ nhắn tin SMS và thông báo cuộc gọi đến dạng push kèm nút Từ chối.
- **Mã hóa đầu-cuối:** Xây dựng trên HChaCha20 tự viết + `ChaChaPoly` của CryptoKit (XChaCha20-Poly1305), Ed25519 nghiêm ngặt, X25519, HKDF và Argon2id. Khóa riêng tư được bảo vệ an toàn trong Keychain hệ thống qua giao thức `SecretStore`.
- **Giao diện đa ngôn ngữ:** Tiếng Anh mặc định, tiếng Việt là ngôn ngữ thứ hai, với String Catalogs được sinh từ `handlive-shared`.
- **Lưu trữ cơ sở dữ liệu:** SQLite cục bộ mã hóa qua SQLCipher 4.19 và GRDB.swift 7.11 cho các cuộc trò chuyện SMS và nhật ký cuộc gọi.

## Bối cảnh workspace

Kho lưu trữ này là một thành phần trong workspace HandLive:
- Kho hub [`handlive`](https://github.com/HandLive/handlive) (tài liệu, kế hoạch) là thư mục cha.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) cung cấp JSON schema, test vector và chuỗi giao diện dùng chung.
- Clone toàn bộ workspace từ hub bằng lệnh `tools/workspace.sh clone <group-url>`. Xem [`CLAUDE.md`](CLAUDE.md) để biết quy trình làm việc trong workspace.

## Bố cục

| Đường dẫn | Nội dung |
|-----------|----------|
| `project.yml` | Định nghĩa XcodeGen: các target cho `HandLive` (app thanh menu macOS), `HandLiveiOS` (iOS/iPadOS), `HandLiveNotificationService` (NSE), cài đặt bản địa hóa và các Swift package nội bộ |
| `HandLive.xcworkspace` | Workspace tham chiếu tới `HandLive.xcodeproj` đã sinh và các package nội bộ |
| `macOS/HandLive/` | Điểm khởi nhập ứng dụng macOS (`HandLiveMacApp`), app delegate, `Assets.xcassets` và `InfoPlist.xcstrings` tự sinh |
| `macOS/Info.plist` | Định danh dịch vụ (`NSBonjourServices`), Intents, và các chuỗi mô tả quyền hạn tự sinh |
| `macOS/HandLive.entitlements` | Quyền truy cập keychain bảo vệ dữ liệu, thông báo liên lạc và thông báo nhạy cảm thời gian |
| `iOS/HandLive/` | Điểm khởi nhập ứng dụng iOS (`HandLiveIOSApp`), giao diện gốc (`HLiOSUI`) và String Catalogs tự sinh |
| `iOS/NotificationService/` | Notification Service Extension: giải mã envelope push APNs bằng `K_push` và dựng thông báo liên lạc |
| `iOS/Info.plist`, `iOS/*.entitlements` | Quyền hạn iOS, chia sẻ App Group và Keychain (`group.app.handlive`), và môi trường push |
| `ThirdParty/GRDB` | Package GRDB.swift 7.11.1 được nhúng sẵn, cấu hình build cùng SQLCipher |
| `ThirdParty/SQLCipher` | Package bọc XCFramework SQLCipher 4.19.0 (tải về qua `fetch.sh`) |
| `Packages/HLProtocol` | Định dạng truyền tải: Envelope, Payload, Ack, `ErrorCode` (0.8.1), khung HL, cấu trúc chunk bảng nhớ tạm, UUIDv7, Base64/Base64URL |
| `Packages/HLCrypto` | Khối mật mã: XChaCha20-Poly1305, X25519, Ed25519 nghiêm ngặt, HKDF, Argon2id, chứng thực ghép nối và lưu trữ Keychain |
| `Packages/HLTransport` | Máy trạng thái kết nối (0.11), khám phá mDNS (`NWBrowser`), kết nối WebSocket (TLS 1.3), client relay (`RelayAPIClient`) và phiên điều khiển (`/v1/ctl`) |
| `Packages/HLDesignSystem` | Design token, màu động, kiểu chữ, khoảng cách bố cục và các thành phần giao diện tái sử dụng |
| `Packages/HLAppCore` | Trạng thái ứng dụng dùng chung: cài đặt, lưu trữ cặp thiết bị, bộ điều khiển ghép nối (QR và điểm hẹn), động cơ bảng nhớ tạm và bộ điều khiển sự kiện cuộc gọi |
| `Packages/HLSMS` | Động cơ SMS: cơ sở dữ liệu SQLCipher, con trỏ đồng bộ, phân trang lịch sử, máy trạng thái hộp thư đi và giải mã thông báo |
| `Packages/HLSMSUI` | Giao diện tin nhắn SwiftUI dùng chung: danh sách cuộc trò chuyện, luồng tin nhắn, thanh soạn thảo và bong bóng tin nhắn |
| `Packages/HLCalls` | Quản lý cuộc gọi: động cơ nhật ký cuộc gọi, theo dõi cuộc gọi nhỡ, dọn dẹp dữ liệu cũ và giải mã payload thông báo |
| `Packages/HLMacUI` | Giao diện macOS: biểu tượng thanh menu, menu trạng thái, cửa sổ Tin nhắn, bảng cuộc gọi (`NSPanel`), màn Cài đặt và trang ghép nối |
| `Packages/HLiOSUI` | Giao diện iOS: điều hướng thẻ, màn Tin nhắn, lịch sử Cuộc gọi, quy trình dán Bảng nhớ tạm và Cài đặt |
| `Packages/HLLocalization` | Bộ truy cập kiểu an toàn `L10n` và String Catalogs sinh từ `../shared/strings/ui-strings.json` |
| `Tools/HandLiveDevClient` | Công cụ CLI cho lập trình viên: client Mac không giao diện dùng để kiểm thử với máy ảo Android qua `adb forward` |
| `Tools/CameraSpike` | Thử nghiệm thăm dò cho Phase 5 (extension camera ảo và plugin âm thanh HAL; không build trong CI) |

## Yêu cầu

- **macOS & Xcode:** Xcode 26 trở lên trên macOS 26 trở lên để build app Mac (tránh lỗi `actool` khi biên dịch tài nguyên; app đã build chạy trên macOS 13+ và iOS 16+)
- **XcodeGen:** XcodeGen (`xcodegen`) để sinh dự án Xcode từ `project.yml`
- **Swift:** Swift 6 toolchain hỗ trợ `swift-testing`

## Cài đặt và file tự sinh

Tải XCFramework SQLCipher một lần sau khi clone:

```sh
apple/ThirdParty/SQLCipher/fetch.sh
```

Sinh design token và chuỗi bản địa hóa từ `../shared` (test chạy các lệnh này với `--check`):

```sh
python3 apple/Packages/HLDesignSystem/Scripts/generate-design-tokens.py   # tokens.json → colors, text styles, metrics
python3 apple/Packages/HLLocalization/Scripts/generate-strings.py        # ui-strings.json → String Catalogs, L10n
```

## Sinh dự án Xcode

```sh
cd apple && xcodegen generate     # tạo HandLive.xcodeproj (không commit, nằm trong .gitignore)
open HandLive.xcworkspace
```

## Test

Test sử dụng swift-testing (`import Testing`) và đối chiếu với schema và test vector trong `../shared`:

```sh
# Với Xcode: dùng module Testing đi kèm Xcode
cd apple/Packages/HLCrypto && swift test
# Toàn bộ package trong một lần build (CI chạy song song hai luồng HLTests-core và HLTests-features)
cd apple && Tools/make-test-scheme.sh HLTests-all all
xcodebuild test -workspace HandLive.xcworkspace -scheme HLTests-all -destination 'platform=macOS' -parallel-testing-enabled NO

# Chỉ dùng Command Line Tools: kéo package swift-testing (release/6.2) và dùng fallback .lproj của
# String Catalogs. Các package SwiftUI (HLDesignSystem, HLSMSUI, HLCalls, HLMacUI, HLiOSUI) cần macOS 26 SDK khi đã cài
# SDK mới hơn.
cd apple/Packages/HLCrypto && HL_SWIFT_TESTING_PACKAGE=1 swift test
cd apple/Packages/HLMacUI && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test
```

## Lint

```sh
cd apple && swiftlint lint --strict
# Chỉ dùng Command Line Tools: TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
```

## Tài liệu và cộng đồng

- [Kiến trúc hệ thống](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.vi.md) — Thiết kế hệ thống và mô hình bảo mật
- [Thiết kế chi tiết](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Giao thức, định dạng và đặc tả kỹ thuật
- [Hướng dẫn triển khai](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.vi.md) — Đóng gói và phát hành ứng dụng
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.vi.md) — Quy trình gửi PR, commit nhỏ và ký xác nhận DCO (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md) — Chính sách báo cáo lỗ hổng bảo mật
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.vi.md) — Quy tắc ứng xử cộng đồng

## Giấy phép

Apache License 2.0 — xem [LICENSE](LICENSE). Phông chữ đi kèm giữ nguyên giấy phép ban đầu, liệt kê trong [NOTICE](NOTICE).
