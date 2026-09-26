[English](deployment-guide.md) | Tiếng Việt

# HandLive: Đóng gói và phân phối

> Chưa có pipeline build. Đây là kế hoạch phân phối theo quyết định D5, D7 và D8 trong plan gốc.

## Ứng dụng Android

- **Play Store.** Cần Permissions Declaration Form cho `READ_SMS`, `SEND_SMS` và `READ_CALL_LOG`, theo ngoại lệ "Cross-device synchronization or transfer of SMS or calls". Khai báo dùng Accessibility API (D4/D12). Chuẩn bị video demo, tài liệu use-case và privacy policy. Nộp sớm ở mốc P1 milestone 2 để biết kết quả trước khi phát hành.
- **Phân phối dự phòng.** Nếu Play Store từ chối quyền SMS, phát hành qua F-Droid và APK trực tiếp. Khi mất `SEND_SMS`, đọc SMS qua Notification Listener.
- **Flavor (plan I8).** `foss` là bản mặc định. Bản này không có Play Services và Firebase, dùng cho F-Droid và APK trực tiếp. `gms` thêm lệnh đánh thức qua FCM cho Play Store. Cấu hình Firebase của `gms` lấy từ thuộc tính Gradle `handlive.fcm.applicationId`, `handlive.fcm.apiKey`, `handlive.fcm.projectId`, `handlive.fcm.senderId`, hoặc biến môi trường `HANDLIVE_FCM_APPLICATION_ID`, `HANDLIVE_FCM_API_KEY`, `HANDLIVE_FCM_PROJECT_ID`, `HANDLIVE_FCM_SENDER_ID`. Kho không chứa `google-services.json`. Để trống cấu hình thì app vẫn build được, chỉ không nhận push.
- **Danh sách cho cổng G2 (trước khi phát hành Phase 2).** Trong Play Console, nộp Permissions Declaration Form cho `READ_SMS` và `SEND_SMS`. `READ_CALL_LOG` thêm vào ở Phase 3. Kèm một video ngắn gồm: màn giới thiệu quyền SMS (SET-01 phần B), hộp thoại xin quyền của hệ thống, tin SMS mới hiện trên Mac, và một tin trả lời gửi từ Mac. URL chính sách quyền riêng tư là trang `docs/privacy.md` đã công bố. Form Data safety điền theo cùng trang đó. Chủ dự án tự nộp form rồi ghi kết quả vào đây.
- **Shizuku** là tùy chọn cho đường âm thanh cuộc gọi Opus/WS. Wizard hướng dẫn cài. Người dùng khởi động lại Shizuku sau mỗi lần bật máy (plan §13 D10).

