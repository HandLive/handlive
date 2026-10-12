[English](README.md) | Tiếng Việt

# handlive-android

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Dịch vụ và ứng dụng HandLive dành cho điện thoại Android, viết bằng Kotlin với Jetpack Compose (minSdk 29, compileSdk 37). Ứng dụng kết nối Android với các thiết bị macOS, iOS và iPadOS để đồng bộ bảng nhớ tạm hai chiều, làm cầu nối SMS và hiển thị thông báo cuộc gọi kèm nút thao tác.

## Tổng quan

- **Tính năng liên kết thiết bị:** Đồng bộ mượt mà bảng nhớ tạm, chuyển tiếp tin nhắn SMS và hiển thị thông báo cuộc gọi trên các thiết bị của bạn.
- **Mã hóa đầu-cuối:** Toàn bộ dữ liệu truyền qua Wi-Fi cục bộ hoặc qua máy chủ relay đều được bảo vệ bằng XChaCha20-Poly1305 và khóa phiên X25519.
- **Hai flavor khi build:**
  - `foss` (mặc định): Bản build mã nguồn mở hoàn toàn, không phụ thuộc Google Play Services hay Firebase; kết nối trực tiếp qua mạng cục bộ hoặc qua WebSocket relay.
  - `gms`: Bổ sung tính năng đánh thức bằng tin dữ liệu ưu tiên cao qua Firebase Cloud Messaging (FCM).
- **Giao diện đa ngôn ngữ:** Tiếng Anh mặc định, tiếng Việt là ngôn ngữ thứ hai, với các chuỗi hiển thị được sinh từ `handlive-shared`.
- **Tích hợp cuộc gọi không cần `InCallService`:** Sử dụng `TelecomManager` cho các thao tác (Trả lời, Từ chối, Kết thúc) và listener hệ thống thay vì dịch vụ xử lý cuộc gọi can thiệp sâu. Không hỗ trợ âm thanh cuộc gọi trên máy tính (Phase 4 đã dừng).

## Bối cảnh workspace