## Ứng dụng macOS

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1). Ký Developer ID cho app, extension camera và driver micro. Target app đặt `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
- **Micro ảo (AudioServerPlugin).** Mac App Store không cài plugin này. Sandbox chặn `/Library/Audio/Plug-Ins/HAL/`. Phân phối theo hai đường:
  - PKG **đã ký và notarized** (`xcrun notarytool submit`, rồi `stapler staple`), nhúng trong app. Lần chạy đầu, app thấy thiếu plugin thì mở PKG bằng Installer. Installer tự xin quyền quản trị. `postinstall` chạy `killall coreaudiod` với quyền root. Không cần privileged helper. `SMJobBless` deprecated từ macOS 13. `launchctl kickstart` bị chặn từ macOS 14.4.
  - Song song: `brew install --cask handlive`. Lệnh này cài cả app và plugin.
- **Camera ảo (CMIOExtension).** System extension nằm trong app bundle, tương thích App Store. Người dùng chấp thuận trong System Settings, mục Login Items & Extensions.
- Yêu cầu macOS 13 trở lên.

## Ứng dụng iOS và iPadOS

Phát hành App Store thông thường. Push đi qua APNs. Yêu cầu iOS 16 trở lên.

- **Định danh.** Bundle id là `app.handlive.ios`. App có thêm target Notification Service Extension. App và extension dùng chung App Group `group.app.handlive`. App Group này cũng là Keychain access group của service `app.handlive.keys` (0.6.1). Nhờ vậy extension đọc được `PRK` khi máy đang mở khóa (C3).
- **Capability (tài khoản Apple Developer và entitlement).** Cần Push Notifications (`aps-environment`), App Groups, Keychain Sharing và Communication Notifications (`com.apple.developer.usernotifications.communication`). Capability cuối dùng cho thông báo `INSendMessageIntent` của SMS-02. App khai báo `INSendMessageIntent` trong `NSUserActivityTypes`. Chuỗi mục đích mạng cục bộ (`NSLocalNetworkUsageDescription`, `NSBonjourServices` = `_handlive._tcp`) lấy từ catalog chuỗi (khóa `infoplist.*`, 0.12).
- **Khóa APNs.** Tạo một khóa `.p8` trong tài khoản Apple Developer, mục Keys, dịch vụ Apple Push Notifications. Khóa chỉ nằm trên máy chủ relay (`RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID`, `RELAY_APNS_TOPIC` = `app.handlive.ios`). Bản build phát triển đăng ký token sandbox.
- **App Review.** Trả lời App Privacy theo `docs/privacy.md`. Ghi chú cho người duyệt rằng app chạy cùng điện thoại Android của chính người dùng có cài HandLive. Kèm video ghép nối và nhận SMS.

## Cloud relay (Rust)

- Biến môi trường: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (byte UTF-8 thô, từ 32 byte, xoay theo lịch). Giới hạn theo IP chỉ tin `X-Forwarded-For` từ reverse proxy đặt trước relay, Caddy hoặc nginx.
- **Push (Phase 2).** APNs bật khi đặt đủ `RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID` và `RELAY_APNS_TOPIC`. FCM bật khi đặt `RELAY_FCM_PROJECT_ID` và `RELAY_FCM_SERVICE_ACCOUNT_PATH`. Biến sau trỏ tới file JSON của một service account Google có quyền dùng Firebase Cloud Messaging API. Để file khóa ngoài kho mã, chỉ user chạy relay đọc được. Danh sách biến đầy đủ nằm trong relay/README.md.
- **Giới hạn.** Mỗi IP đăng ký tối đa 10 thiết bị mới mỗi giờ. Khi relay đứng sau reverse proxy, đặt `RELAY_TRUSTED_PROXIES` là địa chỉ proxy để relay tin `X-Forwarded-For`. Load test từ một máy cần `RELAY_TRUSTED_PROXIES=127.0.0.1` (`shared/tools/bench/relay_load.py`).
- **Nhiều instance.** Mọi instance dùng chung PostgreSQL và Redis. Redis giữ presence và chuyển khung giữa các instance (C5). `RELAY_INSTANCE_ID` đặt tên instance trong `presence:<device_id>`.
- **D5.** Tự host một VPS (Hetzner hoặc OVH, khoảng 20 USD mỗi tháng) cho Phase 2. Docker và systemd. Relay không giữ trạng thái.
- Mở rộng: theo dõi CPU và băng thông. Cảnh báo khi vượt 70 phần trăm, rồi thêm VPS. Chuyển sang nền tảng managed (fly.io hoặc Railway) khi quá 500 người dùng cùng lúc.
- TLS: Let's Encrypt, kèm cert pinning phía client.
- Ước tính: 100 cuộc gọi Opus cùng lúc khoảng 12 GB mỗi giờ. VPS thông thường, 20 TB mỗi tháng, đủ cho khoảng 1000 người dùng.

## CI

Mỗi kho có một workflow GitHub Actions trong `.github/workflows/` của kho đó.

- `ci-android` chạy `./gradlew check`.
- `ci-apple` chạy `xcodebuild test` từng package, SwiftLint, rồi build app.
- `ci-relay` chạy fmt, clippy và test. Test tích hợp dùng PostgreSQL 16 và Redis 7.
- `ci-shared` kiểm vector, vector sinh lại, và schema đối chiếu ví dụ trong tài liệu.
- `ci-docs` ở hub kiểm khuôn tài liệu và schema.

Mỗi workflow dựng lại bố cục workspace bằng `actions/checkout`. Hub nằm ở gốc, checkout trước khi cần tài liệu. Phần mã vào `<phần>/`. `handlive-shared` vào `shared/`. Tên kho lấy theo `${{ github.repository_owner }}/handlive-<phần>`. Cả năm kho phải nằm cùng một organization và giữ đúng tên: `handlive`, `handlive-android`, `handlive-apple`, `handlive-relay`, `handlive-shared`.

Kho private: tạo secret `HANDLIVE_REPOS_TOKEN` ở cấp organization. Token là fine-grained PAT hoặc token GitHub App, quyền Contents: read trên năm kho. Kho public thì `github.token` đủ.

Sửa `shared/` hoặc tài liệu không tự kích hoạt CI nền tảng. Chạy tay bằng `workflow_dispatch`. Mỗi workflow lấy nhánh trùng tên của `handlive-shared` và hub nếu có, ví dụ `feat/phase-01-clipboard` ở mọi kho. Không có nhánh đó thì dùng `main`. Bật branch protection. Nhánh `main` mỗi kho phải qua check tương ứng.

## Tăng tốc USB (tùy chọn)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`). Tự nhận cáp qua IOKit `IOServiceAddMatchingNotification`. Wizard ba bước bật USB Debugging lần đầu. Các lần sau tự chuyển. UVC native để dành cho v2.