Kho lưu trữ này là một thành phần trong workspace HandLive:
- Kho hub [`handlive`](https://github.com/HandLive/handlive) (tài liệu, kế hoạch) là thư mục cha.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) cung cấp JSON schema, test vector và chuỗi giao diện dùng chung.
- Clone toàn bộ workspace từ hub bằng lệnh `tools/workspace.sh clone <group-url>`. Xem [`CLAUDE.md`](CLAUDE.md) để biết quy trình làm việc trong workspace.

## Bố cục

| Đường dẫn | Nội dung |
|-----------|----------|
| `app/` | Ứng dụng Compose (`app.handlive.android`): thiết lập lần đầu (SET-01), các thẻ Thiết bị và Cài đặt, quy trình ghép nối, chi tiết từng máy, thông báo Trợ năng, giải thích quyền SMS và Cuộc gọi, cài đặt chạy nền, và hủy đăng ký thiết bị. Hai flavor: `foss` (mặc định) và `gms` |
| `buildSrc/` | Tác vụ sinh mã: `:core:design:generateHandLiveTheme` từ `../shared/design-tokens/tokens.json`; `:core:strings:generateStringResources` từ `../shared/strings/ui-strings.json` |
| `core/protocol` | Định dạng truyền tải: Envelope, Payload, Ack, `ErrorCode` (0.8.1), khung HL, chunk bảng nhớ tạm, tin nhắn SMS và `call_event`, lớp bọc relay, op điều khiển, khung `HR`, thân REST, UUIDv7, Base64/Base64URL; kiểm tra hợp lệ theo schema trong `../shared` |
| `core/crypto` | Khối mật mã: Tink XChaCha20-Poly1305, X25519, Ed25519, HKDF, `device_id`, PRK, lịch khóa phiên/rekey/stream, `K_push`, và lưu trữ KeyStore `hl_master` |
| `core/transport` | Máy chủ Ktor/Netty WSS nhúng (TLS 1.3, chứng chỉ P-256 tự ký), bắt tay, trao đổi capability, quản lý phiên (thay thế 4409, đóng khi nhàn rỗi/giới hạn 4410/4411/4429); client relay OkHttp kèm ghim chứng chỉ |
| `core/data` | Cơ sở dữ liệu Room `handlive.db` v3 (`paired_device`, `sms_observer_state`, `push_outbox`), các khóa cài đặt DataStore (0.9.5), và bộ chứa `HandLiveData` |
| `core/strings` | Tài nguyên chuỗi sinh lúc build từ catalog; test đảm bảo độ phủ catalog và cấm chuỗi giao diện viết cứng |
| `core/design` | `HandLiveTheme` (4 biến thể giao diện, kiểu chữ Inter / Be Vietnam Pro / Roboto Mono), `HLButton`, `HLSwitch`, `HLGroupedList`, `HLStatusIndicator`, `HLIcon` |
| `feature/connection` | `HandLiveService` (dịch vụ nền trước), máy chủ TLS trên cổng 47800–47809, mDNS với gợi ý theo giờ, đồng bộ capability, định tuyến envelope, và log `HLBENCH/1` ở bản debug |
| `feature/pairing` | Ghép nối bằng mã QR (CameraX + ZXing) hoặc PIN (Argon2id), danh sách thiết bị đã ghép, xác thực Mã an toàn, và hủy ghép nối |
| `feature/clipboard` | Đồng bộ bảng nhớ tạm hai chiều: nhận diện sao chép qua Trợ năng, `ClipboardReadActivity`, ô Cài đặt nhanh, mục Chia sẻ, truyền ảnh theo khối, và tự xóa an toàn |
| `feature/sms` | Cầu nối SMS: `ContentObserver` trên SMS provider (không cần `RECEIVE_SMS`), `sms/new`, đồng bộ phân trang (`sms/sync`, `sms/history`), gửi nhiều phần qua `SmsManager`, cập nhật trạng thái chỉ tiến, và đồng bộ trạng thái đọc |
| `feature/call` | Giám sát và thao tác cuộc gọi: listener trạng thái điện thoại và receiver `PHONE_STATE` nuôi ngữ cảnh cuộc gọi; `answer`, `reject`, `end` qua `TelecomManager`; đồng bộ nhật ký qua `ContentObserver`; push cảnh báo cuộc gọi đến và nhỡ; hỗ trợ cuộc gọi từ ứng dụng khác (`appcall/`) |
| `feature/relay` | Client relay: kết nối `/v1/relay` theo nhu cầu, đăng ký thiết bị, điểm hẹn ghép nối, và gửi push cảnh báo (`K_push`) qua hàng đợi thử lại `push_outbox` |
| `config/` | Cấu hình linter: ktlint, detekt |

## Yêu cầu

- **JDK:** Phiên bản 21 (ví dụ OpenJDK 21)
- **Android SDK:** Compile SDK 37 (`platforms;android-37.0`), Min SDK 29, Target SDK 35
- **Công cụ build:** Android Gradle Plugin (AGP) 9.4 với Kotlin 2.4

## Thiết lập khi build

Cấu hình sử dụng Gradle property (`~/.gradle/gradle.properties` hoặc `-P`) hoặc biến môi trường. Mọi thiết lập là tùy chọn; dự án build thành công với cấu hình mặc định:

| Gradle property | Biến môi trường | Dùng cho |
|-----------------|-----------------|----------|
| `handlive.relayHost` | `HANDLIVE_RELAY_HOST` | Máy chủ relay (CONN-03); để trống = bản build không có relay |
| `handlive.relayExtraPins` | `HANDLIVE_RELAY_EXTRA_PINS` | Bổ sung ghim chứng chỉ `sha256/<base64>`, phân tách bằng dấu phẩy, bên cạnh ISRG Root X1/X2 |
| `handlive.fcm.applicationId`, `.apiKey`, `.projectId`, `.senderId` | `HANDLIVE_FCM_APPLICATION_ID`, `_API_KEY`, `_PROJECT_ID`, `_SENDER_ID` | Chỉ flavor `gms`: thông tin Firebase để đánh thức qua FCM; để trống = không bật push |

## Lệnh

```sh
./gradlew check            # JVM tests (foss) + Android Lint + ktlint + detekt (JDK 21, platforms;android-37.0)
./gradlew assembleFossDebug assembleGmsDebug   # the default flavor and the one with FCM
./gradlew :core:transport:connectedDebugAndroidTest   # instrumented smoke test, needs a device
HL_WRITE_ROUNDTRIP=1 ./gradlew :core:crypto:test   # rewrites ../shared/test-vectors/envelope-roundtrip.json
adb logcat -s HLBENCH      # debug builds: benchmark lines for ../shared/tools/bench
```

## Tài liệu và cộng đồng

- [Kiến trúc hệ thống](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.vi.md) — Thiết kế hệ thống và mô hình bảo mật
- [Thiết kế chi tiết](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Giao thức, định dạng và đặc tả kỹ thuật
- [Hướng dẫn triển khai](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.vi.md) — Đóng gói và phát hành ứng dụng
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.vi.md) — Quy trình gửi PR, commit nhỏ và ký xác nhận DCO (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md) — Chính sách báo cáo lỗ hổng bảo mật
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.vi.md) — Quy tắc ứng xử cộng đồng

## Giấy phép

Apache License 2.0 — xem [LICENSE](LICENSE). Phông chữ và biểu tượng đi kèm giữ nguyên giấy phép ban đầu, liệt kê trong [NOTICE](NOTICE).
